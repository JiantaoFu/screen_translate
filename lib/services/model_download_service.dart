import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:screen_translate/services/custom_model_manager.dart';

class ModelDownloadService {
  final OnDeviceTranslatorModelManager _googleModelManager;
  final CustomModelManager _customModelManager;

  ModelDownloadService()
      : _googleModelManager = OnDeviceTranslatorModelManager(),
        _customModelManager = CustomModelManager();

  /// Downloads a model with a fallback to a custom server.
  ///
  /// First, it tries to download from Google's servers. If that fails
  /// (e.g., due to network issues or service restrictions), it falls back
  /// to downloading from the custom server.
  Future<void> downloadModelWithFallback(String langCode) async {
    try {
      print('Attempting to download model for "$langCode" from Google...');
      // --- FOR TESTING FALLBACK ---
      // To test the fallback, we simulate a failure from the primary download.
      // This will force the catch block and your custom server logic to run.
      // throw Exception('Simulating Google download failure to test fallback.');
      await _googleModelManager.downloadModel(langCode, isWifiRequired: false);
      print('Model for "$langCode" downloaded successfully from Google.');
    } catch (e) {
      print('Failed to download from Google. Reason: $e');
      print('Initiating fallback to custom server...');

      try {
        await _customModelManager.downloadAndInstallModel(langCode);
        print('Model for "$langCode" downloaded successfully from custom server.');
        // Note: A restart might be needed for ML Kit to recognize the manually placed model.
      } catch (fallbackError) {
        print('Fallback download also failed. Reason: $fallbackError');
        // Both primary and fallback failed. Rethrow the original error or a custom one.
        throw Exception('Failed to download model for "$langCode" from both Google and custom server.');
      }
    }
  }

  Future<bool> isModelDownloaded(String langCode) {
    return _googleModelManager.isModelDownloaded(langCode);
  }

  Future<bool> deleteModel(String langCode) {
    return _googleModelManager.deleteModel(langCode);
  }
}
