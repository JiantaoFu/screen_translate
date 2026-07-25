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
import '../services/onnx_translation_service.dart';
import '../models/ocr_result.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/firebase_analytics_service.dart';

extension StringExtension on String {
  String capitalize() {
    return this[0].toUpperCase() + substring(1);
  }
}

enum TranslationMode {
  /// Google ML Kit on-device translation (always available, fallback)
  onDevice,
  /// Helsinki-NLP OPUS-MT ONNX local inference (higher quality, requires download)
  onnx,
  /// Online LLM translation via BigModel API
  llm,
}

class TranslationProvider with ChangeNotifier {
  bool _isTranslating = false;
  int _translationToken = 0; // Bumped each capture cycle to detect stale results
  String _lastTranslatedText = '';
  String _sourceLanguage = 'en';
  String _targetLanguage = 'zh';
  AndroidScreenCaptureService? _androidScreenCaptureService;
  Timer? _captureTimer;
  final OCRService _ocrService;
  final TranslationService _translationService;
  final OverlayService _overlayService;
  final LLMTranslationService _llmTranslationService;
  final OnnxTranslationService _onnxTranslationService;
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
    OnnxTranslationService? onnxTranslationService,
  })  : _llmTranslationService = llmTranslationService ?? LLMTranslationService(),
        _onnxTranslationService = onnxTranslationService ?? OnnxTranslationService() {
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
          
          FirebaseAnalyticsService().trackTranslation(
            sourceLanguage: _sourceLanguage,
            targetLanguage: _targetLanguage,
            translationType: 'screen_${_translationMode.name}',
          );
          
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
    FirebaseAnalyticsService().trackTranslation(
      sourceLanguage: _sourceLanguage,
      targetLanguage: _targetLanguage,
      translationType: 'manual_screen_${_translationMode.name}',
    );
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

              // Bump token so any in-flight translation from a previous cycle becomes stale
              final myToken = ++_translationToken;

              // ── Show "Translating..." placeholders immediately ───────────────────
              // Only for ONNX/LLM which can take noticeable time; on-device is instant.
              if (_translationMode == TranslationMode.onnx || _translationMode == TranslationMode.llm) {
                for (var i = 0; i < ocrResults.length; i++) {
                  final r = ocrResults[i];
                  if (Platform.isAndroid) {
                    await _overlayService.showTranslationOverlay(
                      '…', i,
                      x: r.x, y: r.y, width: r.width, height: r.height,
                      overlayColor: r.overlayColor, backgroundColor: r.backgroundColor,
                      isLight: r.isLight, imgWidth: r.imgWidth, imgHeight: r.imgHeight,
                    );
                  }
                }
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
                
                // Stale check: if the user has scrolled/changed page, discard results
                if (!_isTranslating || myToken != _translationToken) {
                  print('Overlay: Translation stale or stopped (token mismatch), aborting');
                  if (Platform.isAndroid) await _overlayService.hideTranslationOverlay();
                  return;
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
                // Streaming mode for On-Device / ONNX (one block at a time)
                var tMs = 0;
                var rMs = 0;
                for (var i = 0; i < ocrResults.length; i++) {
                  // Stale check on each block: abort if user has navigated away
                  if (!_isTranslating || myToken != _translationToken) {
                    print('Overlay: Translation stale at block $i (token mismatch), aborting');
                    if (Platform.isAndroid) await _overlayService.hideTranslationOverlay();
                    return;
                  }
                  final ocrResult = ocrResults[i];
                  
                  final tWatch = Stopwatch()..start();
                  final translatedText = await translateText(ocrResult.text);
                  tMs += tWatch.elapsedMilliseconds;
                  translatedTexts.add(translatedText);
                  
                  // Stale check again after the (potentially slow) translation call
                  if (myToken != _translationToken) {
                    print('Overlay: Translation stale after block $i, discarding');
                    if (Platform.isAndroid) await _overlayService.hideTranslationOverlay();
                    return;
                  }

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

              FirebaseAnalyticsService().trackPerformance(
                captureMs: captureMs,
                ocrMs: ocrMs,
                translateMs: translateMs,
                renderMs: renderMs,
                totalMs: totalMs,
                translationType: _translationMode.name,
              );

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
      case TranslationMode.onnx:
        // ONNX runs in an Isolate; cancellation is handled by Isolate lifecycle.
        // No additional action required here.
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
          targetLanguage: _targetLanguage,
        );

      case TranslationMode.onnx:
        try {
          return await _onnxTranslationService.translateText(
            text: text,
            sourceLanguage: _sourceLanguage,
            targetLanguage: _targetLanguage,
          );
        } on OnnxModelNotReadyException catch (e) {
          // Model not downloaded yet — fall back to Google ML Kit silently.
          debugPrint('OnnxTranslation: ${e.langPairKey} not ready, falling back to ML Kit');
          return await _translationService.translateText(
            text: text,
            sourceLanguage: _sourceLanguage,
            targetLanguage: _targetLanguage,
          );
        } on UnsupportedError catch (_) {
          // Language pair not supported by ONNX — fall back to ML Kit.
          return await _translationService.translateText(
            text: text,
            sourceLanguage: _sourceLanguage,
            targetLanguage: _targetLanguage,
          );
        }

      case TranslationMode.llm:
        return await _llmTranslationService.translateText(
          text: text,
          sourceLanguage: _sourceLanguage,
          targetLanguage: _targetLanguage,
        );
    }
  }

  Future<List<String>> translateBatch(List<String> texts) async {
    if (texts.isEmpty) return [];
    if (_translationMode == TranslationMode.llm) {
      return await _llmTranslationService.translateBatch(
        texts: texts,
        sourceLanguage: _sourceLanguage,
        targetLanguage: _targetLanguage,
      );
    }
    // For ONNX and MLKit native sessions, run sequentially to avoid platform channel & JNI deadlocks
    final results = <String>[];
    for (final text in texts) {
      results.add(await translateText(text));
    }
    return results;
  }

  @override
  void dispose() {
    stopTranslation();
    _captureTimer?.cancel();
    _ocrService.dispose();
    _onnxTranslationService.dispose();
    super.dispose();
  }

  static Map<String, String> get supportedLanguages {
    return {
      for (var language in TranslateLanguage.values)
        language.bcpCode: language.toString().split('.').last.capitalize()
    };
  }
}
