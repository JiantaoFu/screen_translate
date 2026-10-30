import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';

/// The lead-in to Android's MediaProjection consent dialog.
///
/// That system dialog says the app will capture "everything that's displayed
/// on your screen" and, on Android 14+, lists passwords, photos, messages and
/// payment information. Shown cold it reads as a threat, and the first-use
/// funnel showed exactly that: in the paid app the overlay permission — which
/// this app explains in its own dialog before sending the user to Settings —
/// was granted by 16 of 16 users, while the capture consent, asked two lines
/// of code later with no lead-in, was granted by 13 of 18. Same people, same
/// Start, the only difference being whether anything had explained why.
///
/// So this says why, and answers the system wording head on: only text, on
/// device, nothing uploaded or kept, stop whenever.
///
/// Shown until a capture consent has actually been granted once. After that
/// the user knows what the system dialog is for, and a second explanation is
/// just another tap between them and a translation.
class ScreenCaptureConsent {
  const ScreenCaptureConsent._();

  /// Set the first time Android's consent is granted on this install.
  static const prefGrantedOnce = 'capture_consent_granted_once';

  static Future<SharedPreferences> Function() prefs = SharedPreferences.getInstance;

  /// Whether to explain before asking. Never throws: if prefs are unreadable
  /// we explain, which costs a tap, rather than skip, which costs the grant.
  static Future<bool> shouldExplain() async {
    try {
      return !((await prefs()).getBool(prefGrantedOnce) ?? false);
    } catch (_) {
      return true;
    }
  }

  static Future<void> markGranted() async {
    try {
      await (await prefs()).setBool(prefGrantedOnce, true);
    } catch (_) {}
  }

  /// The lead-in. True if the user wants to go on to the system dialog.
  static Future<bool> explain(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.screen_capture_permission_required),
        content: Text(l.screen_capture_permission_required_content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.grant_permission),
          ),
        ],
      ),
    );
    return proceed ?? false;
  }

  /// After a denied or cancelled system dialog. A six-second snackbar used to
  /// carry this, which is no time at all to read a sentence and decide, and it
  /// left the user with nothing to tap. True if they want to try again.
  static Future<bool> offerRetry(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    final retry = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.screen_capture_permission_required),
        content: Text(l.screen_capture_not_granted),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.retry),
          ),
        ],
      ),
    );
    return retry ?? false;
  }
}
