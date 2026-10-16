import 'package:flutter/material.dart';
import 'package:screen_translate/l10n/app_localizations.dart';
import 'package:screen_translate/services/activation_tracker.dart';
import 'package:screen_translate/widgets/download_error_dialog.dart' show sendFeedbackEmail;

/// One-tap "what went wrong?" after the first live session that translated
/// nothing. Shown once per install: that session is the one that decides
/// whether the buyer refunds, and a tap costs less than writing an email.
/// Closing the dialog counts as `skipped`; "Send feedback by email" as `other`.
///
/// Returns the reason that was reported, or null when it was not asked
/// (already asked on this install).
Future<String?> showFirstFailureFeedback(
  BuildContext context, {
  ActivationTracker? tracker,
}) async {
  final activation = tracker ?? ActivationTracker.instance;
  if (!await activation.claimFailureFeedback()) return null;
  if (!context.mounted) return null;

  final localizations = AppLocalizations.of(context)!;
  final reason = await showDialog<String>(
    context: context,
    builder: (dialogContext) {
      Widget reasonButton(String reason, String label) => SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(dialogContext, reason),
              child: Text(label, textAlign: TextAlign.center),
            ),
          );
      return AlertDialog(
        // Long translations on a small screen would overflow otherwise.
        scrollable: true,
        title: Text(localizations.first_failure_title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            reasonButton('no_text', localizations.first_failure_no_text),
            reasonButton('wrong', localizations.first_failure_wrong),
            reasonButton('slow', localizations.first_failure_slow),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, 'skipped'),
            child: Text(localizations.close),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, 'other'),
            child: Text(localizations.send_feedback_by_email),
          ),
        ],
      );
    },
  );

  // Dismissing by tapping outside or Back is the same as Close.
  final answer = reason ?? 'skipped';
  activation.failureFeedback(answer);
  if (answer == 'other' && context.mounted) {
    await sendFeedbackEmail(context);
  }
  return answer;
}
