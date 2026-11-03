import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:provider/provider.dart';
import 'package:screen_translate/l10n/app_localizations.dart';
import 'package:screen_translate/providers/translation_provider.dart';
import 'package:screen_translate/screens/image_translation_screen.dart';

class _FirebaseCoreMock extends MockFirebaseApp {
  @override
  Future<List<CoreInitializeResponse>> initializeCore() async {
    final apps = await super.initializeCore();
    apps.single.pluginConstants = {
      'plugins.flutter.io/firebase_crashlytics': {
        'isCrashlyticsCollectionEnabled': true,
      },
    };
    return apps;
  }
}

class _TranslationProvider extends Fake
    with ChangeNotifier
    implements TranslationProvider {
  @override
  TextRecognitionScript get currentOCRScript => TextRecognitionScript.latin;
  @override
  double get mergeAggressiveness => 1.5;
  @override
  String get sourceLanguage => 'ja';
  @override
  String get targetLanguage => 'en';
  @override
  TranslationMode get translationMode => TranslationMode.onDevice;
  @override
  Future<List<String>> translateBatch(List<String> texts) async => [];
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const crashlytics = MethodChannel('plugins.flutter.io/firebase_crashlytics');
  const recognizer = MethodChannel('google_mlkit_text_recognizer');
  final reports = <Map<Object?, Object?>>[];
  var reportingFails = false;

  setUpAll(() async {
    TestFirebaseCoreHostApi.setUp(_FirebaseCoreMock());
    await Firebase.initializeApp();
  });

  setUp(() {
    reports.clear();
    reportingFails = false;
    binding.imageCache.clear();
    binding.imageCache.clearLiveImages();
    binding.defaultBinaryMessenger.setMockMethodCallHandler(crashlytics,
        (call) async {
      if (call.method == 'Crashlytics#recordError') {
        reports.add(Map<Object?, Object?>.from(call.arguments as Map));
        if (reportingFails) throw PlatformException(code: 'unavailable');
      }
      return null;
    });
    // Decoding the preview must recover even when native OCR rejects the input.
    binding.defaultBinaryMessenger.setMockMethodCallHandler(recognizer,
        (call) async => throw PlatformException(code: 'invalid-image'));
  });

  tearDown(() {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(crashlytics, null);
    binding.defaultBinaryMessenger.setMockMethodCallHandler(recognizer, null);
  });

  Future<void> showPreview(
      WidgetTester tester, ImageTranslationScreen screen) async {
    final provider = _TranslationProvider();
    addTearDown(provider.dispose);
    await tester.runAsync(() async {
      await tester.pumpWidget(ChangeNotifierProvider<TranslationProvider>.value(
        value: provider,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: screen,
        ),
      ));
      await tester.pumpAndSettle();

      // Wait for the actual image stream instead of an arbitrary decode delay.
      // File reads and engine decoding need real asynchronous work in a test.
      final image = tester.widget<Image>(find.byType(Image));
      final stream = image.image.resolve(ImageConfiguration.empty);
      final decoded = Completer<void>();
      final listener = ImageStreamListener(
        (_, __) => decoded.complete(),
        onError: (_, __) => decoded.complete(),
      );
      stream.addListener(listener);
      try {
        await decoded.future.timeout(const Duration(seconds: 5));
      } finally {
        stream.removeListener(listener);
      }
    });
    await tester.pumpAndSettle();
  }

  Uint8List corruptBytes() =>
      Uint8List.fromList(List<int>.generate(64, (i) => i));

  void expectRecovery(WidgetTester tester) {
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('image_decode_error')), findsOneWidget);
    expect(reports, hasLength(1));
    expect(reports.single['fatal'], isFalse);
    expect(reports.single['exception'], isNotEmpty);
    expect(reports.single['reason'],
        'Image translation preview could not be decoded');
  }

  testWidgets(
      'corrupt memory preview recovers and reports once across rebuilds',
      (tester) async {
    await showPreview(
        tester, ImageTranslationScreen(memoryImage: corruptBytes()));
    expectRecovery(tester);

    tester.element(find.byType(Image)).markNeedsBuild();
    await tester.pump();
    expectRecovery(tester);
  });

  testWidgets('corrupt file preview recovers and reports a nonfatal error',
      (tester) async {
    final directory =
        Directory.systemTemp.createTempSync('image-preview-test-');
    addTearDown(() => directory.deleteSync(recursive: true));
    final file = File('${directory.path}/corrupt.png')
      ..writeAsBytesSync(corruptBytes());

    await showPreview(tester, ImageTranslationScreen(imageFile: file));
    expectRecovery(tester);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('reporting failure does not break the error placeholder',
      (tester) async {
    reportingFails = true;
    await showPreview(
        tester, ImageTranslationScreen(memoryImage: corruptBytes()));
    expectRecovery(tester);
  });

  testWidgets('valid preview renders without a decode error report',
      (tester) async {
    final png = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJ'
      'AAAACklEQVR4nGMAAQAABQABDQottAAAAABJRU5ErkJggg==',
    );
    await showPreview(tester, ImageTranslationScreen(memoryImage: png));
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('image_decode_error')), findsNothing);
    expect(find.byType(RawImage), findsOneWidget);
    expect(reports, isEmpty);
  });
}
