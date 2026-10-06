import 'dart:async';

/// Runs [action] once, then up to [maxRetries] more times after failures.
///
/// Each attempt is capped by [attemptTimeout]; a timeout counts as a failure
/// so a stalled download cannot spin forever. Backoff between attempts is
/// [initialBackoff] * 2^(attempt-1).
///
/// Pure control-flow helper so ML Kit and ONNX downloads share one policy and
/// unit tests can drive it without touching the network.
Future<T> withRetries<T>(
  Future<T> Function() action, {
  int maxRetries = 2,
  Duration attemptTimeout = const Duration(minutes: 3),
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
      return await action().timeout(attemptTimeout);
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
