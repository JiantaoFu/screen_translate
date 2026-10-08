import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Runs [action] once, then up to [maxRetries] more times after failures.
///
/// Each attempt is capped by [attemptTimeout] when given; a timeout counts as
/// a failure. Pass null when [action] has its own stall-based timeouts, so a
/// slow but steady download is never cut off by total duration. Backoff between attempts is
/// [initialBackoff] * 2^(attempt-1).
///
/// Pure control-flow helper so ML Kit and ONNX downloads share one policy and
/// unit tests can drive it without touching the network.
Future<T> withRetries<T>(
  Future<T> Function() action, {
  int maxRetries = 2,
  Duration? attemptTimeout = const Duration(minutes: 3),
  Duration initialBackoff = const Duration(seconds: 2),
  Future<void> Function(Duration delay)? sleep,
  void Function(int attempt, Object error)? onAttemptFailed,
}) async {
  assert(maxRetries >= 0);
  Object? lastError;
  final doSleep = sleep ?? Future<void>.delayed;
  final totalAttempts = maxRetries + 1;
  for (var attempt = 1; attempt <= totalAttempts; attempt++) {
    try {
      final run = action();
      return await (attemptTimeout == null ? run : run.timeout(attemptTimeout));
    } catch (e) {
      lastError = e;
      onAttemptFailed?.call(attempt, e);
      if (attempt >= totalAttempts) break;
      final backoff = initialBackoff * (1 << (attempt - 1));
      await doSleep(backoff);
    }
  }
  throw lastError!;
}

/// Downloads [url] to [target] through `<target>.tmp`, resuming a partial
/// .tmp with an HTTP Range request and retrying up to [maxAttempts] times.
///
/// Only a stall fails an attempt: no response or no data for
/// [stallTimeout]. There used to be a fixed 3-minute cap per file, and on a
/// slow connection the 182 MB ja→en decoder could never finish in time;
/// each retry also deleted the partial file and started from zero.
Future<void> resumableDownload({
  required http.Client client,
  required String url,
  required File target,
  void Function(int received, int? total)? onBytes,
  Duration stallTimeout = const Duration(seconds: 30),
  int maxAttempts = 6,
  Duration retryDelay = const Duration(seconds: 2),
}) async {
  final tmp = File('${target.path}.tmp');
  Object? lastError;
  for (var attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      var offset = await tmp.exists() ? await tmp.length() : 0;
      final request = http.Request('GET', Uri.parse(url));
      if (offset > 0) request.headers['Range'] = 'bytes=$offset-';
      final response = await client.send(request).timeout(stallTimeout);
      final int? total;
      final IOSink sink;
      if (response.statusCode == 206 && offset > 0) {
        total = _totalFromContentRange(response.headers['content-range']) ??
            (response.contentLength == null ? null : offset + response.contentLength!);
        sink = tmp.openWrite(mode: FileMode.append);
      } else if (response.statusCode == 200) {
        offset = 0; // server ignored the Range: start over
        total = response.contentLength;
        sink = tmp.openWrite();
      } else {
        unawaited(response.stream.drain<void>().catchError((_) {}));
        if (response.statusCode == 416) {
          // The partial file is no longer valid for this URL.
          await tmp.delete();
          throw Exception('Download: range not satisfiable, restarting $url');
        }
        final retryable = response.statusCode >= 500 || response.statusCode == 408 || response.statusCode == 429;
        final error = HttpException('Download: HTTP ${response.statusCode} for $url');
        if (!retryable) throw _NonRetryable(error);
        throw error;
      }
      var received = offset;
      try {
        await for (final chunk in response.stream.timeout(stallTimeout)) {
          sink.add(chunk);
          received += chunk.length;
          onBytes?.call(received, total);
          // Some connections hang at the very end instead of closing.
          if (total != null && received >= total) break;
        }
      } finally {
        await sink.close().timeout(stallTimeout);
      }
      if (total != null && received < total) {
        throw Exception('Download: connection closed at $received of $total bytes');
      }
      await tmp.rename(target.path).timeout(stallTimeout);
      return;
    } on _NonRetryable catch (e) {
      throw e.error;
    } catch (e) {
      lastError = e;
      debugPrint('Download: attempt $attempt/$maxAttempts for $url failed: $e');
      if (attempt < maxAttempts) await Future<void>.delayed(retryDelay);
    }
  }
  throw lastError!;
}

int? _totalFromContentRange(String? header) {
  // "bytes 100-199/200"
  final total = header?.split('/').last;
  return total == null ? null : int.tryParse(total);
}


/// An HTTP error that retrying won't fix (e.g. 404).
class _NonRetryable implements Exception {
  final Object error;
  _NonRetryable(this.error);
}
