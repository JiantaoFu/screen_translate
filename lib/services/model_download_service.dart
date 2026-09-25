import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

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

/// Called with true when a download is stalled waiting for the network,
/// and with false when it moves again.
typedef WaitingForNetworkCallback = void Function(bool waiting);

/// One reading of a Quick-mode download: [progress] is null while no byte
/// count is known; [waiting] is true while Android's DownloadManager has
/// paused it to wait for the network.
typedef QuickDownloadReading = ({double? progress, bool waiting});

// ─── ModelDownloadService ─────────────────────────────────────────────────────

class ModelDownloadService {
  final OnDeviceTranslatorModelManager _googleModelManager;
  final CustomModelManager _customModelManager;

  /// Tracks active ONNX download tasks so we avoid duplicate concurrent
  /// downloads, and so every screen agrees on what's currently in flight.
  ///
  /// MUST be static: ModelDownloadService() is constructed fresh at every
  /// call site (home screen, Settings screen, etc.) rather than as a
  /// singleton. An instance field here meant each screen tracked its own
  /// downloads in total isolation — a download started from the home
  /// screen's language picker was invisible to Settings' status checks
  /// (and vice versa), so Settings never reflected an in-progress download
  /// kicked off elsewhere, and two screens could even race to download the
  /// same pack into the same directory simultaneously.
  static final Map<String, Future<void>> _activeOnnxDownloads = {};

  /// Latest known progress (0.0-1.0) per in-flight ONNX download, plus every
  /// callback currently watching each key. Also static, for the same reason
  /// as [_activeOnnxDownloads] above: whichever screen calls
  /// downloadOnnxModel() first used to be the ONLY one that ever heard
  /// progress ticks — a second screen calling it while a download was
  /// already in flight just got handed the existing Future with its
  /// onProgress silently dropped, so it sat frozen at 0% until the download
  /// finished elsewhere. Now every caller's onProgress is registered as a
  /// listener and gets the live feed, whether it started the download or
  /// joined one already running.
  static final Map<String, double> _onnxProgress = {};
  static final Map<String, List<DownloadProgressCallback>> _onnxProgressListeners = {};

  static void _emitOnnxProgress(String key, double progress) {
    _onnxProgress[key] = progress;
    for (final cb in List<DownloadProgressCallback>.of(_onnxProgressListeners[key] ?? const [])) {
      cb(progress);
    }
  }

  ModelDownloadService()
      : _googleModelManager = OnDeviceTranslatorModelManager(),
        _customModelManager = CustomModelManager();

  // ── Google ML Kit helpers ─────────────────────────────────────────────────

  /// Quick-mode (ML Kit) downloads in flight, shared across screens for the
  /// same reasons as [_activeOnnxDownloads]: the home screen's language
  /// picker and Settings must agree on what's downloading, and both must
  /// get the live progress feed whichever one started it.
  static final Map<String, Future<void>> _activeQuickDownloads = {};

  /// Latest real progress (0.0-1.0) per in-flight Quick download. Absent
  /// until a real byte count is known — ML Kit spends the first moments
  /// fetching model metadata before any bytes move, and the UI shows an
  /// indeterminate spinner then rather than a made-up percentage.
  static final Map<String, double> _quickProgress = {};
  static final Map<String, List<DownloadProgressCallback>> _quickProgressListeners = {};
  static final Map<String, bool> _quickWaiting = {};
  static final Map<String, List<WaitingForNetworkCallback>> _quickWaitingListeners = {};

  static const _nativeChannel = MethodChannel('com.lomoware.screen_translate/model_download');

  /// Reads the state of the ML Kit download for a language. ML Kit's own
  /// API reports nothing until the download finishes, but it downloads
  /// through Android's DownloadManager, which the native side reads.
  /// Returns null when no such download is running. Replaceable in tests.
  @visibleForTesting
  static Future<QuickDownloadReading?> Function(String langCode) quickProgressProbe = (langCode) async {
    try {
      final result = await _nativeChannel
          .invokeMapMethod<String, Object?>('getMlKitDownloadProgress', {'lang': langCode});
      if (result == null) return null;
      final downloaded = result['downloaded'] as int? ?? 0;
      final total = result['total'] as int? ?? -1;
      return (
        progress: total > 0 ? downloaded / total : null,
        waiting: result['waiting'] as bool? ?? false,
      );
    } catch (_) {
      return null;
    }
  };

  @visibleForTesting
  static Duration quickProgressPollInterval = const Duration(milliseconds: 400);

  static void _emitQuickProgress(String langCode, double progress) {
    _quickProgress[langCode] = progress;
    for (final cb in List<DownloadProgressCallback>.of(_quickProgressListeners[langCode] ?? const [])) {
      cb(progress);
    }
  }

  static void _emitQuickWaiting(String langCode, bool waiting) {
    if ((_quickWaiting[langCode] ?? false) == waiting) return;
    _quickWaiting[langCode] = waiting;
    for (final cb in List<WaitingForNetworkCallback>.of(_quickWaitingListeners[langCode] ?? const [])) {
      cb(waiting);
    }
  }

  /// Whether a Quick-mode model download for [langCode] is in flight,
  /// started from any screen.
  static bool isQuickDownloading(String langCode) =>
      _activeQuickDownloads.containsKey(langCode);

  /// Downloads a Google ML Kit model with a custom-server fallback.
  ///
  /// If a download for [langCode] is already in flight, joins it. Every
  /// caller's [onProgress] gets the live progress (0.0-1.0), whether it
  /// started the download or joined it, and [onWaitingForNetwork] hears
  /// when it stalls waiting for the network and when it resumes.
  Future<void> downloadModelWithFallback(
    String langCode, {
    DownloadProgressCallback? onProgress,
    WaitingForNetworkCallback? onWaitingForNetwork,
  }) {
    if (onProgress != null) {
      _quickProgressListeners.putIfAbsent(langCode, () => []).add(onProgress);
      final current = _quickProgress[langCode];
      if (current != null) onProgress(current);
    }
    if (onWaitingForNetwork != null) {
      _quickWaitingListeners.putIfAbsent(langCode, () => []).add(onWaitingForNetwork);
      if (_quickWaiting[langCode] ?? false) onWaitingForNetwork(true);
    }

    final existing = _activeQuickDownloads[langCode];
    if (existing != null) return existing;

    // Poll the real byte count while the download runs. Capped at 99%:
    // ML Kit still unpacks and verifies the model after the bytes arrive,
    // so 100% is only reported once the download call actually returns.
    var lastProgress = 0.0;
    final poller = Timer.periodic(quickProgressPollInterval, (_) async {
      final reading = await quickProgressProbe(langCode);
      if (reading == null || !_activeQuickDownloads.containsKey(langCode)) return;
      _emitQuickWaiting(langCode, reading.waiting);
      final p = reading.progress;
      if (p == null) return;
      final capped = p.clamp(0.0, 0.99);
      // DownloadManager can briefly report a smaller total before the
      // real one arrives; never let the bar run backwards.
      if (capped < lastProgress) return;
      lastProgress = capped;
      _emitQuickProgress(langCode, capped);
    });

    // If Google's download fails partway, the custom-server fallback starts
    // from zero. Map it onto what's left of the bar instead of jumping back.
    double? fallbackBase;
    final future = _downloadModelWithFallbackImpl(
      langCode,
      onFallbackProgress: (p) {
        final base = fallbackBase ??= lastProgress;
        lastProgress = (base + p.clamp(0.0, 1.0) * (0.99 - base)).clamp(0.0, 0.99);
        _emitQuickProgress(langCode, lastProgress);
      },
    ).then((_) {
      poller.cancel();
      _emitQuickProgress(langCode, 1.0);
    }).whenComplete(() {
      poller.cancel();
      _activeQuickDownloads.remove(langCode);
      _quickProgress.remove(langCode);
      _quickProgressListeners.remove(langCode);
      _quickWaiting.remove(langCode);
      _quickWaitingListeners.remove(langCode);
    });
    _activeQuickDownloads[langCode] = future;
    // Same as downloadOnnxModel: keep an unawaited failure from being
    // reported as unhandled, while callers still get the error.
    future.catchError((_) {});
    return future;
  }

  Future<void> _downloadModelWithFallbackImpl(
    String langCode, {
    required DownloadProgressCallback onFallbackProgress,
  }) async {
    try {
      debugPrint('Attempting to download ML Kit model for "$langCode" from Google...');
      await _googleModelManager.downloadModel(langCode, isWifiRequired: false);
      debugPrint('ML Kit model for "$langCode" downloaded successfully from Google.');
    } catch (e) {
      debugPrint('Failed to download from Google. Reason: $e');
      debugPrint('Initiating fallback to custom server...');
      try {
        await _customModelManager.downloadAndInstallModel(langCode, onProgress: onFallbackProgress);
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
    if (onProgress != null) {
      _onnxProgressListeners.putIfAbsent(langPairKey, () => []).add(onProgress);
      final current = _onnxProgress[langPairKey];
      if (current != null) onProgress(current);
    }

    if (_activeOnnxDownloads.containsKey(langPairKey)) {
      debugPrint('OnnxDownload: "$langPairKey" already in progress, reusing...');
      return _activeOnnxDownloads[langPairKey]!;
    }

    final future = _downloadOnnxModelImpl(
      langPairKey,
      onProgress: (p) => _emitOnnxProgress(langPairKey, p),
    ).whenComplete(() {
      debugPrint('OnnxDownload: [$langPairKey] whenComplete fired, removing from active map.');
      _activeOnnxDownloads.remove(langPairKey);
      _onnxProgress.remove(langPairKey);
      _onnxProgressListeners.remove(langPairKey);
    });
    _activeOnnxDownloads[langPairKey] = future;

    // We attach a dummy catchError here to prevent unhandled exception
    // from freezing the IDE debugger, but we STILL return the original future
    // so the caller can catch the error and update the UI.
    future.catchError((_) {});

    debugPrint('OnnxDownload: [$langPairKey] downloadOnnxModel() returning future to caller.');
    return future;
  }

  // ── Pivot pairs (e.g. zh→en→es) ───────────────────────────────────────────

  /// Ready only when BOTH hops are downloaded; downloading if either hop is
  /// actively downloading.
  Future<OnnxModelStatus> getOnnxPivotStatus(OnnxPivotPair pivot) async {
    if (_activeOnnxDownloads.containsKey(pivot.firstHopKey) ||
        _activeOnnxDownloads.containsKey(pivot.secondHopKey)) {
      return OnnxModelStatus.downloading;
    }
    final service = OnnxTranslationService();
    final firstReady = await service.isModelReady(pivot.firstHopKey);
    final secondReady = await service.isModelReady(pivot.secondHopKey);
    return (firstReady && secondReady) ? OnnxModelStatus.ready : OnnxModelStatus.notDownloaded;
  }

  /// Downloads whichever hop(s) of [pivot] aren't already present — e.g. if
  /// the user already has the plain zh→en pack downloaded, only the en→es
  /// leg is fetched. Progress is split evenly across the legs actually
  /// downloaded.
  Future<void> downloadOnnxPivot(
    OnnxPivotPair pivot, {
    DownloadProgressCallback? onProgress,
  }) async {
    final service = OnnxTranslationService();
    final legs = [
      if (!await service.isModelReady(pivot.firstHopKey)) pivot.firstHopKey,
      if (!await service.isModelReady(pivot.secondHopKey)) pivot.secondHopKey,
    ];
    if (legs.isEmpty) return;

    for (int i = 0; i < legs.length; i++) {
      await downloadOnnxModel(
        legs[i],
        onProgress: (p) => onProgress?.call((i + p) / legs.length),
      );
      debugPrint('OnnxDownload: [pivot] leg ${legs[i]} awaited-return complete (${i + 1}/${legs.length}).');
    }
  }

  Future<void> _downloadOnnxModelImpl(
    String langPairKey, {
    DownloadProgressCallback? onProgress,
  }) async {
    final targetDir = await onnxModelDir(langPairKey);
    await targetDir.create(recursive: true);
    // Clean up only stray leftovers from a previous interrupted attempt
    // (half-written .tmp files) — fully-renamed final files are left in
    // place so a retry resumes rather than re-downloading a multi-hundred-
    // MB pack from scratch just because one file failed. This matters in
    // practice: Android closes the app's network sockets a few seconds
    // after it's backgrounded (confirmed via logcat — no foreground
    // service here to keep them alive), so a background-interrupted
    // download is common, not exceptional.
    await for (final entity in targetDir.list()) {
      if (entity is File && entity.path.endsWith('.tmp')) {
        await entity.delete();
      }
    }

    // Look up the pair to decide which ONNX variant to download
    final pair = kSupportedOnnxPairs.firstWhere(
      (p) => p.key == langPairKey,
      orElse: () => const OnnxLangPair(
        key: '', sourceBcp: '', targetBcp: '', displayName: ''),
    );

    // Self-hosted pairs (not pre-converted on onnx-community) live in a
    // subfolder of a single shared repo, flat (no "onnx/" prefix), and are
    // always quantized — we don't produce fp16 variants ourselves.
    final String baseUrl;
    final Map<String, String> filesToDownload;
    if (pair.customRepo != null) {
      baseUrl = 'https://huggingface.co/${pair.customRepo}/resolve/main/$langPairKey';
      filesToDownload = {
        'encoder_model_quantized.onnx': 'encoder_model.onnx',
        'decoder_model_quantized.onnx': 'decoder_model.onnx',
        'decoder_with_past_model_quantized.onnx': 'decoder_with_past_model.onnx',
        'source.spm': 'source.spm',
        'vocab.json': 'vocab.json',
      };
    } else {
      baseUrl = 'https://huggingface.co/onnx-community/$langPairKey/resolve/main';
      final suffix = pair.useFp16 ? 'fp16' : 'quantized';
      filesToDownload = {
        'onnx/encoder_model_$suffix.onnx': 'encoder_model.onnx',
        'onnx/decoder_model_$suffix.onnx': 'decoder_model.onnx',
        'onnx/decoder_with_past_model_$suffix.onnx': 'decoder_with_past_model.onnx',
        'source.spm': 'source.spm',
        'vocab.json': 'vocab.json',
      };
    }
    debugPrint('OnnxDownload: Downloading "$langPairKey" from $baseUrl...');

    final client = http.Client();
    try {
      int totalFiles = filesToDownload.length;
      int completedFiles = 0;

      for (final entry in filesToDownload.entries) {
        final remotePath = entry.key;
        final localName = entry.value;
        final finalFile = File(p.join(targetDir.path, localName));

        if (await finalFile.exists()) {
          completedFiles++;
          onProgress?.call(completedFiles / totalFiles);
          debugPrint('OnnxDownload: [$localName] already present, skipping ($completedFiles/$totalFiles).');
          continue;
        }

        final url = '$baseUrl/$remotePath';

        // Bound the ENTIRE per-file operation (network + disk I/O) so that a
        // stall anywhere — including sink.close()/rename(), which have no
        // timeout of their own — surfaces as a retryable error instead of
        // hanging the UI forever at "100%, downloading...".
        debugPrint('OnnxDownload: [$localName] requesting $url');
        await Future(() async {
          final request = http.Request('GET', Uri.parse(url));
          final response = await client.send(request).timeout(const Duration(seconds: 15));
          debugPrint('OnnxDownload: [$localName] connected, status=${response.statusCode}, '
              'contentLength=${response.contentLength}');

          if (response.statusCode != 200) {
            // Drain the stream to free the connection
            response.stream.drain();
            throw Exception('OnnxDownload: HTTP ${response.statusCode} for $url');
          }

          final tmpFile = File(p.join(targetDir.path, '$localName.tmp'));
          final sink = tmpFile.openWrite();

          int totalBytes = response.contentLength ?? (100 * 1024 * 1024); // fallback 100MB
          int receivedBytes = 0;

          await for (final chunk in response.stream.timeout(const Duration(seconds: 15))) {
            sink.add(chunk);
            receivedBytes += chunk.length;

            // Cap in-flight progress below 100% — the file isn't actually done
            // until it's flushed and renamed below. Showing 100% here would
            // be a lie: there's still real work left, and the user has no way
            // to tell "100% and truly done" apart from "100% and still stuck".
            double fileProgress = (receivedBytes / totalBytes).clamp(0.0, 0.99);

            double overallProgress = (completedFiles + fileProgress) / totalFiles;
            onProgress?.call(overallProgress);

            // Workaround for some connections hanging at the very end
            if (response.contentLength != null && receivedBytes >= response.contentLength!) {
              break;
            }
          }
          debugPrint('OnnxDownload: [$localName] stream done, received=$receivedBytes bytes, '
              'closing sink...');
          await sink.close();
          debugPrint('OnnxDownload: [$localName] sink closed, renaming...');
          await tmpFile.rename(finalFile.path);
          debugPrint('OnnxDownload: [$localName] renamed to final path.');
        }).timeout(
          const Duration(seconds: 180),
          onTimeout: () => throw TimeoutException(
              'OnnxDownload: Timed out downloading/finalizing $remotePath'),
        );

        completedFiles++;
        onProgress?.call(completedFiles / totalFiles);
        debugPrint('OnnxDownload: [$localName] complete ($completedFiles/$totalFiles files).');
      }

      debugPrint('OnnxDownload: "$langPairKey" ready at ${targetDir.path}');
    } catch (e) {
      debugPrint('OnnxDownload: [$langPairKey] caught error: $e');
      // Deliberately NOT deleting targetDir here — any files already fully
      // renamed to their final name stay put, so the next attempt (manual
      // retry or auto-resume) skips them via the exists() check above
      // instead of re-downloading a multi-hundred-MB pack from scratch.
      // The failed file's own .tmp remnant, if any, is swept up at the
      // start of the next attempt.
      rethrow;
    } finally {
      debugPrint('OnnxDownload: [$langPairKey] finally block — closing client...');
      client.close();
      debugPrint('OnnxDownload: [$langPairKey] client closed, _downloadOnnxModelImpl returning.');
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
