import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screen_translate/services/model_download_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const mlKitChannel = MethodChannel('google_mlkit_on_device_translator');

  late Completer<void> mlKitDownload;
  double? probeValue;
  bool probeWaiting = false;
  late Future<QuickDownloadReading?> Function(String) originalProbe;
  late Duration originalInterval;

  setUp(() {
    mlKitDownload = Completer<void>();
    probeValue = null;
    probeWaiting = false;
    originalProbe = ModelDownloadService.quickProgressProbe;
    originalInterval = ModelDownloadService.quickProgressPollInterval;
    ModelDownloadService.quickProgressProbe =
        (_) async => (progress: probeValue, waiting: probeWaiting);
    ModelDownloadService.quickProgressPollInterval = const Duration(milliseconds: 5);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(mlKitChannel, (call) async {
      await mlKitDownload.future;
      return 'success';
    });
  });

  tearDown(() {
    ModelDownloadService.quickProgressProbe = originalProbe;
    ModelDownloadService.quickProgressPollInterval = originalInterval;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(mlKitChannel, null);
  });

  Future<void> tick() => Future<void>.delayed(const Duration(milliseconds: 30));

  test('reports real progress, never backwards, 100% only when done', () async {
    final seen = <double>[];
    final download = ModelDownloadService().downloadModelWithFallback('zh', onProgress: seen.add);
    expect(ModelDownloadService.isQuickDownloading('zh'), isTrue);

    await tick();
    expect(seen, isEmpty, reason: 'no byte count yet: stay indeterminate');

    probeValue = 0.3;
    await tick();
    probeValue = 0.2; // a transient smaller reading must not move the bar back
    await tick();
    probeValue = 1.0; // bytes done, but ML Kit hasn't returned yet
    await tick();
    expect(seen.last, 0.99);
    expect(seen, containsAllInOrder([0.3, 0.99]));
    expect(seen, isNot(contains(0.2)));

    mlKitDownload.complete();
    await download;
    expect(seen.last, 1.0);
    expect(ModelDownloadService.isQuickDownloading('zh'), isFalse);
  });

  test('a second caller joins the running download and gets its progress', () async {
    final first = <double>[];
    final second = <double>[];
    final a = ModelDownloadService().downloadModelWithFallback('ja', onProgress: first.add);
    probeValue = 0.5;
    await tick();

    final b = ModelDownloadService().downloadModelWithFallback('ja', onProgress: second.add);
    expect(identical(a, b), isTrue);
    expect(second.first, 0.5, reason: 'joiner gets the current progress immediately');

    mlKitDownload.complete();
    await b;
    expect(first.last, 1.0);
    expect(second.last, 1.0);
  });

  test('reports when the download stalls waiting for the network and resumes', () async {
    final waiting = <bool>[];
    final download = ModelDownloadService()
        .downloadModelWithFallback('ko', onWaitingForNetwork: waiting.add);
    probeWaiting = true;
    await tick();
    expect(waiting, [true], reason: 'reported once, not on every poll');

    // A screen opened mid-stall learns about it straight away.
    final joined = <bool>[];
    ModelDownloadService().downloadModelWithFallback('ko', onWaitingForNetwork: joined.add);
    expect(joined, [true]);

    probeWaiting = false;
    probeValue = 0.4;
    await tick();
    expect(waiting, [true, false]);

    mlKitDownload.complete();
    await download;
  });
}
