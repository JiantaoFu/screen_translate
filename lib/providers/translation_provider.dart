import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:screen_translate/services/android_screen_capture_service.dart';
import 'package:screen_translate/services/ocr_service.dart';
import 'package:screen_translate/services/translation_service.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:flutter/material.dart';
import '../services/overlay_service.dart';
import 'package:flutter/services.dart';
import '../services/llm_translation_service.dart';
import '../models/ocr_result.dart';
import 'package:shared_preferences/shared_preferences.dart';

extension StringExtension on String {
  String capitalize() {
    return this[0].toUpperCase() + substring(1);
  }
}

enum TranslationMode {
  onDevice,
  llm
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
  final LLMTranslationService _llmTranslationService;
  BuildContext? _context;
  bool _isManualTranslationRequested = false;
  static const MethodChannel _translationServiceChannel = 
      MethodChannel('com.lomoware.screen_translate/translationService');
  TranslationMode _translationMode = TranslationMode.onDevice;
  bool _isProcessingCapture = false;
  List<OCRResult> _previousOcrResults = [];
  double _mergeAggressiveness = 1.5;

  bool _areOcrResultsIdentical(List<OCRResult> a, List<OCRResult> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].text != b[i].text) return false;
      
      // Allow a small tolerance of 12 physical pixels for screen coordinate noise
      final dx = (a[i].x - b[i].x).abs();
      final dy = (a[i].y - b[i].y).abs();
      final dw = (a[i].width - b[i].width).abs();
      final dh = (a[i].height - b[i].height).abs();
      
      if (dx > 12 || dy > 12 || dw > 12 || dh > 12) return false;
    }
    return true;
  }

  TranslationProvider(
    this._context,
    this._ocrService,
    this._translationService,
    this._overlayService, {
    LLMTranslationService? llmTranslationService,
  }) : _llmTranslationService = llmTranslationService ?? LLMTranslationService() {
    if (Platform.isAndroid) {
      _androidScreenCaptureService = AndroidScreenCaptureService();
      initTranslationServiceChannel();
    }
    _initPreferences();
  }

  bool get isTranslating => _isTranslating;
  String get lastTranslatedText => _lastTranslatedText;
  String get sourceLanguage => _sourceLanguage;
  String get targetLanguage => _targetLanguage;
  TranslationMode get translationMode => _translationMode;
  double get mergeAggressiveness => _mergeAggressiveness;

  Future<void> _initPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _mergeAggressiveness = prefs.getDouble('mergeAggressiveness') ?? 1.5;
    notifyListeners();
  }

  Future<void> setMergeAggressiveness(double value) async {
    _mergeAggressiveness = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('mergeAggressiveness', value);
    notifyListeners();
  }

  void setSourceLanguage(String language) {
    _sourceLanguage = language;
    notifyListeners();
  }

  void setTargetLanguage(String language) {
    _targetLanguage = language;
    notifyListeners();
  }

  void setTranslationMode(TranslationMode mode) {
    _translationMode = mode;
    notifyListeners();
  }

  Future<void> startTranslation() async {
    if (_isTranslating) return;

    if (Platform.isAndroid) {
      try {
        if (await _overlayService.ensureOverlayPermission(_context!)) {
          _isTranslating = true;
          notifyListeners();
          await _overlayService.start();
          await _startAndroidScreenCapture();
          _startPeriodicCapture();
        }
      } catch (e) {
        print('Error starting translation: $e');
        await stopTranslation();
      }
    }
  }

  void requestManualTranslation() {
    _isManualTranslationRequested = true;
  }

  void _startPeriodicCapture() async {
    if (_captureTimer != null) return;

    _captureTimer = Timer.periodic(const Duration(milliseconds: 500), (_) async {
      if (!_isTranslating) return;
      if (_isProcessingCapture) return; // Guard to prevent overlapping ticks

      _isProcessingCapture = true;

      try {
        // Check translation mode from Android service
        final translationMode = await _androidScreenCaptureService?.getTranslationMode();
        print('Timer: translationMode=$translationMode, isManualRequested=$_isManualTranslationRequested');
        
        // Skip only in "original" mode (shows untranslated screen)
        // In "auto" mode: always capture and translate
        // In "manual" mode: capture and translate when manual button pressed
        // In null/unknown mode: treat as auto
        final bool shouldProcess = (translationMode != 'manual' && translationMode != 'original') || _isManualTranslationRequested;
        if (shouldProcess) {
          if (Platform.isAndroid) {
            print('Timer: capturing screen...');
            final stopwatch = Stopwatch()..start();
            final imageData = await _androidScreenCaptureService?.captureScreen();
            final captureMs = stopwatch.elapsedMilliseconds;
            print('Timer: captureScreen returned ${imageData != null ? "data (${imageData['width']}x${imageData['height']})" : "null"} in ${captureMs}ms, isTranslating=$_isTranslating');
            if (imageData != null && _isTranslating) {
              print('Timer: running OCR...');
              stopwatch.reset();
              final ocrResults = await _ocrService.processImage(
                imageData,
                currentOCRScript,
                minTextLength: 1, // Ignore blocks that have only 1 character
                mergeAggressiveness: _mergeAggressiveness,
              );
              final ocrMs = stopwatch.elapsedMilliseconds;
              print('Timer: OCR found ${ocrResults.length} text blocks in ${ocrMs}ms');
              
              // Change Detection Check - but always honor manual translation requests
              if (!_isManualTranslationRequested && _areOcrResultsIdentical(ocrResults, _previousOcrResults)) {
                // Skip processing as screen is unchanged
                print('OCR: Screen unchanged (${ocrResults.length} blocks), skipping translation');
                return;
              }

              // Screen has changed (e.g., user is scrolling). Immediately hide old overlays so they don't stick to the text.
              if (!_isManualTranslationRequested) {
                _overlayService.hideTranslationOverlay();
                print('Overlay: Screen changed, immediately hiding old overlays');
              } else {
                // For manual translation, we clear here right before generating new ones
                _overlayService.hideTranslationOverlay();
              }

              // Translate blocks and render (Streaming for on-device to minimize perceived latency)
              print('Timer: translating ${ocrResults.length} blocks (mode=$_translationMode)...');
              final List<String> translatedTexts = [];
              stopwatch.reset();
              var translateMs = 0;
              var renderMs = 0;
              
              if (_translationMode == TranslationMode.llm) {
                final textsToTranslate = ocrResults.map((r) => r.text).toList();
                final batchResults = await _llmTranslationService.translateBatch(
                  texts: textsToTranslate,
                  sourceLanguage: _sourceLanguage,
                  targetLanguage: _targetLanguage,
                );
                translateMs = stopwatch.elapsedMilliseconds;
                
                if (!_isTranslating) {
                  print('Overlay: Translation stopped during translate phase, aborting');
                  return; // Guard if stopped
                }
                
                stopwatch.reset();
                for (var i = 0; i < ocrResults.length; i++) {
                  final ocrResult = ocrResults[i];
                  translatedTexts.add(batchResults[i]); // Keep history
                  if (Platform.isAndroid) {
                    await _overlayService.showTranslationOverlay(
                      batchResults[i], i,
                      x: ocrResult.x, y: ocrResult.y, width: ocrResult.width, height: ocrResult.height,
                      overlayColor: ocrResult.overlayColor, backgroundColor: ocrResult.backgroundColor, isLight: ocrResult.isLight, imgWidth: ocrResult.imgWidth, imgHeight: ocrResult.imgHeight,
                    );
                  }
                }
                renderMs = stopwatch.elapsedMilliseconds;
              } else {
                // Streaming mode for On-Device
                var tMs = 0;
                var rMs = 0;
                for (var i = 0; i < ocrResults.length; i++) {
                  if (!_isTranslating) break; // Guard if stopped
                  final ocrResult = ocrResults[i];
                  
                  final tWatch = Stopwatch()..start();
                  final translatedText = await translateText(ocrResult.text);
                  tMs += tWatch.elapsedMilliseconds;
                  translatedTexts.add(translatedText);
                  
                  final rWatch = Stopwatch()..start();
                  if (Platform.isAndroid) {
                    await _overlayService.showTranslationOverlay(
                      translatedText, i,
                      x: ocrResult.x, y: ocrResult.y, width: ocrResult.width, height: ocrResult.height,
                      overlayColor: ocrResult.overlayColor, backgroundColor: ocrResult.backgroundColor, isLight: ocrResult.isLight, imgWidth: ocrResult.imgWidth, imgHeight: ocrResult.imgHeight,
                    );
                  }
                  rMs += rWatch.elapsedMilliseconds;
                }
                translateMs = tMs;
                renderMs = rMs;
              }

              print('Overlay: Translations complete (${translatedTexts.length} blocks)');
              
              // -------------------------------------------------------------
              // SUMMARY METRICS
              // -------------------------------------------------------------
              final totalMs = captureMs + ocrMs + translateMs + renderMs;
              print('\n======================================================');
              print('[METRICS] Total Processing: ${totalMs}ms');
              print('[METRICS] -> Capture: ${captureMs}ms');
              print('[METRICS] -> OCR:     ${ocrMs}ms');
              print('[METRICS] -> Translate: ${translateMs}ms');
              print('[METRICS] -> Render:  ${renderMs}ms');
              print('======================================================\n');

              if (!_isManualTranslationRequested) {
                _previousOcrResults = ocrResults;
              }

              if (ocrResults.isNotEmpty) {
                _lastTranslatedText = ocrResults.map((r) => r.text).join('\n');
                notifyListeners();
              }
            } else {
              print('Timer: captureScreen returned null or not translating, skipping');
            }
          }

          // Reset manual translation flag after processing
          _isManualTranslationRequested = false;
        } else {
          print('Timer: skipping - mode=$translationMode, isManualRequested=$_isManualTranslationRequested');
        }
      } catch (e, stackTrace) {
        print('Error processing captured screen: $e');
        print('Stack trace: $stackTrace');
      } finally {
        _isProcessingCapture = false; // Always release guard
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
    _isProcessingCapture = false;
    _previousOcrResults = [];
    _captureTimer?.cancel();
    _captureTimer = null;
    if (Platform.isAndroid) {
      await _androidScreenCaptureService?.stopScreenCapture();
      await _overlayService.stop();
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

  Future<void> initTranslationServiceChannel() async {
    if (Platform.isAndroid) {
      try {
        _translationServiceChannel.setMethodCallHandler((MethodCall call) async {
          switch (call.method) {
            case 'requestManualTranslation':
              print("Manual translation requested"); // Add this debug print
              requestManualTranslation();
              break;
            case 'cancelTranslation':
              print("Translation cancelled due to scroll");
              cancelTranslation(_lastTranslatedText, _sourceLanguage, _targetLanguage);
              _translationService.cancelAllTranslations();
              _overlayService.hideTranslationOverlay();
              _previousOcrResults.clear();
              break;
            default:
              throw MissingPluginException();
          }
        });
      } catch (e) {
        print('Error setting up method channel: $e');
      }
    }
  }

  void cancelTranslation(String text, String sourceLanguage, String targetLanguage) {
    switch (_translationMode) {
      case TranslationMode.onDevice:
        _translationService.cancelTranslation(text, sourceLanguage, targetLanguage);
        break;
      case TranslationMode.llm:
        _llmTranslationService.cancelTranslation(text, sourceLanguage, targetLanguage);
        break;
    }
  }

  void cancelAllTranslations() {
    _translationService.cancelAllTranslations();
  }

  Future<String> translateText(String text) async {
    switch (_translationMode) {
      case TranslationMode.onDevice:
        return await _translationService.translateText(
          text: text, 
          sourceLanguage: _sourceLanguage, 
          targetLanguage: _targetLanguage
        );
      case TranslationMode.llm:
        return await _llmTranslationService.translateText(
          text: text, 
          sourceLanguage: _sourceLanguage, 
          targetLanguage: _targetLanguage
        );
    }
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