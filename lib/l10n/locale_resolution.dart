import 'dart:ui';

import 'package:screen_translate/l10n/app_localizations.dart';

/// Android reports some languages under codes that differ from the ones
/// our translations use: Norwegian is usually "nb" (Bokmål), and older
/// devices use the legacy "iw" for Hebrew and "in" for Indonesian.
const _languageAliases = {'nb': 'no', 'nn': 'no', 'iw': 'he', 'in': 'id'};

/// Picks the app language for the device language: its translation if we
/// have one, English otherwise.
///
/// Returning the device locale unchanged (as this app once did) left
/// AppLocalizations unloaded for any language without a translation, and
/// every `AppLocalizations.of(context)!` then crashed the home screen.
Locale resolveAppLocale(Locale? device, Iterable<Locale> supported) {
  if (device != null) {
    final code = _languageAliases[device.languageCode] ?? device.languageCode;
    for (final locale in supported) {
      if (locale.languageCode == code) return locale;
    }
  }
  return const Locale('en');
}

/// Localized strings for code with no BuildContext (e.g. services), in the
/// same language the UI resolves to.
AppLocalizations deviceAppLocalizations() => lookupAppLocalizations(
      resolveAppLocale(PlatformDispatcher.instance.locale, AppLocalizations.supportedLocales),
    );
