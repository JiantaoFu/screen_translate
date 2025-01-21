import 'package:google_mlkit_translation/google_mlkit_translation.dart';

class TranslationService {
  OnDeviceTranslator? _translator;
  late final modelManager = OnDeviceTranslatorModelManager();

  TranslateLanguage _getTranslateLanguage(String code) {
    TranslateLanguage? language = BCP47Code.fromRawValue(code);
    if (language != null) {
      return language!;
    } else {
      throw Exception('Unsupported language code: $code');
    }
  }

  String _getLanguageCode(TranslateLanguage language) {
    return language.bcpCode;
  }

  Future<String> translateText({
    required String text,
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    try {
      print('Translation: Starting translation from $sourceLanguage to $targetLanguage');
      print('Translation: Original text: $text');

      final sourceLang = _getTranslateLanguage(sourceLanguage);
      final targetLang = _getTranslateLanguage(targetLanguage);

      // Download language model if needed
      final targetCode = _getLanguageCode(targetLang);
      final isModelDownloaded = await modelManager.isModelDownloaded(targetCode);
      if (!isModelDownloaded) {
        print('Translation: Downloading language model for $targetCode');
        await modelManager.downloadModel(targetCode);
        print('Translation: Language model downloaded successfully');
      }

      // Create or update translator if needed
      if (_translator == null || 
          _translator!.sourceLanguage != sourceLang || 
          _translator!.targetLanguage != targetLang) {
        _translator?.close();
        _translator = OnDeviceTranslator(
          sourceLanguage: sourceLang,
          targetLanguage: targetLang,
        );
      }

      final translatedText = await _translator!.translateText(text);
      print('Translation: Translated text: $translatedText');
      return translatedText;
    } catch (e) {
      print('Translation Error: $e');
      return text; // Return original text on error
    }
  }

  void dispose() {
    _translator?.close();
  }
}
