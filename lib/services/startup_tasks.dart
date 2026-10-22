import 'dart:async';

/// One step of background startup: a name for the log, the work, and the
/// time it is allowed to take.
class StartupTask {
  const StartupTask(
    this.name,
    this.run, {
    this.timeout = const Duration(seconds: 10),
  });

  final String name;
  final Future<void> Function() run;
  final Duration timeout;
}

/// Runs background startup steps in order, each with its own timeout and its
/// own error guard, so one slow or broken step can't take the rest with it.
///
/// This used to be a single try block ending in analytics, with Remote Config
/// just before it on a 10 s budget — shorter than Remote Config's own 20 s
/// fetch timeout. On a slow network Remote Config therefore blew past the
/// budget reliably, and `app_opened`, the activation funnel and the
/// accessibility funnel were never sent for that launch. GA saw `first_open`
/// (sent natively by the Firebase SDK, which doesn't go through here) with
/// nothing after it, which made every funnel denominator wrong.
///
/// The order of the list is the fix: anything that reports the start of a
/// session runs before the steps that can be slow.
Future<void> runStartupTasks(
  List<StartupTask> tasks, {
  void Function(String message)? log,
}) async {
  final write = log ?? print;
  for (final task in tasks) {
    try {
      await task.run().timeout(task.timeout);
      write('Background Services: ${task.name} ok');
    } catch (e) {
      write('Background Services: ${task.name} failed: $e');
    }
  }
}
