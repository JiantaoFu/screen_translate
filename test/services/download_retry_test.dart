import 'package:flutter_test/flutter_test.dart';
import 'package:screen_translate/services/download_retry.dart';

void main() {
  test('succeeds on the first attempt without sleeping', () async {
    var calls = 0;
    final sleeps = <Duration>[];
    final result = await withRetries(() async {
      calls++;
      return 42;
    }, sleep: (d) async => sleeps.add(d));
    expect(result, 42);
    expect(calls, 1);
    expect(sleeps, isEmpty);
  });

  test('retries twice with exponential backoff then succeeds', () async {
    var calls = 0;
    final sleeps = <Duration>[];
    final failures = <int>[];
    final result = await withRetries(() async {
      calls++;
      if (calls < 3) throw Exception('fail $calls');
      return 'ok';
    },
        maxRetries: 2,
        initialBackoff: const Duration(seconds: 2),
        sleep: (d) async => sleeps.add(d),
        onAttemptFailed: (a, _) => failures.add(a));
    expect(result, 'ok');
    expect(calls, 3);
    expect(sleeps, [const Duration(seconds: 2), const Duration(seconds: 4)]);
    expect(failures, [1, 2]);
  });

  test('a timeout counts as a failure and is retried', () async {
    var calls = 0;
    final result = await withRetries(() async {
      calls++;
      if (calls == 1) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return 'late';
      }
      return 'ok';
    },
        maxRetries: 2,
        attemptTimeout: const Duration(milliseconds: 10),
        initialBackoff: Duration.zero,
        sleep: (_) async {});
    expect(result, 'ok');
    expect(calls, 2);
  });

  test('throws the last error after exhausting retries', () async {
    var calls = 0;
    await expectLater(
      withRetries(() async {
        calls++;
        throw Exception('boom $calls');
      }, maxRetries: 2, initialBackoff: Duration.zero, sleep: (_) async {}),
      throwsA(isA<Exception>().having((e) => e.toString(), 'msg', contains('boom 3'))),
    );
    expect(calls, 3);
  });
}
