import 'package:flutter_test/flutter_test.dart';
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
  });
}
