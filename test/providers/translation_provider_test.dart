import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:screen_translate/models/ocr_result.dart';
import 'package:screen_translate/providers/translation_provider.dart';

import '../mocks/fake_services.dart';

OCRResult _box(String text, double x, double y, double w, double h) => OCRResult(
      text: text, x: x, y: y, width: w, height: h,
      imgWidth: 1080, imgHeight: 2400,
    );

bool _overlaps(Rect a, Rect b) =>
    a.left < b.right && a.right > b.left && a.top < b.bottom && a.bottom > b.top;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TranslationProvider provider;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    provider = TranslationProvider(
      null,
      FakeOCRService(),
      FakeTranslationService(),
      FakeOverlayService(),
      llmTranslationService: FakeLLMTranslationService(),
      onnxTranslationService: FakeOnnxTranslationService(),
    );
  });

  group('TranslationProvider state', () {
    test('initial values are correct', () {
      expect(provider.isTranslating, false);
      expect(provider.lastTranslatedText, '');
      expect(provider.sourceLanguage, 'en');
      expect(provider.targetLanguage, 'zh');
      expect(provider.translationMode, TranslationMode.onDevice);
    });

    test('setters update languages and mode, and notify listeners', () {
      var notifications = 0;
      provider.addListener(() => notifications++);

      provider.setSourceLanguage('ja');
      provider.setTargetLanguage('ko');
      provider.setTranslationMode(TranslationMode.llm);

      expect(provider.sourceLanguage, 'ja');
      expect(provider.targetLanguage, 'ko');
      expect(provider.translationMode, TranslationMode.llm);
      expect(notifications, 3);
    });

    test('swapLanguages swaps source and target', () {
      provider.swapLanguages();
      expect(provider.sourceLanguage, 'zh');
      expect(provider.targetLanguage, 'en');
      expect(provider.isChineseToEnglish, true);
    });

    test('merge aggressiveness is loaded from and persisted to preferences', () async {
      SharedPreferences.setMockInitialValues({'mergeAggressiveness': 2.5});
      final p = TranslationProvider(
        null,
        FakeOCRService(),
        FakeTranslationService(),
        FakeOverlayService(),
        llmTranslationService: FakeLLMTranslationService(),
        onnxTranslationService: FakeOnnxTranslationService(),
      );
      await pumpEventQueue();
      expect(p.mergeAggressiveness, 2.5);

      await p.setMergeAggressiveness(0.5);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getDouble('mergeAggressiveness'), 0.5);
    });

    test('stopTranslation leaves provider inactive', () async {
      await provider.stopTranslation();
      expect(provider.isTranslating, false);
    });

    test('supportedLanguages includes common codes', () {
      final langs = TranslationProvider.supportedLanguages;
      expect(langs.keys, containsAll(['en', 'zh', 'ja']));
    });
  });

  group('computeDisplayBoxes', () {
    test('pads an isolated box on every side', () {
      final boxes = provider.computeDisplayBoxesForTest([_box('a', 100, 100, 200, 40)]);
      const pad = 40 * 0.15;
      expect(boxes.single, const Rect.fromLTWH(100 - pad, 100 - pad, 200 + pad * 2, 40 + pad * 2));
    });

    test('same-row neighbors with a small gap do not overlap or get pushed down', () {
      // Two adjacent tabs 4px apart — less than the 2 × 6px default side pad.
      final left = _box('Home', 100, 100, 100, 40);
      final right = _box('Settings', 204, 100, 100, 40);
      final boxes = provider.computeDisplayBoxesForTest([left, right]);

      expect(_overlaps(boxes[0], boxes[1]), false);
      // Neither was shoved a row down by overlap resolution.
      expect(boxes[0].top, boxes[1].top);
      expect(boxes[1].top, lessThan(100));
    });

    test('stacked neighbors split the vertical gap instead of overlapping', () {
      final top = _box('line 1', 100, 100, 200, 40);
      final bottom = _box('line 2', 100, 144, 200, 40);
      final boxes = provider.computeDisplayBoxesForTest([top, bottom]);

      expect(_overlaps(boxes[0], boxes[1]), false);
      expect(boxes[0].bottom, lessThanOrEqualTo(142));
      expect(boxes[1].top, greaterThanOrEqualTo(142));
    });

    test('overlapping OCR boxes are pushed apart', () {
      final a = _box('a', 100, 100, 200, 40);
      final b = _box('b', 120, 120, 200, 40);
      final boxes = provider.computeDisplayBoxesForTest([a, b]);
      expect(_overlaps(boxes[0], boxes[1]), false);
    });
  });
}
