import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screen_translate/app_flavor.dart';
import 'package:screen_translate/services/firebase_analytics_service.dart';

/// Debug builds (emulator regression, store-asset recordings, local runs)
/// used to report to GA like real users and skewed every funnel. Only
/// release builds may collect, and every release launch tags the app it is.
class _RecordingAnalytics extends Fake implements FirebaseAnalytics {
  final collection = <bool>[];
  final properties = <String, String?>{};

  @override
  Future<void> setAnalyticsCollectionEnabled(bool enabled) async => collection.add(enabled);

  @override
  Future<void> setUserProperty({
    required String name,
    required String? value,
    AnalyticsCallOptions? callOptions,
  }) async =>
      properties[name] = value;
}

void main() {
  late _RecordingAnalytics analytics;
  late FirebaseAnalyticsService service;

  setUp(() {
    analytics = _RecordingAnalytics();
    service = FirebaseAnalyticsService()..debugUseAnalytics(analytics);
  });

  tearDown(() => AppFlavorConfig.debugSet(AppFlavor.paid));

  test('a non-release build turns collection off and tags nothing', () async {
    await service.init(); // tests run in debug mode, like the emulator APK
    expect(analytics.collection, [false]);
    expect(analytics.properties, isEmpty);
  });

  test('a release build collects and tags the paid app', () async {
    AppFlavorConfig.debugSet(AppFlavor.paid);
    await service.init(collect: true);
    expect(analytics.collection, [true]);
    expect(analytics.properties, {FirebaseAnalyticsService.flavorProperty: 'paid'});
  });

  test('a release build collects and tags the Lite app', () async {
    AppFlavorConfig.debugSet(AppFlavor.lite);
    await service.init(collect: true);
    expect(analytics.properties, {'flavor': 'lite'});
  });
}
