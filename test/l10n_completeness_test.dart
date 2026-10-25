import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every language must carry every string, in both the Flutter ARB files and
/// the Android resources (accessibility dialog, overlay labels). Until
/// 2026-09 the 35 localized strings.xml files were all empty and Finnish
/// lacked four ARB keys, which nothing caught.
void main() {
  final arbDir = Directory('lib/l10n');
  final resDir = Directory('android/app/src/main/res');

  Map<String, dynamic> readArb(File f) => jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
  Set<String> messageKeys(Map<String, dynamic> arb) => arb.keys.where((k) => !k.startsWith('@')).toSet();
  Set<String> placeholders(String s) => RegExp(r'\{(\w+)\}').allMatches(s).map((m) => m[1]!).toSet();

  final english = readArb(File('lib/l10n/app_en.arb'));
  final arbFiles = arbDir
      .listSync()
      .whereType<File>()
      .where((f) => RegExp(r'app_[a-z]{2}\.arb$').hasMatch(f.path))
      .toList();

  test('every ARB file has exactly the English keys with the same placeholders', () {
    expect(arbFiles.length, greaterThan(30));
    for (final file in arbFiles) {
      final arb = readArb(file);
      final name = file.uri.pathSegments.last;
      expect(messageKeys(arb), messageKeys(english), reason: name);
      for (final key in messageKeys(english)) {
        expect(placeholders(arb[key] as String), placeholders(english[key] as String), reason: '$name $key');
        expect((arb[key] as String).trim(), isNotEmpty, reason: '$name $key');
      }
    }
  });

  Set<String> androidStringNames(File f) =>
      RegExp(r'<string name="([^"]+)"').allMatches(f.readAsStringSync()).map((m) => m[1]!).toSet();

  test('every Android locale has every default string', () {
    final defaults = androidStringNames(File('${resDir.path}/values/strings.xml'));
    expect(defaults, isNotEmpty);
    final localized = resDir
        .listSync()
        .whereType<Directory>()
        .where((d) => RegExp(r'values-[a-z]{2}$').hasMatch(d.path))
        .toList();
    for (final dir in localized) {
      final file = File('${dir.path}/strings.xml');
      if (!file.existsSync()) continue;
      expect(androidStringNames(file), defaults, reason: dir.path);
    }
  });

  test('every app language also has Android strings', () {
    for (final file in arbFiles) {
      final lang = RegExp(r'app_([a-z]{2})\.arb$').firstMatch(file.path)![1]!;
      if (lang == 'en') continue;
      expect(File('${resDir.path}/values-$lang/strings.xml').existsSync(), isTrue, reason: lang);
    }
    // Android reports Norwegian Bokmål as "nb".
    expect(File('${resDir.path}/values-nb/strings.xml').existsSync(), isTrue);
  });
}
