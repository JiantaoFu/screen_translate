import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:screen_translate/providers/translation_provider.dart';
import 'package:screen_translate/screens/home_screen.dart';
import 'package:screen_translate/screens/overlay_test_screen.dart';

void main() {
  runApp(const ScreenTranslateApp());
}

class ScreenTranslateApp extends StatelessWidget {
  const ScreenTranslateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Screen Translate',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: Builder(
        builder: (context) => ChangeNotifierProvider(
          create: (_) => TranslationProvider(context: context),
          child: const HomeScreen(),
        ),
      ),
    );
  }
}
