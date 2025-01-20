import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'providers/translation_provider.dart';
import 'services/ocr_service.dart';
import 'services/translation_service.dart';
import 'services/overlay_service.dart';
import 'package:logging/logging.dart';

void main() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print('${record.loggerName}: ${record.level.name}: ${record.time}: ${record.message}');
  });
  runApp(const ScreenTranslateApp());
}

class ScreenTranslateApp extends StatelessWidget {
  const ScreenTranslateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Screen Translate',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: Builder(
        builder: (context) => MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (context) => TranslationProvider(
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
