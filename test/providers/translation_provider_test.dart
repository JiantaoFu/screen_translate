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
      // Test locale is en-US: translate *into* English, from Japanese.
      expect(provider.sourceLanguage, 'ja');
      expect(provider.targetLanguage, 'en');
      expect(provider.translationMode, TranslationMode.onDevice);
    });

    test('default pair targets the device language', () {
      expect(TranslationProvider.defaultLanguagePairFor('pt'), ('en', 'pt'));
      expect(TranslationProvider.defaultLanguagePairFor('th'), ('en', 'th'));
      expect(TranslationProvider.defaultLanguagePairFor('zh'), ('en', 'zh'));
      expect(TranslationProvider.defaultLanguagePairFor('en'), ('ja', 'en'));
      // Legacy Android codes are mapped; unsupported ones fall back to English.
      expect(TranslationProvider.defaultLanguagePairFor('in'), ('en', 'id'));
      expect(TranslationProvider.defaultLanguagePairFor('xx'), ('ja', 'en'));
    });

    test('language pair is persisted and restored', () async {
      provider.setSourceLanguage('ko');
      provider.setTargetLanguage('vi');
      await pumpEventQueue();

      final restored = TranslationProvider(
        null,
        FakeOCRService(),
        FakeTranslationService(),
        FakeOverlayService(),
        llmTranslationService: FakeLLMTranslationService(),
        onnxTranslationService: FakeOnnxTranslationService(),
      );
      await pumpEventQueue();
      expect(restored.sourceLanguage, 'ko');
      expect(restored.targetLanguage, 'vi');
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
      provider.setSourceLanguage('en');
      provider.setTargetLanguage('zh');
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

  group('withoutOwnOverlayText', () {
    test('drops text read back from our own overlays and reports them', () {
      final ownTranslation = _box('天気がいい', 40, 190, 900, 80);
      final newSubtitle = _box('Hello there', 100, 800, 600, 50);
      final covered = <int>{};
      final kept = TranslationProvider.withoutOwnOverlayText(
        [ownTranslation, newSubtitle],
        {7: const Rect.fromLTWH(30, 180, 920, 100)},
        covered,
      );
      expect(kept, [newSubtitle]);
      expect(covered, {7});
    });

    test('a block OCR merged across two of our boxes covers both', () {
      // Our boxes for two paragraphs, and OCR reading them back as one block
      // whose centre falls in the gap between them.
      final merged = _box('段落一 段落二', 30, 180, 920, 250);
      final covered = <int>{};
      final kept = TranslationProvider.withoutOwnOverlayText(
        [merged],
        {
          1: const Rect.fromLTWH(30, 180, 920, 110),
          2: const Rect.fromLTWH(30, 320, 920, 110),
        },
        covered,
      );
      expect(kept, isEmpty);
      expect(covered, {1, 2});
    });

    test('text only partly under a box is not ours', () {
      final covered = <int>{};
      final r = _box('new caption', 0, 0, 400, 100);
      final kept = TranslationProvider.withoutOwnOverlayText(
          [r], {1: const Rect.fromLTWH(300, 0, 400, 100)}, covered);
      expect(kept, [r]);
      expect(covered, isEmpty);
    });

    test('keeps everything when no overlays are shown', () {
      final covered = <int>{};
      final all = [_box('a', 0, 0, 10, 10), _box('b', 50, 50, 10, 10)];
      expect(TranslationProvider.withoutOwnOverlayText(all, {}, covered), all);
      expect(covered, isEmpty);
    });
  });

  group('continuesText', () {
    // Our box over the first half of a typed-out dialogue line (55px line).
    const box = Rect.fromLTWH(90, 2080, 780, 66);

    test('the rest of the same line right after the box', () {
      expect(TranslationProvider.continuesText(box, const Rect.fromLTWH(880, 2086, 90, 55)), isTrue);
    });

    test('the next line at the same indent', () {
      expect(TranslationProvider.continuesText(box, const Rect.fromLTWH(95, 2150, 800, 55)), isTrue);
    });

    test('text far along the same row is not a continuation', () {
      expect(TranslationProvider.continuesText(box, const Rect.fromLTWH(1000, 2086, 60, 55)), isFalse);
    });

    test('text just below but not aligned (e.g. read off a video) is not', () {
      expect(TranslationProvider.continuesText(box, const Rect.fromLTWH(400, 2160, 200, 40)), isFalse);
    });

    test('text well below the box is not', () {
      expect(TranslationProvider.continuesText(box, const Rect.fromLTWH(95, 2300, 800, 55)), isFalse);
    });
  });

  group('staleOverlayIds', () {
    // Our box over the first line of a dialogue box, and another one far up.
    const dialogueBox = Rect.fromLTWH(90, 2080, 780, 66);
    const titleBox = Rect.fromLTWH(40, 200, 900, 70);
    final drawn = {1: dialogueBox, 2: titleBox};

    test('new text overlapping a box marks just that box', () {
      // OCR read lines 1-3 of the dialogue as one block, partly under box 1.
      expect(TranslationProvider.staleOverlayIds(drawn, const [Rect.fromLTWH(80, 2070, 800, 220)]), {1});
    });

    test('new text continuing past a box marks it', () {
      expect(TranslationProvider.staleOverlayIds(drawn, const [Rect.fromLTWH(95, 2150, 800, 55)]), {1});
    });

    test('new text directly above a box (text growing upward) marks it', () {
      // A bottom-anchored line wrapped: the earlier line moved up above box 1.
      expect(TranslationProvider.staleOverlayIds(drawn, const [Rect.fromLTWH(95, 2020, 800, 55)]), {1});
    });

    test('unrelated new text marks nothing', () {
      expect(TranslationProvider.staleOverlayIds(drawn, const [Rect.fromLTWH(100, 1200, 600, 60)]), isEmpty);
      expect(TranslationProvider.staleOverlayIds(drawn, const []), isEmpty);
    });
  });

  group('hasTranslatableText', () {
    test('skips clocks and counters, keeps text in any script', () {
      bool t(String s) => TranslationProvider.hasTranslatableText(_box(s, 0, 0, 10, 10));
      expect(t('01:52'), isFalse);
      expect(t('12,345 / 99%'), isFalse);
      expect(t('Hello'), isTrue);
      expect(t('こんにちは'), isTrue);
      expect(t('안녕 3'), isTrue);
      expect(t('Привет'), isTrue);
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
