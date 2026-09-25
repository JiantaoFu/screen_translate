import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'providers/translation_provider.dart';
import 'services/ocr_service.dart';
import 'services/translation_service.dart';
import 'services/overlay_service.dart';
import 'services/firebase_analytics_service.dart';
import 'services/firebase_remote_config_service.dart';
import 'package:logging/logging.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:screen_translate/l10n/app_localizations.dart';
import 'package:screen_translate/l10n/locale_resolution.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'firebase_options.dart';
import 'services/ocr_sampling_service.dart';

Future<void> main() async {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print('${record.loggerName}: ${record.level.name}: ${record.time}: ${record.message}');
  });
  WidgetsFlutterBinding.ensureInitialized();

  // Run the app UI immediately so the user never gets stuck on the splash screen/logo!
  runApp(const ScreenTranslateApp());

  // Initialize Firebase and other network-dependent background services asynchronously
  Future(() async {
    try {
      print('Background Services: Initializing Firebase...');
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        ).timeout(const Duration(seconds: 10));
      } on FirebaseException catch (e) {
        // The Android FlutterFire plugin auto-initializes the default
        // Firebase app from google-services.json via a native
        // ContentProvider before this Dart call ever runs, so this throws
        // "duplicate-app" on every launch — not a real failure, just means
        // the app is already there and usable. Anything else is a real
        // error and should still short-circuit the block below (Crashlytics
        // must not silently end up half-configured).
        if (e.code != 'duplicate-app') rethrow;
        print('Background Services: Firebase already initialized natively, continuing.');
      }

      // Crash reporting — this was previously a total blind spot: the only
      // error signal anywhere in the app was a manually-called trackError()
      // that nothing actually invoked, so native crashes and uncaught Dart
      // exceptions were invisible. Wiring both error channels (Flutter
      // framework errors and everything else, e.g. errors in async
      // callbacks/isolates) is the standard FlutterFire pattern.
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };

      // Initialize Firebase Remote Config
      final remoteConfig = FirebaseRemoteConfigService();
      await remoteConfig.init().timeout(const Duration(seconds: 10));
      remoteConfig.logAllValues();

      // Initialize Firebase Analytics
      final analytics = FirebaseAnalyticsService();
      await analytics.init().timeout(const Duration(seconds: 5));
      await analytics.trackAppOpen();

      // Initialize OCR Sampling Service
      final ocrSamplingService = OCRSamplingService();
      await ocrSamplingService.init(
        cloudinaryCloudName: 'dyr6qobke',
        cloudinaryUploadPreset: 'oucv1boz',
      ).timeout(const Duration(seconds: 5));
      print('Background Services: All services initialized successfully.');
    } catch (e) {
      print('Background Services: Non-fatal initialization error: $e');
    }
  });
}

class ScreenTranslateApp extends StatelessWidget {
  const ScreenTranslateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Screen Translate',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: resolveAppLocale,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: Builder(
        builder: (context) => MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (context) => TranslationProvider(
                context,
                OCRService(),
                TranslationService(),
                OverlayService(),
              ),
            ),
          ],
          child: const HomeScreen(),
        ),
      ),
    );
  }
}
