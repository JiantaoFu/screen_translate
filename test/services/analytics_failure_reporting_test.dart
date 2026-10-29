import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screen_translate/services/firebase_analytics_service.dart';
import 'package:screen_translate/services/firebase_remote_config_service.dart';

/// `app_opened` is the denominator of every funnel, including the 2 h
/// activation north star. The startup steps that send it must be able to
/// report that they failed: a step whose work swallows its own exception
/// logs "ok" for a launch that was never counted, which is the blind spot
/// this PR exists to close.
class _ThrowingAnalytics extends Fake implements FirebaseAnalytics {
  int logEventCalls = 0;
  int collectionCalls = 0;

  @override
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
    List<AnalyticsEventItem>? items,
    AnalyticsCallOptions? callOptions,
  }) async {
    logEventCalls++;
    throw StateError('no analytics transport');
  }

  @override
  Future<void> setAnalyticsCollectionEnabled(bool enabled) async {
    collectionCalls++;
    throw StateError('no analytics transport');
  }
}

void main() {
  late _ThrowingAnalytics analytics;
  late FirebaseAnalyticsService service;

  setUp(() {
    analytics = _ThrowingAnalytics();
    service = FirebaseAnalyticsService()..debugUseAnalytics(analytics);
  });

  test('trackAppOpen propagates, so its startup step can report failure', () {
    expect(service.trackAppOpen(), throwsStateError);
    expect(analytics.logEventCalls, 1);
  });

  test('init propagates, so its startup step can report failure', () {
    expect(service.init(), throwsStateError);
    expect(analytics.collectionCalls, 1);
  });

  test('logEvent still swallows: analytics must not break a feature', () async {
    await service.logEvent('some_feature_event');
    expect(analytics.logEventCalls, 1);
  });

  test('logEventOrThrow propagates', () {
    expect(service.logEventOrThrow('some_event'), throwsStateError);
  });

  // Remote Config is the last startup step, so until it has registered its
  // defaults an unregistered key reads as 0 through the SDK.
  test('OCR minimum text length never reads as 0', () {
    expect(FirebaseRemoteConfigService.minTextLengthFrom(0),
        FirebaseRemoteConfigService.defaultOCRMinTextLength);
    expect(FirebaseRemoteConfigService.minTextLengthFrom(-1),
        FirebaseRemoteConfigService.defaultOCRMinTextLength);
    expect(FirebaseRemoteConfigService.minTextLengthFrom(3), 3);
  });
}
