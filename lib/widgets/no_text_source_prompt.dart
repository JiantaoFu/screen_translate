import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:screen_translate/services/activation_tracker.dart';

/// Languages offered when a session found no text at all. Labels are each
/// language's own name so they read the same on every device locale.
const noTextSourceChoices = <String, String>{
  'ja': '日本語',
  'ko': '한국어',
  'zh': '中文',
  'en': 'English',
};

const prefNoTextPromptCount = 'no_text_source_prompt_count';

/// How many times the prompt may appear before the user gets a translation.
const noTextPromptMaxShows = 3;

/// Whether to offer other source languages: the session OCR'd frames but
/// found no text at all, and this install has not translated anything yet
/// (only the first sessions — later the user already knows the app works).
Future<bool> shouldOfferSourceLanguages({required bool sessionFoundNoText}) async {
  if (!sessionFoundNoText) return false;
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getBool(ActivationTracker.prefFirstTranslationLogged) ?? false) return false;
  return (prefs.getInt(prefNoTextPromptCount) ?? 0) < noTextPromptMaxShows;
}

/// One-line "No text found" prompt with a button per likely source language.
/// The target language is left out (translating ja→ja would show nothing).
/// Returns the language code tapped, or null when dismissed.
Future<String?> showNoTextSourcePrompt(BuildContext context,
    {required String currentSource, String? targetLanguage}) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(prefNoTextPromptCount, (prefs.getInt(prefNoTextPromptCount) ?? 0) + 1);
  if (!context.mounted) return null;
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      key: const Key('no_text_source_prompt'),
      content: const Text('No text found. Try another source language?'),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          children: [
            for (final e in noTextSourceChoices.entries)
              if (e.key != targetLanguage)
                OutlinedButton(
                key: Key('no_text_source_${e.key}'),
                onPressed: () => Navigator.pop(dialogContext, e.key),
                child: Text(e.value),
              ),
          ],
        ),
      ],
    ),
  );
}
