import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;
import 'package:screen_translate/services/custom_model_manager.dart';
import 'package:screen_translate/services/onnx_translation_service.dart';

// ─── ONNX model download status ──────────────────────────────────────────────

enum OnnxModelStatus { notDownloaded, downloading, ready, error }

// ─── Download progress callback ───────────────────────────────────────────────

typedef DownloadProgressCallback = void Function(double progress);

// ─── ModelDownloadService ─────────────────────────────────────────────────────

class ModelDownloadService {
  final OnDeviceTranslatorModelManager _googleModelManager;
  final CustomModelManager _customModelManager;

  /// Tracks active ONNX download tasks so we avoid duplicate concurrent downloads.
  final Map<String, Future<void>> _activeOnnxDownloads = {};

  ModelDownloadService()
      : _googleModelManager = OnDeviceTranslatorModelManager(),
        _customModelManager = CustomModelManager();

  // ── Google ML Kit helpers ─────────────────────────────────────────────────

  /// Downloads a Google ML Kit model with a custom-server fallback.
  Future<void> downloadModelWithFallback(String langCode) async {
    try {
      debugPrint('Attempting to download ML Kit model for "$langCode" from Google...');
      await _googleModelManager.downloadModel(langCode, isWifiRequired: false);
      debugPrint('ML Kit model for "$langCode" downloaded successfully from Google.');
    } catch (e) {
      debugPrint('Failed to download from Google. Reason: $e');
      debugPrint('Initiating fallback to custom server...');
      try {
        await _customModelManager.downloadAndInstallModel(langCode);
        debugPrint('ML Kit model for "$langCode" downloaded successfully from custom server.');
      } catch (fallbackError) {
        debugPrint('Fallback download also failed. Reason: $fallbackError');
        throw Exception(
          'Failed to download model for "$langCode" from both Google and custom server.',
        );
      }
    }
  }

  Future<bool> isModelDownloaded(String langCode) =>
      _googleModelManager.isModelDownloaded(langCode);

  Future<bool> deleteModel(String langCode) =>
      _googleModelManager.deleteModel(langCode);

  // ── ONNX model helpers ────────────────────────────────────────────────────

  /// Returns the local directory where ONNX model files are extracted.
  Future<Directory> onnxModelDir(String langPairKey) async {
    final appSupport = await getApplicationSupportDirectory();
    return Directory(p.join(appSupport.path, 'onnx_models', langPairKey));
  }

  /// Checks whether all required ONNX model files are present on disk.
  Future<OnnxModelStatus> getOnnxModelStatus(String langPairKey) async {
    if (_activeOnnxDownloads.containsKey(langPairKey)) {
      return OnnxModelStatus.downloading;
    }
    final service = OnnxTranslationService();
    final ready = await service.isModelReady(langPairKey);
    return ready ? OnnxModelStatus.ready : OnnxModelStatus.notDownloaded;
  }

  /// Downloads and extracts an ONNX model ZIP for [langPairKey].
  ///
  /// If a download for [langPairKey] is already in progress, the returned
  /// Future will complete when that existing download finishes.
  ///
  /// Optionally provide [onProgress] to receive progress updates (0.0 – 1.0).
  Future<void> downloadOnnxModel(
    String langPairKey, {
    DownloadProgressCallback? onProgress,
  }) {
    if (_activeOnnxDownloads.containsKey(langPairKey)) {
      debugPrint('OnnxDownload: "$langPairKey" already in progress, reusing...');
      return _activeOnnxDownloads[langPairKey]!;
    }

    final future = _downloadOnnxModelImpl(langPairKey, onProgress: onProgress)
        .whenComplete(() => _activeOnnxDownloads.remove(langPairKey));
    _activeOnnxDownloads[langPairKey] = future;
    
    // We attach a dummy catchError here to prevent unhandled exception
    // from freezing the IDE debugger, but we STILL return the original future
    // so the caller can catch the error and update the UI.
    future.catchError((_) {});
    
    return future;
  }

  Future<void> _downloadOnnxModelImpl(
    String langPairKey, {
    DownloadProgressCallback? onProgress,
  }) async {
    final baseUrl = 'https://huggingface.co/onnx-community/$langPairKey/resolve/main';
    debugPrint('OnnxDownload: Downloading "$langPairKey" from $baseUrl...');

    final targetDir = await onnxModelDir(langPairKey);
    if (await targetDir.exists()) {
      await targetDir.delete(recursive: true);
    }
    await targetDir.create(recursive: true);

    // Look up the pair to decide which ONNX variant to download
    final pair = kSupportedOnnxPairs.firstWhere(
      (p) => p.key == langPairKey,
      orElse: () => const OnnxLangPair(
        key: '', sourceBcp: '', targetBcp: '', displayName: ''),
    );
    final suffix = pair.useFp16 ? 'fp16' : 'quantized';

    // The files we need and where they map to locally
    final filesToDownload = {
      'onnx/encoder_model_$suffix.onnx': 'encoder_model.onnx',
      'onnx/decoder_model_$suffix.onnx': 'decoder_model.onnx',
      'onnx/decoder_with_past_model_$suffix.onnx': 'decoder_with_past_model.onnx',
      'source.spm': 'source.spm',
      'target.spm': 'target.spm',
    };

    final client = http.Client();
    try {
      int totalFiles = filesToDownload.length;
      int completedFiles = 0;

      for (final entry in filesToDownload.entries) {
        final remotePath = entry.key;
        final localName = entry.value;
        final url = '$baseUrl/$remotePath';
        
        final request = http.Request('GET', Uri.parse(url));
        final response = await client.send(request).timeout(const Duration(seconds: 15));

        if (response.statusCode != 200) {
          // Drain the stream to free the connection
          response.stream.drain();
          throw Exception('OnnxDownload: HTTP ${response.statusCode} for $url');
        }

        final finalFile = File(p.join(targetDir.path, localName));
        final tmpFile = File(p.join(targetDir.path, '$localName.tmp'));
        final sink = tmpFile.openWrite();
        
        int totalBytes = response.contentLength ?? (100 * 1024 * 1024); // fallback 100MB
        int receivedBytes = 0;

        await for (final chunk in response.stream.timeout(const Duration(seconds: 15))) {
          sink.add(chunk);
          receivedBytes += chunk.length;
          
          double fileProgress = receivedBytes / totalBytes;
          if (fileProgress > 1.0) fileProgress = 1.0;
          
          double overallProgress = (completedFiles + fileProgress) / totalFiles;
          onProgress?.call(overallProgress);
          
          // Workaround for some connections hanging at the very end
          if (response.contentLength != null && receivedBytes >= response.contentLength!) {
            break;
          }
        }
        await sink.close();
        await tmpFile.rename(finalFile.path);
        completedFiles++;
        onProgress?.call(completedFiles / totalFiles);
      }

      debugPrint('OnnxDownload: "$langPairKey" ready at ${targetDir.path}');
    } catch (e) {
      // Clean up partial files on error
      if (await targetDir.exists()) {
        await targetDir.delete(recursive: true);
      }
      rethrow;
    } finally {
      client.close();
    }
  }

  /// Deletes a downloaded ONNX model from device storage.
  Future<void> deleteOnnxModel(String langPairKey) async {
    final dir = await onnxModelDir(langPairKey);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
      debugPrint('OnnxDownload: Deleted model "$langPairKey"');
    }
  }

  /// Returns approximate size on disk for a downloaded ONNX model, in MB.
  Future<double> getOnnxModelSizeMb(String langPairKey) async {
    final dir = await onnxModelDir(langPairKey);
    if (!await dir.exists()) return 0.0;
    int totalBytes = 0;
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) {
        totalBytes += await entity.length();
      }
    }
    return totalBytes / (1024 * 1024);
  }
}
