import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:screen_translate/services/download_retry.dart';

/// Quick-mode (ML Kit) backup server, used when Google's own model download
/// fails or stalls (common on some Middle East networks).
class CustomModelManager {
  final String baseUrl = 'https://huggingface.co/fuji246/small-translation/resolve/main';

  final http.Client Function() _clientFactory;
  final Future<Directory> Function() _cacheDir;

  /// A pack download fails only after this long with no bytes arriving,
  /// never because of its total duration: ~30 MB on a slow link can take
  /// many minutes.
  final Duration stallTimeout;

  /// Stalls tolerated per call before giving up; each one resumes from the
  /// bytes already on disk.
  final int maxAttempts;
  final Duration retryDelay;

  CustomModelManager({
    http.Client Function()? clientFactory,
    Future<Directory> Function()? cacheDir,
    this.stallTimeout = const Duration(seconds: 30),
    this.maxAttempts = 4,
    this.retryDelay = const Duration(seconds: 2),
  })  : _clientFactory = clientFactory ?? http.Client.new,
        _cacheDir = cacheDir ?? _defaultCacheDir;

  static Future<Directory> _defaultCacheDir() async =>
      Directory(path.join((await getApplicationSupportDirectory()).path, 'mlkit_backup'));

  /// Gets the directory where the ML Kit model folder should be unzipped.
  Future<Directory> _getExtractionDir() async {
    final appDir = await getApplicationSupportDirectory();
    return Directory(path.join(appDir.parent.path, 'no_backup'));
  }

  /// Downloads `<langCode>.zip` into the cache dir and returns it.
  ///
  /// Resumable: bytes go to `<zip>.tmp`, which is kept when a call fails, so
  /// the next attempt (another retry, or the user tapping Retry later)
  /// continues with an HTTP Range request instead of starting over. Before
  /// 1.2.4 the whole zip was buffered in memory with no timeout and every
  /// retry restarted from zero.
  @visibleForTesting
  Future<File> downloadZip(
    String langCode, {
    void Function(double progress)? onProgress,
  }) async {
    final dir = await _cacheDir();
    await dir.create(recursive: true);
    final zip = File(path.join(dir.path, '$langCode.zip'));
    if (await zip.exists()) return zip; // finished earlier, extraction failed
    final client = _clientFactory();
    try {
      await resumableDownload(
        client: client,
        url: '$baseUrl/$langCode.zip',
        target: zip,
        stallTimeout: stallTimeout,
        maxAttempts: maxAttempts,
        retryDelay: retryDelay,
        onBytes: (received, total) {
          if (total != null && total > 0) onProgress?.call((received / total).clamp(0.0, 1.0));
        },
      );
    } finally {
      client.close();
    }
    return zip;
  }

  Future<void> downloadAndInstallModel(
    String langCode, {
    void Function(double progress)? onProgress,
  }) async {
    debugPrint('Fallback: Downloading model for $langCode from $baseUrl...');
    final zip = await downloadZip(langCode, onProgress: onProgress);
    try {
      final archive = ZipDecoder().decodeBytes(await zip.readAsBytes());
      final extractionDir = await _getExtractionDir();
      await extractionDir.create(recursive: true);
      debugPrint('Unzipping and installing model files to ${extractionDir.path}...');
      for (final file in archive) {
        if (!file.isFile) continue;
        final outFile = File(path.join(extractionDir.path, file.name));
        await outFile.create(recursive: true);
        await outFile.writeAsBytes(file.content as List<int>);
      }
      debugPrint('Fallback model for $langCode installed successfully.');
      await zip.delete();
    } catch (e) {
      // A corrupt zip must not be reused by the next attempt.
      if (await zip.exists()) await zip.delete();
      rethrow;
    }
  }
}
