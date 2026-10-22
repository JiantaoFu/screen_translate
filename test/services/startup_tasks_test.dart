import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:screen_translate/services/startup_tasks.dart';

void main() {
  late List<String> ran;
  late List<String> log;

  setUp(() {
    ran = [];
    log = [];
  });

  StartupTask ok(String name) => StartupTask(name, () async => ran.add(name));

  test('runs the steps in order', () async {
    await runStartupTasks([ok('a'), ok('b'), ok('c')], log: log.add);

    expect(ran, ['a', 'b', 'c']);
    expect(log, [
      'Background Services: a ok',
      'Background Services: b ok',
      'Background Services: c ok',
    ]);
  });

  test('a step that throws does not stop the ones after it', () async {
    await runStartupTasks([
      ok('a'),
      StartupTask('boom', () async => throw StateError('nope')),
      ok('c'),
    ], log: log.add);

    expect(ran, ['a', 'c']);
    expect(log[1], contains('boom failed'));
  });

  test('a step that hangs is cut off at its own timeout and the rest still run',
      () async {
    await runStartupTasks([
      StartupTask(
        'hang',
        () => Completer<void>().future,
        timeout: const Duration(milliseconds: 20),
      ),
      ok('after'),
    ], log: log.add);

    expect(ran, ['after']);
    expect(log.first, contains('hang failed'));
  });

  test('a step is left alone until its own timeout', () async {
    await runStartupTasks([
      StartupTask(
        'slow',
        () => Future.delayed(const Duration(milliseconds: 30), () => ran.add('slow')),
        timeout: const Duration(milliseconds: 300),
      ),
    ], log: log.add);

    expect(ran, ['slow']);
    expect(log, ['Background Services: slow ok']);
  });

  test('every step gets its own budget, not one shared deadline', () async {
    final started = <String>[];
    await runStartupTasks([
      StartupTask(
        'first',
        () => Future.delayed(const Duration(milliseconds: 30), () => started.add('first')),
        timeout: const Duration(milliseconds: 200),
      ),
      StartupTask(
        'second',
        () => Future.delayed(const Duration(milliseconds: 30), () => started.add('second')),
        timeout: const Duration(milliseconds: 200),
      ),
    ], log: log.add);

    expect(started, ['first', 'second']);
    expect(log, [
      'Background Services: first ok',
      'Background Services: second ok',
    ]);
  });
}
