import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'providers/translation_provider.dart';
import 'services/ocr_service.dart';
import 'services/translation_service.dart';
import 'services/overlay_service.dart';
import 'services/firebase_analytics_service.dart';
import 'services/activation_tracker.dart';
import 'services/accessibility_funnel_reporter.dart';
import 'services/firebase_remote_config_service.dart';
import 'services/startup_tasks.dart';
import 'package:logging/logging.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:screen_translate/l10n/app_localizations.dart';
import 'package:screen_translate/l10n/locale_resolution.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/review_prompt_service.dart';

Future<void> main() async {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print('${record.loggerName}: ${record.level.name}: ${record.time}: ${record.message}');
  });
  WidgetsFlutterBinding.ensureInitialized();

  // Run the app UI immediately so the user never gets stuck on the splash screen/logo!
  runApp(const ScreenTranslateApp());

  // Initialize Firebase and other network-dependent background services
  // asynchronously. Each step is isolated, and the steps that report the
  // start of a session come before the slow ones — see runStartupTasks.
  Future(() => runStartupTasks(backgroundStartupTasks()));
}

/// Background startup, in the order it has to happen in.
///
/// Firebase first because everything below talks to it, then crash
/// reporting, then everything that reports this launch to analytics, and
/// only then the steps that can take their time (the previous-run crash
/// check reads prefs; Remote Config fetches over the network).
List<StartupTask> backgroundStartupTasks() => [
      const StartupTask('Firebase', _initFirebase),
      const StartupTask('crash reporting', _initCrashReporting),
      StartupTask(
        'analytics',
        () => FirebaseAnalyticsService().init(),
        timeout: const Duration(seconds: 5),
      ),
      StartupTask(
        'app_opened',
        () => FirebaseAnalyticsService().trackAppOpen(),
        timeout: const Duration(seconds: 5),
      ),
      StartupTask(
        'activation first-seen',
        () => ActivationTracker.instance.recordAppOpen(),
        timeout: const Duration(seconds: 5),
      ),
      if (Platform.isAndroid)
        StartupTask(
          'accessibility funnel',
          () => AccessibilityFunnelReporter.instance.report(),
          timeout: const Duration(seconds: 5),
        ),
      const StartupTask('previous-run crash check', _recordPreviousCrash),
      // Remote Config's own fetch timeout is 20 s, so anything shorter here
      // cuts it off before it can give up on its own. It runs last, where
      // taking that long costs nothing.
      const StartupTask(
        'Remote Config',
        _initRemoteConfig,
        timeout: Duration(seconds: 25),
      ),
    ];

Future<void> _initFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on FirebaseException catch (e) {
    // The Android FlutterFire plugin auto-initializes the default
    // Firebase app from google-services.json via a native
    // ContentProvider before this Dart call ever runs, so this throws
    // "duplicate-app" on every launch — not a real failure, just means
    // the app is already there and usable. Anything else is a real error
    // and should still be reported as a failed step.
    if (e.code != 'duplicate-app') rethrow;
    print('Background Services: Firebase already initialized natively, continuing.');
  }
}

/// Crash reporting — this was previously a total blind spot: the only error
/// signal anywhere in the app was a manually-called trackError() that
/// nothing actually invoked, so native crashes and uncaught Dart exceptions
/// were invisible. Wiring both error channels (Flutter framework errors and
/// everything else, e.g. errors in async callbacks/isolates) is the standard
/// FlutterFire pattern.
Future<void> _initCrashReporting() async {
  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
}

/// A crash on the previous run marks this device as having had an error, so
/// the in-app review prompt never asks it.
Future<void> _recordPreviousCrash() async {
  if (await FirebaseCrashlytics.instance.didCrashOnPreviousExecution()) {
    final prefs = await SharedPreferences.getInstance();
    await ReviewPromptService(prefs).recordError();
  }
}

Future<void> _initRemoteConfig() async {
  final remoteConfig = FirebaseRemoteConfigService();
  await remoteConfig.init();
  remoteConfig.logAllValues();
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
