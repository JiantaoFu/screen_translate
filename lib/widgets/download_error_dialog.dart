import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:screen_translate/l10n/app_localizations.dart';
import 'package:screen_translate/providers/translation_provider.dart';
import 'package:screen_translate/services/feedback_email_service.dart';
import 'package:screen_translate/services/llm_translation_service.dart';

/// Result of [showDownloadFailedDialog].
enum DownloadFailedAction { retry, switchToCloudAi, dismiss }

/// Engine name as it appears in feedback emails.
String feedbackEngineLabel(TranslationMode mode) => switch (mode) {
      TranslationMode.onDevice => 'Quick (ML Kit offline)',
      TranslationMode.onnx => 'AI (ONNX offline)',
      TranslationMode.llm => 'Cloud AI (LLM)',
    };

/// Opens the mail app with a feedback email prefilled with diagnostics
/// (app version, device, Android version/SDK, engine, language pair).
/// Shows the support address if no email app is installed.
Future<void> sendFeedbackEmail(BuildContext context) async {
  final localizations = AppLocalizations.of(context)!;
  final provider = Provider.of<TranslationProvider>(context, listen: false);
  final messenger = ScaffoldMessenger.maybeOf(context);
  final opened = await FeedbackEmailService().send(
    subject: localizations.send_feedback,
    engine: feedbackEngineLabel(provider.translationMode),
    languagePair: '${provider.sourceLanguage} → ${provider.targetLanguage}',
  );
  if (!opened) {
    messenger?.showSnackBar(const SnackBar(content: Text(kSupportEmail)));
  }
}

/// Clear error dialog after language-pack download retries are exhausted.
/// Offers Retry, one-tap switch to Cloud AI (LLM), and Send feedback.
Future<DownloadFailedAction> showDownloadFailedDialog(
  BuildContext context, {
  required String packLabel,
}) async {
  final localizations = AppLocalizations.of(context)!;
  final result = await showDialog<DownloadFailedAction>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      title: Text(localizations.download_failed_title),
      content: Text(localizations.download_failed_body(packLabel)),
      actions: [
        TextButton(
          onPressed: () => sendFeedbackEmail(context),
          child: Text(localizations.send_feedback_by_email),
        ),
        TextButton(
          onPressed: () =>
              Navigator.pop(dialogContext, DownloadFailedAction.switchToCloudAi),
          child: Text(localizations.switch_to_cloud_ai),
        ),
        TextButton(
          onPressed: () =>
              Navigator.pop(dialogContext, DownloadFailedAction.retry),
          child: Text(localizations.retry),
        ),
      ],
    ),
  );
  return result ?? DownloadFailedAction.dismiss;
}

/// Switches to Cloud AI in one tap when an API key is already saved.
/// Without a key, explains that one is needed and, if [openSettings] is
/// given, offers to open Settings where the key is entered.
Future<void> switchToCloudAi(
  BuildContext context, {
  VoidCallback? openSettings,
}) async {
  final localizations = AppLocalizations.of(context)!;
  final provider = Provider.of<TranslationProvider>(context, listen: false);
  final messenger = ScaffoldMessenger.maybeOf(context);
  final hasApiKey = await LLMTranslationService.isApiKeyConfigured();
  if (!context.mounted) return;
  if (hasApiKey) {
    provider.setTranslationMode(TranslationMode.llm);
    messenger?.showSnackBar(
      SnackBar(content: Text(localizations.cloud_ai_connected), backgroundColor: Colors.green),
    );
    return;
  }
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(localizations.connect_ai_account_title),
      content: Text(localizations.cloud_ai_api_key_required_content),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(localizations.cancel),
        ),
        if (openSettings != null)
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              openSettings();
            },
            child: Text(localizations.go_to_settings),
          ),
      ],
    ),
  );
}
