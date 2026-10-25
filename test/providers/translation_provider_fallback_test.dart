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

    test(
        'Falls back to ML Kit silently when ONNX throws OnnxModelNotReadyException',
        () async {
      provider.setTranslationMode(TranslationMode.onnx);
      mockOnnx.shouldThrowNotReady = true;

      final result = await provider.translateText('Hello');

      expect(result, 'ML Kit translated: Hello');
      expect(mockOnnx.callCount, 1);
      expect(mockMlKit.callCount, 1);
    });

    test(
        'Falls back to ML Kit silently when ONNX throws UnsupportedError (unsupported pair)',
        () async {
      provider.setTranslationMode(TranslationMode.onnx);
      mockOnnx.shouldThrowUnsupported = true;

      final result = await provider.translateText('Hello');

      expect(result, 'ML Kit translated: Hello');
      expect(mockOnnx.callCount, 1);
      expect(mockMlKit.callCount, 1);
    });

    test(
        'Falls back to ML Kit when ONNX throws anything else (PlatformException)',
        () async {
      provider.setTranslationMode(TranslationMode.onnx);
      mockOnnx.throwError =
          PlatformException(code: 'INFERENCE_ERROR', message: 'boom');

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
      mockOnnx.throwError =
          const OnnxUnavailableException('crash_marker_disabled');
      await provider.translateText('c');
      await provider.translateText('d');
      expect(provider.debugOnnxSkips,
          ['error_fallback', 'error_fallback', 'crash_marker_disabled']);
    });

    test('Service downgrade callback is wired to the provider log', () async {
      mockOnnx.onSkipped!('crash_marker_cpu');
      expect(provider.debugOnnxSkips, ['crash_marker_cpu']);
    });

    test('Stops calling ONNX for the session after repeated failures',
        () async {
      provider.setTranslationMode(TranslationMode.onnx);
      mockOnnx.throwError = StateError('ort');

      for (var i = 0;
          i < TranslationProvider.kMaxOnnxFailuresPerSession + 2;
          i++) {
        expect(await provider.translateText('Hi'), 'ML Kit translated: Hi');
      }
      expect(
          mockOnnx.callCount, TranslationProvider.kMaxOnnxFailuresPerSession);
    });

    test('Falls back to ML Kit when ONNX is unavailable on the device',
        () async {
      provider.setTranslationMode(TranslationMode.onnx);
      mockOnnx.throwError = const OnnxUnavailableException('low_memory');

      expect(await provider.translateText('Hello'), 'ML Kit translated: Hello');
      expect(provider.onnxUnavailable, isTrue);
      expect(provider.sessionOnnxFailures, 0);
      expect(provider.debugOnnxSkips, ['low_memory']);
    });
  });
}
