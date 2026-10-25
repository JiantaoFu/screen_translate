import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:screen_translate/services/onnx_crash_guard.dart';
import 'package:screen_translate/services/onnx_translation_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // A new guard simulates a new process reading the persisted state.
  OnnxCrashGuard relaunch() => OnnxCrashGuard();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('clean runs never strike', () async {
    final g = relaunch();
    expect(await g.guard(() async => 'ok'), 'ok');
    expect(await relaunch().strikes(), 0);
    expect(await relaunch().cpuOnly(), isFalse);
  });

  test('a Dart exception clears the marker (not a native crash)', () async {
    await expectLater(relaunch().guard(() async => throw StateError('x')), throwsStateError);
    expect(await relaunch().strikes(), 0);
  });

  test('marker left set: first relaunch uses CPU only, second disables ONNX', () async {
    SharedPreferences.setMockInitialValues({OnnxCrashGuard.kInFlight: true});
    final first = relaunch();
    expect(await first.cpuOnly(), isTrue);
    expect(await first.disabled(), isFalse);

    // Crash again while running on CPU.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(OnnxCrashGuard.kInFlight, true);
    final second = relaunch();
    expect(await second.disabled(), isTrue);
    expect(await second.takeDisabledNotice(), isTrue);
    expect(await relaunch().takeDisabledNotice(), isFalse);
  });

  test('nested guard calls (pivot pairs) keep one marker', () async {
    final g = relaunch();
    await g.guard(() => g.guard(() async {
          final p = await SharedPreferences.getInstance();
          expect(p.getBool(OnnxCrashGuard.kInFlight), isTrue);
        }));
    final p = await SharedPreferences.getInstance();
    expect(p.getBool(OnnxCrashGuard.kInFlight), isFalse);
  });

  test('disabled service throws OnnxUnavailableException without loading', () async {
    SharedPreferences.setMockInitialValues({OnnxCrashGuard.kStrikes: 2});
    final s = OnnxTranslationService(lowMemoryReason: () async => null);
    await expectLater(
      s.translateText(text: 'hi', sourceLanguage: 'en', targetLanguage: 'zh'),
      throwsA(isA<OnnxUnavailableException>()),
    );
  });

  test('providers drop XNNPACK on the CPU-only path', () {
    expect(OnnxTranslationService.providersFor(xnnpack: true), [OrtProvider.XNNPACK, OrtProvider.CPU]);
    expect(OnnxTranslationService.providersFor(xnnpack: false), [OrtProvider.CPU]);
  });

  test('a finished run resets the crash count; CPU-only stays sticky', () async {
    SharedPreferences.setMockInitialValues({OnnxCrashGuard.kInFlight: true});
    final g = relaunch();
    expect(await g.strikes(), 1);
    await g.guard(() async => 'ok');
    expect(await relaunch().strikes(), 0);
    expect(await relaunch().cpuOnly(), isTrue);
  });

  test('two unfinished runs separated by a success do not disable ONNX', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(OnnxCrashGuard.kInFlight, true); // crash 1
    final a = relaunch();
    await a.guard(() async => 'ok'); // success resets
    await prefs.setBool(OnnxCrashGuard.kInFlight, true); // crash 2
    final b = relaunch();
    expect(await b.strikes(), 1);
    expect(await b.disabled(), isFalse);
    expect(await b.cpuOnly(), isTrue);
  });
}
