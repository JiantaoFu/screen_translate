import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:screen_translate/services/custom_model_manager.dart';
import 'package:screen_translate/services/model_download_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Google's ML Kit download: never finishes (stalled DownloadManager), or
/// throws, depending on [hang].
class _FakeGoogle extends OnDeviceTranslatorModelManager {
  bool hang;
  bool downloaded = false;
  int downloadCalls = 0;
  _FakeGoogle({this.hang = true});

  @override
  Future<bool> downloadModel(String model, {bool isWifiRequired = true}) {
    downloadCalls++;
    if (hang) return Completer<bool>().future;
    return Future.error(Exception('google failed'));
  }

  @override
  Future<bool> isModelDownloaded(String model) async => downloaded;
}

/// The backup server; fails the first [failures] calls.
class _FakeBackup extends CustomModelManager {
  int failures;
  int calls = 0;
  _FakeBackup({this.failures = 0});

  @override
  Future<void> downloadAndInstallModel(String langCode,
      {void Function(double progress)? onProgress}) async {
    calls++;
    if (calls <= failures) throw Exception('backup failed');
    onProgress?.call(1.0);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Future<QuickDownloadReading?> Function(String) originalProbe;
  late Duration originalGoogleTimeout;
  late Duration originalBackoff;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ModelDownloadService.resetQuickStateForTesting();
    originalProbe = ModelDownloadService.quickProgressProbe;
    originalGoogleTimeout = ModelDownloadService.quickGoogleTimeout;
    originalBackoff = ModelDownloadService.quickRetryBackoff;
    ModelDownloadService.quickProgressProbe = (_) async => null;
    ModelDownloadService.quickGoogleTimeout = const Duration(milliseconds: 50);
    ModelDownloadService.quickRetryBackoff = Duration.zero;
  });

  tearDown(() {
    ModelDownloadService.quickProgressProbe = originalProbe;
    ModelDownloadService.quickGoogleTimeout = originalGoogleTimeout;
    ModelDownloadService.quickRetryBackoff = originalBackoff;
    ModelDownloadService.resetQuickStateForTesting();
  });

  test('Quick attempts have no total-duration cap (backup is stall-based)', () {
    expect(ModelDownloadService.quickAttemptTimeout, isNull);
    expect(CustomModelManager().stallTimeout, const Duration(seconds: 30));
  });

  test('a stalled Google download falls through to the backup server', () async {
    final google = _FakeGoogle(hang: true);
    final backup = _FakeBackup();
    await ModelDownloadService.withManagers(google, backup).downloadModelWithFallback('ar');
    expect(google.downloadCalls, 1);
    expect(backup.calls, 1);
    expect(ModelDownloadService.quickDownloadFailed('ar'), isFalse);
  });

  test('after Google fails once, retries go straight to the backup', () async {
    final google = _FakeGoogle(hang: true);
    final backup = _FakeBackup(failures: 2);
    await ModelDownloadService.withManagers(google, backup).downloadModelWithFallback('fa');
    expect(google.downloadCalls, 1, reason: 'Google must not eat 2 minutes per retry');
    expect(backup.calls, 3);
  });

  test('a retry stops early if the model arrived meanwhile', () async {
    final google = _FakeGoogle(hang: false);
    final backup = _FakeBackup(failures: 99);
    // First attempt fails; then Google's background download completes.
    final future = ModelDownloadService.withManagers(google, backup)
        .downloadModelWithFallback('tr', onProgress: (_) {});
    google.downloaded = true;
    await future;
    expect(backup.calls, 1);
  });

  test('a background failure is recorded silently and cleared on the next try', () async {
    final service = ModelDownloadService.withManagers(_FakeGoogle(hang: false), _FakeBackup(failures: 99));
    await expectLater(service.downloadModelWithFallback('he'), throwsA(anything));
    expect(ModelDownloadService.quickDownloadFailed('he'), isTrue);
    expect(ModelDownloadService.quickDownloadFailed('en'), isFalse);

    final ok = ModelDownloadService.withManagers(_FakeGoogle(hang: false), _FakeBackup());
    final retry = ok.downloadModelWithFallback('he');
    expect(ModelDownloadService.quickDownloadFailed('he'), isFalse,
        reason: 'a running retry is not a failure');
    await retry;
    expect(ModelDownloadService.quickDownloadFailed('he'), isFalse);
  });

  test('clearQuickDownloadFailure forgets a recorded failure', () async {
    final service = ModelDownloadService.withManagers(_FakeGoogle(hang: false), _FakeBackup(failures: 99));
    await expectLater(service.downloadModelWithFallback('ur'), throwsA(anything));
    ModelDownloadService.clearQuickDownloadFailure('ur');
    expect(ModelDownloadService.quickDownloadFailed('ur'), isFalse);
  });

  group('backup server download', () {
    final body = List<int>.generate(1000, (i) => i % 256);
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync('backup_test_'));
    tearDown(() => dir.deleteSync(recursive: true));

    /// Serves [body] with Range support. Requests up to [stallUntil] send
    /// half of what they promise and then stall.
    MockClient server(List<String?> ranges, {int stallUntil = 0, Duration chunkDelay = Duration.zero}) {
      var n = 0;
      return MockClient.streaming((request, _) async {
        n++;
        final range = request.headers['range'];
        ranges.add(range);
        final start = range == null ? 0 : int.parse(range.substring(6, range.length - 1));
        final rest = body.sublist(start);
        final controller = StreamController<List<int>>();
        if (n <= stallUntil) {
          controller.add(rest.sublist(0, rest.length ~/ 2));
        } else {
          () async {
            for (var i = 0; i < rest.length; i += 100) {
              await Future<void>.delayed(chunkDelay);
              controller.add(rest.sublist(i, (i + 100).clamp(0, rest.length)));
            }
            await controller.close();
          }();
        }
        return http.StreamedResponse(controller.stream, range == null ? 200 : 206,
            contentLength: rest.length,
            headers: range == null ? {} : {'content-range': 'bytes $start-${body.length - 1}/${body.length}'});
      });
    }

    CustomModelManager manager(MockClient client, {int maxAttempts = 4}) => CustomModelManager(
          clientFactory: () => client,
          cacheDir: () async => dir,
          stallTimeout: const Duration(milliseconds: 100),
          maxAttempts: maxAttempts,
          retryDelay: Duration.zero,
        );

    test('a stalled backup download resumes with a Range request', () async {
      final ranges = <String?>[];
      final zip = await manager(server(ranges, stallUntil: 1)).downloadZip('ar');
      expect(zip.readAsBytesSync(), body);
      expect(ranges, [null, 'bytes=500-']);
    });

    test('the partial file survives a failed call and the next call resumes it', () async {
      final ranges = <String?>[];
      final client = server(ranges, stallUntil: 1);
      await expectLater(manager(client, maxAttempts: 1).downloadZip('fa'), throwsA(anything));
      expect(File('${dir.path}/fa.zip.tmp').lengthSync(), 500);
      final zip = await manager(client, maxAttempts: 1).downloadZip('fa');
      expect(zip.readAsBytesSync(), body);
      expect(ranges, [null, 'bytes=500-']);
    });

    test('slow but steady is never cut off: only a stall fails', () async {
      // 10 chunks 60 ms apart = ~600 ms total, 6x the 100 ms stall timeout.
      final ranges = <String?>[];
      final zip = await manager(server(ranges, chunkDelay: const Duration(milliseconds: 60)), maxAttempts: 1)
          .downloadZip('tr');
      expect(zip.readAsBytesSync(), body);
      expect(ranges, [null]);
    });
  });
}
