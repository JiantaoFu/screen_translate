import 'dart:async';
import 'dart:io';
import 'dart:math';
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

/// A translated box currently shown on screen, tracked by a stable id that
/// survives across capture ticks (unlike its position in the OCR results
/// list, which shifts whenever a box is added/removed elsewhere on screen).
class _DisplayedOverlay {
  final OCRResult ocrResult;
  final String translatedText;
  // Where the native window was actually drawn (padded/de-overlapped
  // screen rect). Kept separately from ocrResult because ocrResult is
  // refreshed every tick for matching, while the window only moves when we
  // explicitly re-show it.
  final Rect drawnRect;
  _DisplayedOverlay(this.ocrResult, this.translatedText, this.drawnRect);
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
  final Map<int, _DisplayedOverlay> _displayedOverlays = {};
  int _nextOverlayId = 0;
  double _mergeAggressiveness = 1.5;

  // Same box, allowing a small tolerance of 12 physical pixels for screen
  // coordinate noise between ticks.
  bool _sameBox(OCRResult a, OCRResult b) {
    if (a.text != b.text) return false;
    final dx = (a.x - b.x).abs();
    final dy = (a.y - b.y).abs();
    final dw = (a.width - b.width).abs();
    final dh = (a.height - b.height).abs();
    return dx <= 12 && dy <= 12 && dw <= 12 && dh <= 12;
  }

  // A drawn box has drifted far enough from where its text now is that it
  // should be re-shown at the new position.
  bool _rectMoved(Rect a, Rect b) {
    return (a.left - b.left).abs() > 3 ||
        (a.top - b.top).abs() > 3 ||
        (a.width - b.width).abs() > 3 ||
        (a.height - b.height).abs() > 3;
  }

  // Cleans up "…" placeholders (onnx/llm modes) that were shown but never
  // replaced by a real translation (stale-token abort or an exception
  // mid-cycle) — without this they'd never be hidden or reused since Dart
  // has no record of them.
  Future<void> _hidePlaceholders(Iterable<int> ids) async {
    if (!Platform.isAndroid) return;
    for (final id in ids) {
      await _overlayService.hideTranslationOverlayById(id);
    }
  }

  /// Pad each box slightly and push down anything still overlapping a
  /// neighbor, mirroring image_translation_screen.dart's overlay layout —
  /// the live overlay renders each box as an independent native floating
  /// window with no shared parent to catch collisions, so without this any
  /// two OCR boxes left close together by the merge step render as
  /// literally overlapping translucent rectangles.
  @visibleForTesting
  List<Rect> computeDisplayBoxesForTest(List<OCRResult> results) => _computeDisplayBoxes(results);

  List<Rect> _computeDisplayBoxes(List<OCRResult> results) {
    final baseBoxes = results.map((r) => Rect.fromLTWH(r.x, r.y, r.width, r.height)).toList();

    final paddedBoxes = <Rect>[];
    for (int i = 0; i < results.length; i++) {
      final result = results[i];
      final base = baseBoxes[i];
      final desiredPad = result.height * 0.15;

      double padTop = desiredPad;
      double padBottom = desiredPad;
      double padLeft = desiredPad;
      double padRight = desiredPad;
      for (int j = 0; j < baseBoxes.length; j++) {
        if (j == i) continue;
        final other = baseBoxes[j];
        final horizontalOverlap = base.left < other.right && base.right > other.left;
        final verticalOverlap = base.top < other.bottom && base.bottom > other.top;
        if (horizontalOverlap) {
          if (other.bottom <= base.top) {
            padTop = min(padTop, max(0.0, (base.top - other.bottom) / 2));
          } else if (other.top >= base.bottom) {
            padBottom = min(padBottom, max(0.0, (other.top - base.bottom) / 2));
          }
        } else if (verticalOverlap) {
          // Same-row neighbor (adjacent tabs/buttons): cap the side padding
          // at half the gap, otherwise both boxes grow into each other and
          // _resolveOverlaps pushes one a full box height down, exposing
          // its original text and covering whatever is below.
          if (other.right <= base.left) {
            padLeft = min(padLeft, max(0.0, (base.left - other.right) / 2));
          } else if (other.left >= base.right) {
            padRight = min(padRight, max(0.0, (other.left - base.right) / 2));
          }
        }
      }

      paddedBoxes.add(Rect.fromLTWH(
        base.left - padLeft, base.top - padTop,
        base.width + padLeft + padRight, base.height + padTop + padBottom,
      ));
    }

    return _resolveOverlaps(paddedBoxes);
  }

  /// Pushes boxes down (reading order) just enough that none of them
  /// overlaps a box above/left of it that shares horizontal space.
  List<Rect> _resolveOverlaps(List<Rect> boxes) {
    final order = List<int>.generate(boxes.length, (i) => i)
      ..sort((a, b) {
        final byTop = boxes[a].top.compareTo(boxes[b].top);
        if (byTop != 0) return byTop;
        return boxes[a].left.compareTo(boxes[b].left);
      });

    final result = List<Rect>.from(boxes);
    final finalized = <int>[];

    for (final i in order) {
      var box = result[i];
      double minTop = box.top;
      for (final j in finalized) {
        final other = result[j];
        final horizontalOverlap = box.left < other.right && box.right > other.left;
        if (horizontalOverlap) {
          minTop = max(minTop, other.bottom);
        }
      }
      if (minTop != box.top) {
        box = Rect.fromLTWH(box.left, minTop, box.width, box.height);
        result[i] = box;
      }
      finalized.add(i);
    }

    return result;
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
    debugPrint('LangPicker: setSourceLanguage($language) — was $_sourceLanguage, notifying...');
    _sourceLanguage = language;
    notifyListeners();
  }

  void setTargetLanguage(String language) {
    debugPrint('LangPicker: setTargetLanguage($language) — was $_targetLanguage, notifying...');
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
          // Request MediaProjection consent BEFORE showing the floating
          // control overlay. If the user backs out of (or denies) that
          // system dialog, requestScreenCapture() returns false here and we
          // bail without ever starting the overlay — previously the overlay
          // was started first, so a denied/cancelled consent dialog left a
          // floating button on screen with no active capture behind it.
          final captureGranted = await _startAndroidScreenCapture();
          if (!captureGranted) {
            print('Screen capture permission denied or cancelled, not starting translation');
            return;
          }

          _isTranslating = true;

          FirebaseAnalyticsService().trackTranslation(
            sourceLanguage: _sourceLanguage,
            targetLanguage: _targetLanguage,
            translationType: 'screen_${_translationMode.name}',
          );

          notifyListeners();
          await _overlayService.start();
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

      // Snapshot before capturing: if a cancelTranslation (scroll, window or
      // frame change) lands while this tick is capturing/OCRing, the frame
      // it's working on no longer matches the screen.
      final tickToken = _translationToken;
      // "…" placeholder ids shown this tick that haven't been replaced by a
      // real translation yet. Whatever is left when the tick ends — stale
      // abort or an unexpected exception — gets hidden in `finally`, since
      // Dart has no other record of them.
      final pendingPlaceholders = <int>{};
      // Set when this tick abandons its frame because a cancel arrived
      // mid-cycle. On a static screen no further frame would ever be
      // queued, so `finally` asks native for a fresh one.
      var droppedStale = false;

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

              // Pad and de-overlap boxes before handing them to the native
              // overlay — each box here becomes its own independent floating
              // window with no shared parent to catch collisions, unlike the
              // static "Translate Image" screen's Stack. Without this, any
              // two OCR boxes left close together by the merge step (e.g. a
              // caption nested near a paragraph's edge) render as literally
              // overlapping translucent rectangles. Computed for the full
              // list (cheap, pure layout math) so de-overlap still accounts
              // for boxes we're not re-translating this tick, and so matched
              // boxes can be checked for drift below.
              final displayBoxes = _computeDisplayBoxes(ocrResults);

              // ── Match against currently-displayed overlays ──────────────
              // Each box gets a STABLE id that survives across ticks (unlike
              // its position in this cycle's list, which shifts whenever a
              // box is added/removed elsewhere on screen). Boxes whose text
              // and position are unchanged are left alone entirely — no
              // hide, no re-translate, no re-show. This matters most for
              // game/app UIs where most of the screen (HUD, menu labels) is
              // static and only one region (a dialogue box) actually
              // changes: previously ANY change anywhere on screen hid EVERY
              // overlay and retranslated EVERY block every 500ms tick,
              // causing visible flicker and, for cloud/LLM mode, repeated
              // paid API calls for text that hadn't changed at all.
              final matchedIdForIndex = <int, int>{};
              if (!_isManualTranslationRequested) {
                final remainingOldIds = _displayedOverlays.keys.toList();
                for (var i = 0; i < ocrResults.length; i++) {
                  final newResult = ocrResults[i];
                  for (final oldId in remainingOldIds) {
                    if (_sameBox(_displayedOverlays[oldId]!.ocrResult, newResult)) {
                      matchedIdForIndex[i] = oldId;
                      remainingOldIds.remove(oldId);
                      break;
                    }
                  }
                }

                // Matched boxes whose text has drifted (slow scroll/pan still
                // within _sameBox tolerance each tick) away from where their
                // window was drawn — those windows need to follow it.
                final anyMoved = matchedIdForIndex.entries.any((e) =>
                    _rectMoved(_displayedOverlays[e.value]!.drawnRect, displayBoxes[e.key]));

                // Nothing changed at all: same boxes, same text, same place,
                // nothing added or removed — skip this tick entirely.
                if (remainingOldIds.isEmpty &&
                    !anyMoved &&
                    matchedIdForIndex.length == ocrResults.length &&
                    matchedIdForIndex.length == _displayedOverlays.length) {
                  print('OCR: Screen unchanged (${ocrResults.length} blocks), skipping translation');
                  return;
                }

                // Boxes that were shown before but aren't on screen anymore.
                for (final goneId in remainingOldIds) {
                  if (Platform.isAndroid) await _overlayService.hideTranslationOverlayById(goneId);
                  _displayedOverlays.remove(goneId);
                }
              } else {
                // Manual translation always does a full rebuild — the user
                // explicitly asked for a fresh pass, and auto-capture may
                // have been paused (mode=manual/original) for a while, so
                // the previous overlay state can't be trusted.
                if (Platform.isAndroid) await _overlayService.hideTranslationOverlay();
                _displayedOverlays.clear();
              }

              final newIndices = [
                for (var i = 0; i < ocrResults.length; i++)
                  if (!matchedIdForIndex.containsKey(i)) i
              ];

              // A cancelTranslation that arrived during capture/OCR or the
              // awaits above has already hidden every overlay natively and
              // cleared _displayedOverlays, so this frame is stale. Carrying
              // on would draw it anyway — and with translation services
              // cancelled, as untranslated originals that later ticks then
              // match by text/position and never re-translate.
              if (!_isTranslating || tickToken != _translationToken) {
                print('Overlay: Cancelled during capture/OCR, dropping frame');
                droppedStale = true;
                return;
              }

              // Bump token so any in-flight translation from a previous cycle becomes stale
              final myToken = ++_translationToken;

              // Matched boxes keep their cached translation. Refresh the
              // stored OCR position for next tick's matching, and move the
              // window only if it has drifted from where it was drawn.
              for (final e in matchedIdForIndex.entries) {
                final i = e.key;
                final id = e.value;
                final old = _displayedOverlays[id];
                if (old == null || myToken != _translationToken) {
                  droppedStale = true;
                  return;
                }
                var drawn = old.drawnRect;
                if (_rectMoved(drawn, displayBoxes[i])) {
                  drawn = displayBoxes[i];
                  final r = ocrResults[i];
                  if (Platform.isAndroid) {
                    await _overlayService.showTranslationOverlay(
                      old.translatedText, id,
                      x: drawn.left, y: drawn.top, width: drawn.width, height: drawn.height,
                      overlayColor: r.overlayColor, backgroundColor: r.backgroundColor,
                      isLight: r.isLight, imgWidth: r.imgWidth, imgHeight: r.imgHeight,
                    );
                  }
                }
                _displayedOverlays[id] = _DisplayedOverlay(ocrResults[i], old.translatedText, drawn);
              }

              final idForIndex = <int, int>{
                for (final i in newIndices) i: _nextOverlayId++,
              };

              // ── Show "Translating..." placeholders immediately ───────────────────
              // Only for ONNX/LLM which can take noticeable time; on-device is instant.
              // Only for new/changed boxes — untouched ones keep showing their
              // existing translation instead of flashing to a placeholder.
              if (_translationMode == TranslationMode.onnx || _translationMode == TranslationMode.llm) {
                for (final i in newIndices) {
                  final r = ocrResults[i];
                  final box = displayBoxes[i];
                  if (Platform.isAndroid) {
                    pendingPlaceholders.add(idForIndex[i]!);
                    await _overlayService.showTranslationOverlay(
                      '…', idForIndex[i]!,
                      x: box.left, y: box.top, width: box.width, height: box.height,
                      overlayColor: r.overlayColor, backgroundColor: r.backgroundColor,
                      isLight: r.isLight, imgWidth: r.imgWidth, imgHeight: r.imgHeight,
                    );
                  }
                }
              }

              // Translate only the new/changed blocks and render (Streaming for on-device to minimize perceived latency)
              print('Timer: translating ${newIndices.length} new/changed of ${ocrResults.length} total blocks (mode=$_translationMode)...');
              stopwatch.reset();
              var translateMs = 0;
              var renderMs = 0;

              if (newIndices.isEmpty) {
                // Only removals happened this cycle — nothing left to translate.
              } else if (_translationMode == TranslationMode.llm) {
                final textsToTranslate = [for (final i in newIndices) ocrResults[i].text];
                final batchResults = await _llmTranslationService.translateBatch(
                  texts: textsToTranslate,
                  sourceLanguage: _sourceLanguage,
                  targetLanguage: _targetLanguage,
                );
                translateMs = stopwatch.elapsedMilliseconds;

                // Stale check: if the user has scrolled/changed page, discard results
                if (!_isTranslating || myToken != _translationToken) {
                  print('Overlay: Translation stale or stopped (token mismatch), aborting');
                  droppedStale = true;
                  return;
                }

                stopwatch.reset();
                for (var k = 0; k < newIndices.length; k++) {
                  final i = newIndices[k];
                  final ocrResult = ocrResults[i];
                  final box = displayBoxes[i];
                  final id = idForIndex[i]!;
                  final translated = batchResults[k];
                  if (Platform.isAndroid) {
                    await _overlayService.showTranslationOverlay(
                      translated, id,
                      x: box.left, y: box.top, width: box.width, height: box.height,
                      overlayColor: ocrResult.overlayColor, backgroundColor: ocrResult.backgroundColor, isLight: ocrResult.isLight, imgWidth: ocrResult.imgWidth, imgHeight: ocrResult.imgHeight,
                    );
                  }
                  pendingPlaceholders.remove(id);
                  _displayedOverlays[id] = _DisplayedOverlay(ocrResult, translated, box);
                }
                renderMs = stopwatch.elapsedMilliseconds;
              } else {
                // Streaming mode for On-Device / ONNX (one block at a time)
                var tMs = 0;
                var rMs = 0;
                for (var k = 0; k < newIndices.length; k++) {
                  final i = newIndices[k];
                  // Stale check on each block: abort if user has navigated away
                  if (!_isTranslating || myToken != _translationToken) {
                    print('Overlay: Translation stale at block $i (token mismatch), aborting');
                    droppedStale = true;
                    return;
                  }
                  final ocrResult = ocrResults[i];
                  final id = idForIndex[i]!;

                  final tWatch = Stopwatch()..start();
                  final translatedText = await translateText(ocrResult.text);
                  tMs += tWatch.elapsedMilliseconds;

                  // Stale check again after the (potentially slow) translation call
                  if (myToken != _translationToken) {
                    print('Overlay: Translation stale after block $i, discarding');
                    droppedStale = true;
                    return;
                  }

                  final box = displayBoxes[i];
                  final rWatch = Stopwatch()..start();
                  if (Platform.isAndroid) {
                    await _overlayService.showTranslationOverlay(
                      translatedText, id,
                      x: box.left, y: box.top, width: box.width, height: box.height,
                      overlayColor: ocrResult.overlayColor, backgroundColor: ocrResult.backgroundColor, isLight: ocrResult.isLight, imgWidth: ocrResult.imgWidth, imgHeight: ocrResult.imgHeight,
                    );
                  }
                  rMs += rWatch.elapsedMilliseconds;
                  pendingPlaceholders.remove(id);
                  _displayedOverlays[id] = _DisplayedOverlay(ocrResult, translatedText, box);
                }
                translateMs = tMs;
                renderMs = rMs;
              }

              print('Overlay: Translations complete (${newIndices.length} new/changed, ${matchedIdForIndex.length} reused)');

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

              if (ocrResults.isNotEmpty) {
                _lastTranslatedText = ocrResults.map((r) => r.text).join('\n');
                notifyListeners();
              }
            } else {
              print('Timer: captureScreen returned null or not translating, skipping');
            }
          }
        } else {
          print('Timer: skipping - mode=$translationMode, isManualRequested=$_isManualTranslationRequested');
        }
      } catch (e, stackTrace) {
        print('Error processing captured screen: $e');
        print('Stack trace: $stackTrace');
      } finally {
        if (pendingPlaceholders.isNotEmpty) {
          try {
            await _hidePlaceholders(pendingPlaceholders);
          } catch (e) {
            print('Error hiding leftover placeholders: $e');
          }
        }
        if (droppedStale && _isTranslating) {
          await _androidScreenCaptureService?.requestFreshFrame();
        }
        _isProcessingCapture = false; // Always release guard
        // Always clear here (not inline after a successful cycle) so a
        // manual request that gets abandoned mid-cycle — e.g. the user taps
        // "Stop Translation" while an LLM/ONNX call is still in flight, which
        // trips the staleness check above and returns early — doesn't leave
        // this stuck true. A stuck flag makes every future tick look like a
        // fresh manual request, bypassing the "screen unchanged, skip"
        // optimization (an extra, avoidable LLM API call/battery hit) until
        // it happens to complete one cycle uninterrupted.
        _isManualTranslationRequested = false;
      }
    });
  }

  Future<bool> _startAndroidScreenCapture() async {
    if (_androidScreenCaptureService == null) {
      throw Exception('Android screen capture service not initialized');
    }
    return await _androidScreenCaptureService!.requestScreenCapture();
  }

  Future<void> stopTranslation() async {
    _isTranslating = false;
    _isProcessingCapture = false;
    _isManualTranslationRequested = false;
    _displayedOverlays.clear();
    _translationToken++;
    _nextOverlayId = 0;
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
              _displayedOverlays.clear();
              // Invalidate any cycle already in flight. Without this its
              // token still matches, so it draws the (now cancelled, i.e.
              // untranslated) results and records them in
              // _displayedOverlays, where the next tick matches them by
              // text/position and never re-translates them.
              _translationToken++;
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
    _llmTranslationService.dispose();
    super.dispose();
  }

  static Map<String, String> get supportedLanguages {
    return {
      for (var language in TranslateLanguage.values)
        language.bcpCode: language.toString().split('.').last.capitalize()
    };
  }
}
