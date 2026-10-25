import 'package:shared_preferences/shared_preferences.dart';

/// Native ONNX Runtime crashes (SIGILL in libonnxruntime.so, OOM kills) can't
/// be caught from Dart or Kotlin, so the app would crash again on every
/// attempt. This persists an "in flight" marker around each model load and
/// inference: if the marker is still set on the next launch, the previous
/// run died inside ONNX.
///
///   1 unfinished run  -> run ONNX on plain CPU (no XNNPACK), sticky
///   2 consecutive     -> stop using ONNX on this device; ML Kit is used
/// A run that finishes (success or a normal Dart error) resets the count.
class OnnxCrashGuard {
  static const kInFlight = 'onnx_guard_in_flight';
  static const kStrikes = 'onnx_guard_strikes';
  static const kCpuOnly = 'onnx_guard_cpu_only';
  static const kNoticeShown = 'onnx_guard_disabled_notice_shown';

  final Future<SharedPreferences> Function() _prefs;
  OnnxCrashGuard({Future<SharedPreferences> Function()? prefs})
      : _prefs = prefs ?? SharedPreferences.getInstance;

  int? _strikes;
  bool _cpuOnly = false;
  bool _inFlight = false;

  /// Reads the persisted state once per process; a leftover in-flight marker
  /// counts as a strike.
  Future<int> strikes() async {
    if (_strikes != null) return _strikes!;
    final p = await _prefs();
    var s = p.getInt(kStrikes) ?? 0;
    _cpuOnly = p.getBool(kCpuOnly) ?? false;
    if (p.getBool(kInFlight) ?? false) {
      s++;
      await p.setInt(kStrikes, s);
      await p.setBool(kInFlight, false);
      if (!_cpuOnly) {
        _cpuOnly = true;
        await p.setBool(kCpuOnly, true);
      }
    }
    return _strikes = s;
  }

  Future<bool> cpuOnly() async {
    await strikes();
    return _cpuOnly;
  }

  Future<bool> disabled() async => await strikes() >= 2;

  /// Runs [body] with the marker set. Nested calls (pivot pairs) share it.
  Future<T> guard<T>(Future<T> Function() body) async {
    await strikes();
    if (_inFlight) return body();
    final p = await _prefs();
    _inFlight = true;
    await p.setBool(kInFlight, true);
    try {
      final r = await body();
      // Finished inference: the crash count is about consecutive runs.
      if (_strikes != 0) {
        _strikes = 0;
        await p.setInt(kStrikes, 0);
      }
      return r;
    } finally {
      _inFlight = false;
      await p.setBool(kInFlight, false);
    }
  }

  /// True exactly once after ONNX was disabled on this device.
  Future<bool> takeDisabledNotice() async {
    if (!await disabled()) return false;
    final p = await _prefs();
    if (p.getBool(kNoticeShown) ?? false) return false;
    await p.setBool(kNoticeShown, true);
    return true;
  }
}
