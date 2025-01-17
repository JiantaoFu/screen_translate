// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:screen_translate/main.dart';
import 'package:screen_translate/providers/translation_provider.dart';
import 'mocks/mock_translation_provider.dart';

void main() {
  testWidgets('App renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<TranslationProvider>(
            create: (_) => MockTranslationProvider(),
          ),
        ],
        child: const ScreenTranslateApp(),
      ),
    );

    expect(find.text('Screen Translate'), findsOneWidget);
    expect(find.text('Start Translation'), findsOneWidget);
    expect(find.text('Translation Inactive'), findsOneWidget);
  });

  testWidgets('Translation button shows error on permission denied', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<TranslationProvider>(
            create: (_) => MockTranslationProvider(),
          ),
        ],
        child: const ScreenTranslateApp(),
      ),
    );

    expect(find.text('Start Translation'), findsOneWidget);
    expect(find.text('Translation Inactive'), findsOneWidget);

    // Tap the translation button
    await tester.tap(find.byType(ElevatedButton));
    // Wait for the async operation and animation to complete
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Verify error message is shown
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Error: Exception: Required permissions were denied'), findsOneWidget);
  });
}
