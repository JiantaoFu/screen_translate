import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'dart:async';

class TranslationService {
  OnDeviceTranslator? _translator;
  late final modelManager = OnDeviceTranslatorModelManager();
  
  // Support multiple ongoing translations
  final _translations = <String, Future<String>>{};
  final _translationCompleters = <String, Completer<String>>{};

  TranslateLanguage _getTranslateLanguage(String code) {
    TranslateLanguage? language = BCP47Code.fromRawValue(code);
    if (language == null) {
      throw ArgumentError('Unsupported language code: $code');
    }
    return language;
  }

  String _getLanguageCode(TranslateLanguage language) {
    return language.bcpCode;
  }

  Future<String> translateText({
    required String text,
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    // Generate a unique key for this translation task
    final taskKey = _generateTaskKey(text, sourceLanguage, targetLanguage);

    // Create a completer for this translation
    final completer = Completer<String>();
    _translationCompleters[taskKey] = completer;

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

      // Start the translation
      final translationFuture = _translator!.translateText(text).then((translatedText) {
        print('Translation: Translated text: $translatedText');
        completer.complete(translatedText);
        _translations.remove(taskKey);
        _translationCompleters.remove(taskKey);
        return translatedText;
      }).catchError((error) {
        print('Translation Error: $error');
        completer.completeError(error);
        _translations.remove(taskKey);
        _translationCompleters.remove(taskKey);
        return text;
      });

      // Store the translation future
      _translations[taskKey] = translationFuture;

      return await completer.future;
    } catch (e) {
      print('Translation Error: $e');
      completer.complete(text);
      _translations.remove(taskKey);
      _translationCompleters.remove(taskKey);
      return text;
    }
  }

  // Generate a unique key for translation tasks
  String _generateTaskKey(String text, String sourceLanguage, String targetLanguage) {
    return '$text|$sourceLanguage|$targetLanguage|${DateTime.now().millisecondsSinceEpoch}';
  }

  // Method to cancel a specific translation task
  Future<void> cancelTranslation(String text, String sourceLanguage, String targetLanguage) async {
    final taskKey = _translations.keys.firstWhere(
      (key) => key.startsWith('$text|$sourceLanguage|$targetLanguage'),
      orElse: () => '',
    );

    if (taskKey.isNotEmpty) {
      final completer = _translationCompleters[taskKey];
      if (completer != null && !completer.isCompleted) {
        print('Translation: Attempting to cancel specific translation task');
        
        // Close the current translator to interrupt any ongoing translation
        _translator?.close();
        _translator = null;

        // Complete the completer with the original text to signal cancellation
        completer.complete(text);
        
        // Remove the task from tracking
        _translations.remove(taskKey);
        _translationCompleters.remove(taskKey);
      }
    }
  }

  // Method to cancel all ongoing translations
  Future<void> cancelAllTranslations() async {
    print('Translation: Cancelling all ongoing translations');
    final keys = List<String>.from(_translations.keys);
    for (final key in keys) {
      final completer = _translationCompleters[key];
      if (completer != null && !completer.isCompleted) {
        completer.complete('');
      }
    }
    // Close the current translator to interrupt any ongoing translation
    _translator?.close();
    _translator = null;
    _translations.clear();
    _translationCompleters.clear();
  }

  // Get current number of ongoing translations
  int get ongoingTranslationsCount => _translations.length;

  // Cleanup method to close resources
  void dispose() {
    cancelAllTranslations();
    _translator?.close();
  }
}
