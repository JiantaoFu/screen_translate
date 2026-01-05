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
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print('${record.loggerName}: ${record.level.name}: ${record.time}: ${record.message}');
  });
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Firebase Remote Config
  final remoteConfig = FirebaseRemoteConfigService();
  await remoteConfig.init();
  remoteConfig.logAllValues();

  // Initialize Firebase Analytics
  final analytics = FirebaseAnalyticsService();
  await analytics.init();
  await analytics.trackAppOpen();

  runApp(const ScreenTranslateApp());
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
      localeResolutionCallback: (locale, supportedLocales) {
        // Fallback to English if locale is not supported
        print('Device Locale: $locale');
        print('Supported Locales: $supportedLocales');
        return locale;
      },
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
