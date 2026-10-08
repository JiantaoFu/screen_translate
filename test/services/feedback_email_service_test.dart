import 'package:flutter_test/flutter_test.dart';
import 'package:screen_translate/services/feedback_email_service.dart';

void main() {
  final body = feedbackBody(
    appVersion: '1.2.3+13',
    manufacturer: 'Google',
    model: 'Pixel 8',
    androidVersion: '14',
    sdkInt: 34,
    engine: 'Quick (ML Kit offline)',
    languagePair: 'ja → en',
  );

  test('body carries version, device, Android, engine and languages', () {
    expect(body, contains('App version: 1.2.3+13'));
    expect(body, contains('Device: Google Pixel 8'));
    expect(body, contains('Android: 14 (SDK 34)'));
    expect(body, contains('Engine: Quick (ML Kit offline)'));
    expect(body, contains('Languages: ja → en'));
  });

  test('mailto goes to the support inbox and round-trips subject and body', () {
    final uri = feedbackMailto(subject: 'Send Feedback', body: body);
    expect(uri.scheme, 'mailto');
    expect(uri.path, kSupportEmail);
    expect(uri.toString(), isNot(contains('+')), reason: 'spaces must be %20, not +');
    expect(uri.queryParameters['subject'], 'Send Feedback');
    expect(uri.queryParameters['body'], body);
  });

  test('subject is fixed English plus the locale code', () {
    expect(feedbackSubject('es'), 'Screen Translate feedback (es)');
    expect(feedbackSubject('pt'), 'Screen Translate feedback (pt)');
  });
}
