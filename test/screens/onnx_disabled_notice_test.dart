import 'package:flutter_test/flutter_test.dart';
import 'package:screen_translate/main.dart';
import 'package:screen_translate/services/onnx_crash_guard.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// HomeScreen asks for the "AI Enhanced was turned off" note in its first
/// post-frame callback. That callback runs before TranslationProvider has
/// restored the saved translation mode from prefs, so a check against the
/// provider's restored state is still at its default there — which is how
/// the note came to never appear at all.
void main() {
  const noteStart = 'AI Enhanced stopped unexpectedly';

  Future<void> launch(WidgetTester tester) async {
    await tester.pumpWidget(const ScreenTranslateApp());
    // One frame to run the post-frame callback, then let the prefs read and
    // the SnackBar's entrance animation finish.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
  }

  testWidgets('the note shows on the launch after ONNX was disabled', (tester) async {
    SharedPreferences.setMockInitialValues({
      OnnxCrashGuard.kStrikes: 2,
      'translationMode': 'onnx',
    });

    await launch(tester);

    expect(find.textContaining(noteStart), findsOneWidget);
  });

  testWidgets('the note shows only once', (tester) async {
    SharedPreferences.setMockInitialValues({
      OnnxCrashGuard.kStrikes: 2,
      OnnxCrashGuard.kNoticeShown: true,
      'translationMode': 'onnx',
    });

    await launch(tester);

    expect(find.textContaining(noteStart), findsNothing);
  });

  testWidgets('no note when ONNX was never disabled', (tester) async {
    SharedPreferences.setMockInitialValues({'translationMode': 'onnx'});

    await launch(tester);

    expect(find.textContaining(noteStart), findsNothing);
  });
}
