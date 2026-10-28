import 'package:screen_translate/services/onnx_crash_guard.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screen_translate/services/onnx_translation_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:screen_translate/providers/translation_provider.dart';

import '../mocks/fake_services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('TranslationProvider ONNX Fallback Logic', () {
    late TranslationProvider provider;
    late FakeTranslationService mockMlKit;
    late FakeOnnxTranslationService mockOnnx;

    setUp(() {
      mockMlKit = FakeTranslationService();
      mockOnnx = FakeOnnxTranslationService();

      provider = TranslationProvider(
        null,
        FakeOCRService(),
        mockMlKit,
        FakeOverlayService(),
        llmTranslationService: FakeLLMTranslationService(),
        onnxTranslationService: mockOnnx,
      );
    });

    test('Uses ONNX when model is ready and supported', () async {
      provider.setTranslationMode(TranslationMode.onnx);

      final result = await provider.translateText('Hello');

      expect(result, 'ONNX translated: Hello');
      expect(mockOnnx.callCount, 1);
      expect(mockMlKit.callCount, 0);
    });

    test('Falls back to ML Kit silently when ONNX throws OnnxModelNotReadyException', () async {
      provider.setTranslationMode(TranslationMode.onnx);
      mockOnnx.shouldThrowNotReady = true;

      final result = await provider.translateText('Hello');

      expect(result, 'ML Kit translated: Hello');
      expect(mockOnnx.callCount, 1);
      expect(mockMlKit.callCount, 1);
    });

    test('Falls back to ML Kit silently when ONNX throws UnsupportedError (unsupported pair)', () async {
      provider.setTranslationMode(TranslationMode.onnx);
      mockOnnx.shouldThrowUnsupported = true;

      final result = await provider.translateText('Hello');

      expect(result, 'ML Kit translated: Hello');
      expect(mockOnnx.callCount, 1);
      expect(mockMlKit.callCount, 1);
    });

    test('Falls back to ML Kit when ONNX throws anything else (PlatformException)', () async {
      provider.setTranslationMode(TranslationMode.onnx);
      mockOnnx.throwError = PlatformException(code: 'INFERENCE_ERROR', message: 'boom');

      final result = await provider.translateText('Hello');

      expect(result, 'ML Kit translated: Hello');
      expect(provider.sessionOnnxFailures, 1);
      expect(provider.debugOnnxSkips, ['error_fallback']);
    });

    test('Logs each error_fallback, other reasons once per session', () async {
      provider.setTranslationMode(TranslationMode.onnx);
      mockOnnx.throwError = StateError('ort');
      await provider.translateText('a');
      await provider.translateText('b');
      mockOnnx.throwError = const OnnxUnavailableException('crash_marker_disabled');
      await provider.translateText('c');
      await provider.translateText('d');
      expect(provider.debugOnnxSkips,
          ['error_fallback', 'error_fallback', 'crash_marker_disabled']);
    });

    test('Picking AI Enhanced in Settings re-enables an auto-disabled ONNX', () async {
      SharedPreferences.setMockInitialValues({OnnxCrashGuard.kStrikes: 2});
      provider.setTranslationMode(TranslationMode.onnx);
      mockOnnx.throwError = const OnnxUnavailableException('crash_marker_disabled');
      await provider.translateText('a');
      expect(provider.onnxUnavailable, isTrue);

      mockOnnx.throwError = null;
      provider.setTranslationMode(TranslationMode.onnx, userInitiated: true);
      await provider.debugReEnable;
      expect(provider.onnxUnavailable, isFalse);
      expect(await mockOnnx.guard.disabled(), isFalse);
      expect(provider.debugOnnxSkips.last, 'reenabled');
    });

    test('Non-user mode changes do not re-enable ONNX', () async {
      SharedPreferences.setMockInitialValues({OnnxCrashGuard.kStrikes: 2});
      provider.setTranslationMode(TranslationMode.onnx);
      expect(provider.debugReEnable, isNull);
      expect(await mockOnnx.guard.disabled(), isTrue);
    });

    test('Picking AI Enhanced when not disabled logs nothing', () async {
      SharedPreferences.setMockInitialValues({});
      provider.setTranslationMode(TranslationMode.onnx, userInitiated: true);
      await provider.debugReEnable;
      expect(provider.debugOnnxSkips, isEmpty);
    });

    test('Service downgrade callback is wired to the provider log', () async {
      mockOnnx.onSkipped!('crash_marker_cpu');
      expect(provider.debugOnnxSkips, ['crash_marker_cpu']);
    });

    test('Stops calling ONNX for the session after repeated failures', () async {
      provider.setTranslationMode(TranslationMode.onnx);
      mockOnnx.throwError = StateError('ort');

      for (var i = 0; i < TranslationProvider.kMaxOnnxFailuresPerSession + 2; i++) {
        expect(await provider.translateText('Hi'), 'ML Kit translated: Hi');
      }
      expect(mockOnnx.callCount, TranslationProvider.kMaxOnnxFailuresPerSession);
    });

    test('Falls back to ML Kit when ONNX is unavailable on the device', () async {
      provider.setTranslationMode(TranslationMode.onnx);
      mockOnnx.throwError = const OnnxUnavailableException('low_memory');

      expect(await provider.translateText('Hello'), 'ML Kit translated: Hello');
      expect(provider.onnxUnavailable, isTrue);
      expect(provider.sessionOnnxFailures, 0);
      expect(provider.debugOnnxSkips, ['low_memory']);
    });

    test('Unavailable ONNX notifies listeners once, not per block', () async {
      provider.setTranslationMode(TranslationMode.onnx);
      mockOnnx.throwError = const OnnxUnavailableException('low_memory');
      // _initPreferences() notifies when the saved settings land; wait for
      // that so the count below is only about the ONNX transition.
      await pumpEventQueue();
      var notifications = 0;
      provider.addListener(() => notifications++);

      for (var i = 0; i < 5; i++) {
        expect(await provider.translateText('Hi'), 'ML Kit translated: Hi');
      }

      expect(provider.onnxUnavailable, isTrue);
      expect(notifications, 1, reason: 'only the transition is new state');
    });

    // HomeScreen asks for this note in its first post-frame callback, which
    // runs before TranslationProvider._initPreferences() has restored the
    // saved translation mode from prefs. The note must therefore not be
    // gated on the mode; takeOnnxDisabledNotice() is authoritative on its
    // own, and is true only on a device where ONNX ran and was disabled.
    test('The disabled note is available before the saved mode is restored', () async {
      SharedPreferences.setMockInitialValues({OnnxCrashGuard.kStrikes: 2});
      final fresh = TranslationProvider(
        null,
        FakeOCRService(),
        FakeTranslationService(),
        FakeOverlayService(),
        llmTranslationService: FakeLLMTranslationService(),
        onnxTranslationService: FakeOnnxTranslationService(),
      );

      expect(fresh.translationMode, isNot(TranslationMode.onnx),
          reason: 'the saved mode has not been restored yet');
      expect(await fresh.takeOnnxDisabledNotice(), isTrue);
      expect(await fresh.takeOnnxDisabledNotice(), isFalse, reason: 'shown once');
    });
  });
}
