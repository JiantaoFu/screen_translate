import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:screen_translate/providers/translation_provider.dart';
import 'package:screen_translate/services/activation_tracker.dart';
import 'package:screen_translate/widgets/no_text_source_prompt.dart';

import '../mocks/fake_services.dart';

TranslationProvider _provider() => TranslationProvider(
      null,
      FakeOCRService(),
      FakeTranslationService(),
      FakeOverlayService(),
      llmTranslationService: FakeLLMTranslationService(),
      onnxTranslationService: FakeOnnxTranslationService(),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('sessionFoundNoText only when every OCR pass was empty', () {
    final p = _provider();
    expect(p.sessionFoundNoText, isFalse); // no OCR yet
    p.debugRecordOcrFrame(0);
    p.debugRecordOcrFrame(0);
    expect(p.sessionFoundNoText, isTrue);
    p.debugRecordOcrFrame(3);
    expect(p.sessionFoundNoText, isFalse);
  });

  test('offered only before the first translation, at most 3 times', () async {
    expect(
        await shouldOfferSourceLanguages(sessionFoundNoText: false), isFalse);
    expect(await shouldOfferSourceLanguages(sessionFoundNoText: true), isTrue);
    SharedPreferences.setMockInitialValues(
        {prefNoTextPromptCount: noTextPromptMaxShows});
    expect(await shouldOfferSourceLanguages(sessionFoundNoText: true), isFalse);
    SharedPreferences.setMockInitialValues(
        {ActivationTracker.prefFirstTranslationLogged: true});
    expect(await shouldOfferSourceLanguages(sessionFoundNoText: true), isFalse);
  });

  testWidgets('prompt shows four languages and returns the tapped one',
      (tester) async {
    String? picked;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async => picked =
              await showNoTextSourcePrompt(context, currentSource: 'en'),
          child: const Text('go'),
        ),
      ),
    ));
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(find.text('No text found. Try another source language?'),
        findsOneWidget);
    for (final label in ['日本語', '한국어', '中文', 'English']) {
      expect(find.text(label), findsOneWidget);
    }
    await tester.tap(find.text('한국어'));
    await tester.pumpAndSettle();
    expect(picked, 'ko');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt(prefNoTextPromptCount), 1);
  });

  testWidgets('prompt hides the target language (ja-JP device: target ja)',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => showNoTextSourcePrompt(context,
              currentSource: 'en', targetLanguage: 'ja'),
          child: const Text('go'),
        ),
      ),
    ));
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(find.text('日本語'), findsNothing);
    for (final label in ['한국어', '中文', 'English']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.byType(OutlinedButton), findsNWidgets(3));
  });
}
