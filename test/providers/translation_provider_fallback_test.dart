import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:screen_translate/providers/translation_provider.dart';
import 'package:screen_translate/services/translation_service.dart';
import 'package:screen_translate/services/onnx_translation_service.dart';
import 'package:screen_translate/services/ocr_service.dart';
import 'package:screen_translate/services/overlay_service.dart';
import 'package:screen_translate/services/llm_translation_service.dart';
// Import removed

// Generate mocks using build_runner or just write simple mock classes.
// For simplicity and avoiding build_runner execution, we'll write manual mocks.

class MockTranslationService extends Fake implements TranslationService {
  int callCount = 0;
  @override
  Future<String> translateText({
    required String text,
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    callCount++;
    return 'ML Kit translated: $text';
  }
}

class MockOnnxTranslationService extends Fake implements OnnxTranslationService {
  int callCount = 0;
  bool shouldThrowNotReady = false;
  bool shouldThrowUnsupported = false;

  @override
  Future<String> translateText({
    required String text,
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    callCount++;
    if (shouldThrowNotReady) {
      throw OnnxModelNotReadyException('opus-mt-en-zh');
    }
    if (shouldThrowUnsupported) {
      throw UnsupportedError('Not supported');
    }
    return 'ONNX translated: $text';
  }

  @override
  Future<void> dispose() async {}
}

class MockOCRService extends Fake implements OCRService {
  @override
  void dispose() {}
}

class MockOverlayService extends Fake implements OverlayService {}
class MockLLMTranslationService extends Fake implements LLMTranslationService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('TranslationProvider ONNX Fallback Logic', () {
    late TranslationProvider provider;
    late MockTranslationService mockMlKit;
    late MockOnnxTranslationService mockOnnx;

    setUp(() {
      mockMlKit = MockTranslationService();
      mockOnnx = MockOnnxTranslationService();
      
      provider = TranslationProvider(
        null,
        MockOCRService(),
        mockMlKit,
        MockOverlayService(),
        llmTranslationService: MockLLMTranslationService(),
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
