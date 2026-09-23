import 'package:flutter_test/flutter_test.dart';
import 'package:screen_translate/services/llm_translation_service.dart';
import 'package:screen_translate/services/ocr_service.dart';
import 'package:screen_translate/services/onnx_translation_service.dart';
import 'package:screen_translate/services/overlay_service.dart';
import 'package:screen_translate/services/translation_service.dart';

// Hand-written fakes (no build_runner): only the members the provider
// actually touches in these tests are implemented; anything else throws
// UnimplementedError from Fake, which surfaces unexpected calls.

class FakeTranslationService extends Fake implements TranslationService {
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

class FakeOnnxTranslationService extends Fake implements OnnxTranslationService {
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
      throw const OnnxModelNotReadyException('opus-mt-en-zh');
    }
    if (shouldThrowUnsupported) {
      throw UnsupportedError('Not supported');
    }
    return 'ONNX translated: $text';
  }

  @override
  Future<void> dispose() async {}
}

class FakeLLMTranslationService extends Fake implements LLMTranslationService {
  @override
  void dispose() {}
}

class FakeOCRService extends Fake implements OCRService {
  @override
  void dispose() {}
}

class FakeOverlayService extends Fake implements OverlayService {}
