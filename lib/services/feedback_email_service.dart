import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';

/// Support inbox for "Send feedback by email". Same address the Settings
/// feedback row has used since 1.2.0 (ccb5977).
const String kSupportEmail = 'support@wtao.top';

const _channel = MethodChannel('com.lomoware.screen_translate/feedback');

/// Installed versionName+versionCode, e.g. "1.2.3+13"; "unknown" off-device.
Future<String> installedAppVersion() async {
  try {
    return await _channel.invokeMethod<String>('getAppVersion') ?? 'unknown';
  } catch (_) {
    return 'unknown';
  }
}

/// Diagnostics block appended to every feedback email.
String feedbackBody({
  required String appVersion,
  required String manufacturer,
  required String model,
  required String androidVersion,
  required int sdkInt,
  required String engine,
  required String languagePair,
}) =>
    (StringBuffer()
          ..writeln('Please describe the problem:')
          ..writeln()
          ..writeln()
          ..writeln('---')
          ..writeln('App version: $appVersion')
          ..writeln('Device: $manufacturer $model')
          ..writeln('Android: $androidVersion (SDK $sdkInt)')
          ..writeln('Engine: $engine')
          ..writeln('Languages: $languagePair'))
        .toString();

/// Feedback email subject: fixed English plus the app's locale code, e.g.
/// "Screen Translate feedback (es)". Not localized, so support can filter
/// and read every subject whatever the user's language.
String feedbackSubject(String localeTag) => 'Screen Translate feedback ($localeTag)';

/// mailto: URI with subject and body. Encoded by hand: Uri's
/// queryParameters would turn spaces into "+", which mail apps show as is.
Uri feedbackMailto({required String subject, required String body, String to = kSupportEmail}) =>
    Uri.parse('mailto:$to?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}');

/// Opens an email app (ACTION_SENDTO) prefilled with device diagnostics.
class FeedbackEmailService {
  final DeviceInfoPlugin _deviceInfo;

  FeedbackEmailService({DeviceInfoPlugin? deviceInfo})
      : _deviceInfo = deviceInfo ?? DeviceInfoPlugin();

  /// Returns false when no email app could be opened.
  Future<bool> send({
    required String subject,
    required String engine,
    required String languagePair,
  }) async {
    var manufacturer = 'unknown', model = 'unknown', androidVersion = 'unknown';
    var sdkInt = 0;
    if (Platform.isAndroid) {
      try {
        final android = await _deviceInfo.androidInfo;
        manufacturer = android.manufacturer;
        model = android.model;
        androidVersion = android.version.release;
        sdkInt = android.version.sdkInt;
      } catch (_) {}
    }
    final body = feedbackBody(
      appVersion: await installedAppVersion(),
      manufacturer: manufacturer,
      model: model,
      androidVersion: androidVersion,
      sdkInt: sdkInt,
      engine: engine,
      languagePair: languagePair,
    );
    try {
      return await _channel.invokeMethod<bool>('sendEmail', {
            'uri': feedbackMailto(subject: subject, body: body).toString(),
            'subject': subject,
            'body': body,
          }) ??
          false;
    } catch (_) {
      return false;
    }
  }
}
