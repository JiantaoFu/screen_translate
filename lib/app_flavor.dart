import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Which of the two Play apps this build is.
///
/// - [paid]: com.lomoware.screen_translate, no limits, no billing.
/// - [lite]: com.lomoware.screen_translate.lite, a daily free limit and a
///   one-time Pro unlock (lib/lite/).
enum AppFlavor { paid, lite }

class AppFlavorConfig {
  AppFlavorConfig._();

  /// `--dart-define=APP_FLAVOR=lite`; tools/build.py --flavor passes it.
  static const String dartDefine = String.fromEnvironment('APP_FLAVOR', defaultValue: 'paid');

  static const MethodChannel _channel = MethodChannel('com.lomoware.screen_translate/flavor');

  static AppFlavor _current = parse(dartDefine);

  static AppFlavor get current => _current;
  static bool get isLite => _current == AppFlavor.lite;

  static AppFlavor parse(String? value) =>
      value?.trim().toLowerCase() == 'lite' ? AppFlavor.lite : AppFlavor.paid;

  /// Cross-checks the dart-define with the APK's own Gradle flavor
  /// (BuildConfig.FLAVOR), so `flutter run --flavor lite` without the
  /// dart-define still behaves as lite. Either side saying lite wins: a lite
  /// APK must never run unlimited.
  static Future<void> resolve({Future<String?> Function()? nativeFlavor}) async {
    String? native;
    try {
      native = await (nativeFlavor ?? () => _channel.invokeMethod<String>('getFlavor'))();
    } catch (_) {
      native = null; // tests, non-Android platforms
    }
    _current = combine(dartDefine: dartDefine, native: native);
  }

  @visibleForTesting
  static AppFlavor combine({required String dartDefine, String? native}) =>
      (parse(dartDefine) == AppFlavor.lite || parse(native) == AppFlavor.lite)
          ? AppFlavor.lite
          : AppFlavor.paid;

  @visibleForTesting
  static void debugSet(AppFlavor flavor) => _current = flavor;
}
