import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:screen_translate/services/android_screen_capture_service.dart';
import 'package:screen_translate/services/ocr_service.dart';
import 'package:screen_translate/services/translation_service.dart';
import '../services/overlay_service.dart';

class TranslationProvider with ChangeNotifier {
  bool _isTranslating = false;
  String _lastTranslatedText = '';
  int? _lastImageHash;
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
          final currentHash = _computeFastImageHash(imageData['bytes']);
          if (currentHash != _lastImageHash) {
            print('Screen content changed, processing...');
            _lastImageHash = currentHash;
            try {
              final ocrResults = await _ocrService.processImage(imageData);
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
      }
    });
  }

  int _computeFastImageHash(List<int> bytes) {
    int hash = 0;
    // Take every 4th byte to reduce computation while maintaining good distribution
    for (int i = 0; i < bytes.length; i += 4) {
      hash = (hash * 31 + bytes[i]) & 0x7FFFFFFF;  // Keep it positive
    }
    return hash;
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

  void switchTranslationDirection() {
    final temp = _sourceLanguage;
    _sourceLanguage = _targetLanguage;
    _targetLanguage = temp;
    print('Translation direction switched: $_sourceLanguage -> $_targetLanguage');
    notifyListeners();
  }

  bool get isChineseToEnglish => _sourceLanguage == 'zh' && _targetLanguage == 'en';

  @override
  void dispose() {
    stopTranslation();
    _captureTimer?.cancel();
    _ocrService.dispose();
    super.dispose();
  }
}
