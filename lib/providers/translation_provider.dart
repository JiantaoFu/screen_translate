import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:screen_translate/services/android_screen_capture_service.dart';
import 'package:screen_translate/services/ocr_service.dart';
import 'package:screen_translate/services/translation_service.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import '../services/overlay_service.dart';

extension StringExtension on String {
  String capitalize() {
    return this[0].toUpperCase() + substring(1);
  }
}

class TranslationProvider with ChangeNotifier {
  bool _isTranslating = false;
  String _lastTranslatedText = '';
  String _sourceLanguage = 'en';
  String _targetLanguage = 'zh';
  AndroidScreenCaptureService? _androidScreenCaptureService;
  Timer? _captureTimer;
  final OCRService _ocrService;
  final TranslationService _translationService;
  final OverlayService _overlayService;

  TranslationProvider(
    this._ocrService,
    this._translationService,
    this._overlayService,
  ) {
    if (Platform.isAndroid) {
      _androidScreenCaptureService = AndroidScreenCaptureService();
    }
  }

  bool get isTranslating => _isTranslating;
  String get lastTranslatedText => _lastTranslatedText;
  String get sourceLanguage => _sourceLanguage;
  String get targetLanguage => _targetLanguage;

  void setSourceLanguage(String language) {
    _sourceLanguage = language;
    notifyListeners();
  }

  void setTargetLanguage(String language) {
    _targetLanguage = language;
    notifyListeners();
  }

  Future<void> startTranslation() async {
    if (_isTranslating) return;

    _isTranslating = true;
    notifyListeners();

    if (Platform.isAndroid) {
      try {
        await _startAndroidScreenCapture();
        _startPeriodicCapture();
      } catch (e) {
        print('Error starting translation: $e');
        await stopTranslation();
      }
    }
  }

  void _startPeriodicCapture() async {
    if (_captureTimer != null) return;

    _captureTimer = Timer.periodic(const Duration(milliseconds: 500), (_) async {
      if (!_isTranslating) return;

      if (Platform.isAndroid) {
        final imageData = await _androidScreenCaptureService?.captureScreen();
        if (imageData != null) {
            try {
              final ocrResults = await _ocrService.processImage(imageData, currentOCRScript);
              await _overlayService.hideTranslationOverlay(); // Clear old overlays
              
              for (var i = 0; i < ocrResults.length; i++) {
                final ocrResult = ocrResults[i];
                final translatedText = await _translationService.translateText(
                  text: ocrResult.text,
                  sourceLanguage: _sourceLanguage,
                  targetLanguage: _targetLanguage,
                );
                if (Platform.isAndroid) {
                  await _overlayService.showTranslationOverlay(
                    translatedText,
                    i,
                    x: ocrResult.x,
                    y: ocrResult.y,
                    width: ocrResult.width,
                    height: ocrResult.height,
                  );
                }
              }
              
              if (ocrResults.isNotEmpty) {
                _lastTranslatedText = ocrResults.map((r) => r.text).join('\n');
                notifyListeners();
              }
            } catch (e) {
              print('Error processing captured screen: $e');
            }
        }
      }
    });
  }

  Future<void> _startAndroidScreenCapture() async {
    if (_androidScreenCaptureService == null) {
      throw Exception('Android screen capture service not initialized');
    }
    await _androidScreenCaptureService?.requestScreenCapture();
  }

  Future<void> stopTranslation() async {
    _isTranslating = false;
    _captureTimer?.cancel();
    _captureTimer = null;
    if (Platform.isAndroid) {
      await _androidScreenCaptureService?.stopScreenCapture();
      await _overlayService.hideTranslationOverlay();
    }
    notifyListeners();
  }

  void setAndroidScreenCaptureService(AndroidScreenCaptureService service) {
    _androidScreenCaptureService = service;
  }

  void swapLanguages() {
    final temp = _sourceLanguage;
    _sourceLanguage = _targetLanguage;
    _targetLanguage = temp;
    print('Translation direction switched: $_sourceLanguage -> $_targetLanguage');
    notifyListeners();
  }

  bool get isChineseToEnglish => _sourceLanguage == 'zh' && _targetLanguage == 'en';

  TextRecognitionScript get currentOCRScript {
    return _ocrService.getScriptForLanguage(_sourceLanguage);
  }

  @override
  void dispose() {
    stopTranslation();
    _captureTimer?.cancel();
    _ocrService.dispose();
    super.dispose();
  }

  static Map<String, String> get supportedLanguages {
    return {
      for (var language in TranslateLanguage.values)
        language.bcpCode: language.toString().split('.').last.capitalize()
    };
  }
}