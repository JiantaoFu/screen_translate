import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:screen_translate/providers/translation_provider.dart';
import 'package:screen_translate/services/ocr_service.dart';

void main() {
  test('default source picks the matching OCR recognizer', () {
    final ocr = OCRService();
    for (final device in ['en', 'pt', 'th', 'zh', 'ko']) {
      final (source, _) = TranslationProvider.defaultLanguagePairFor(device);
      expect(source, 'ja');
      expect(ocr.getScriptForLanguage(source), TextRecognitionScript.japanese);
    }
    final (jaSource, _) = TranslationProvider.defaultLanguagePairFor('ja');
    expect(ocr.getScriptForLanguage(jaSource), TextRecognitionScript.latin);
  });
}
