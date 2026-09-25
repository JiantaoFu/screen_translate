import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:screen_translate/l10n/app_localizations.dart';
import 'package:screen_translate/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<Locale> startWithDeviceLocale(WidgetTester tester, Locale device) async {
    tester.platformDispatcher.localesTestValue = [device];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(const ScreenTranslateApp());
    await tester.pump();
    expect(tester.takeException(), isNull);
    final context = tester.element(find.byType(Scaffold).first);
    expect(AppLocalizations.of(context), isNotNull);
    return Localizations.localeOf(context);
  }

  testWidgets('a device language the app lacks falls back to English', (tester) async {
    expect((await startWithDeviceLocale(tester, const Locale('uk'))).languageCode, 'en');
  });

  testWidgets('Norwegian Bokmål (nb) uses the Norwegian translation', (tester) async {
    expect((await startWithDeviceLocale(tester, const Locale('nb', 'NO'))).languageCode, 'no');
  });

  testWidgets('legacy Hebrew code is recognised', (tester) async {
    expect((await startWithDeviceLocale(tester, const Locale('iw'))).languageCode, 'he');
  });

  testWidgets('legacy Indonesian code is recognised', (tester) async {
    expect((await startWithDeviceLocale(tester, const Locale('in'))).languageCode, 'id');
  });

  testWidgets('a supported device language is used as is', (tester) async {
    expect((await startWithDeviceLocale(tester, const Locale('ja', 'JP'))).languageCode, 'ja');
  });
}
