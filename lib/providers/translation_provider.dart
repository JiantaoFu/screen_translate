import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:screen_translate/services/android_screen_capture_service.dart';
import 'package:screen_translate/services/ocr_service.dart';
import '../services/translation_service.dart';

class TranslationProvider with ChangeNotifier {
  bool _isTranslating = false;
  String _lastTranslatedText = '';
  String _sourceLanguage = 'en';
  String _targetLanguage = 'zh';
  AndroidScreenCaptureService? _androidScreenCaptureService;
  Timer? _captureTimer;
  final OCRService _ocrService = OCRService();
  final TranslationService _translationService = TranslationService();
  final BuildContext context;

  TranslationProvider({required this.context}) {
    if (Platform.isAndroid) {
      _androidScreenCaptureService = AndroidScreenCaptureService();
    }
  }

  bool get isTranslating => _isTranslating;
  String get lastTranslatedText => _lastTranslatedText;
  String get sourceLanguage => _sourceLanguage;
  String get targetLanguage => _targetLanguage;

  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      if (needsOverlayPermission) {
        final alertWindowStatus = await Permission.systemAlertWindow.request();
        return alertWindowStatus.isGranted;
      }
      return true;
    } else if (Platform.isIOS) {
      return true;
    }
    return false;
  }

  bool get needsOverlayPermission => false;

  Future<void> startTranslation() async {
    if (_isTranslating) return;

    final hasPermission = await requestPermissions();
    if (!hasPermission) {
      throw Exception('Required permissions were denied');
    }

    try {
      if (Platform.isAndroid) {
        await _startAndroidScreenCapture();
      } else if (Platform.isIOS) {
        await _startIOSScreenCapture();
      } else {
        throw Exception('Platform not supported');
      }

      _isTranslating = true;
      notifyListeners();

      _startPeriodicCapture();
    } catch (e) {
      throw Exception('Failed to start screen capture: $e');
    }
  }

  void _startPeriodicCapture() {
    _captureTimer?.cancel();
    _captureTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!_isTranslating) {
        timer.cancel();
        return;
      }

      if (Platform.isAndroid) {
        final imageData = await _androidScreenCaptureService?.captureScreen();
        if (imageData != null) {
          print('Screen captured, size: ${imageData['bytes'].length} bytes');
          try {
            final recognizedText = await _ocrService.processImage(imageData);
            if (recognizedText.isNotEmpty) {
              print('Text recognized, translating...');
              final translatedText = await _translationService.translateText(
                text: recognizedText,
                sourceLanguage: _sourceLanguage,
                targetLanguage: _targetLanguage,
              );
              _lastTranslatedText = translatedText;
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

    final success = await _androidScreenCaptureService!.requestScreenCapture();
    if (!success) {
      throw Exception('Failed to start Android screen capture');
    }
  }

  Future<void> _startIOSScreenCapture() async {
    // TODO: Implement iOS screen capture
  }

  void stopTranslation() {
    if (!_isTranslating) return;
    
    _captureTimer?.cancel();
    _captureTimer = null;

    if (Platform.isAndroid) {
      _androidScreenCaptureService?.stopScreenCapture();
    }

    _isTranslating = false;
    notifyListeners();
  }

  void setLanguages(String source, String target) {
    _sourceLanguage = source;
    _targetLanguage = target;
    notifyListeners();
  }

  void switchTranslationDirection() {
    final temp = _sourceLanguage;
    _sourceLanguage = _targetLanguage;
    _targetLanguage = temp;
    print('Translation direction switched: ${_sourceLanguage} -> ${_targetLanguage}');
    notifyListeners();
  }

  bool get isChineseToEnglish => _sourceLanguage == 'zh' && _targetLanguage == 'en';

  @override
  void dispose() {
    stopTranslation();
    _captureTimer?.cancel();
    _ocrService.dispose();
    _translationService.dispose();
    super.dispose();
  }
}
