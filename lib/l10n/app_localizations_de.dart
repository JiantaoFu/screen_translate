// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get app_title => 'Bildschirmübersetzung';

  @override
  String get source_language => 'Von';

  @override
  String get target_language => 'Nach';

  @override
  String get stop_translation => 'Übersetzung stoppen';

  @override
  String get translate_screen => 'Bildschirm übersetzen';

  @override
  String get source_and_target_cannot_be_the_same =>
      'Quell- und Zielsprache können nicht identisch sein';

  @override
  String get manage_translation_models => 'Übersetzungsmodelle verwalten';

  @override
  String model_download_success(Object language) {
    return 'Modell für $language wurde erfolgreich heruntergeladen';
  }

  @override
  String model_download_error(Object language) {
    return 'Fehler beim Herunterladen des Modells für $language';
  }

  @override
  String get model_not_downloaded => 'Modell nicht heruntergeladen';

  @override
  String get download_model => 'Herunterladen';

  @override
  String get remove_translation_model => 'Übersetzungsmodell entfernen';

  @override
  String remove_translation_model_confirmation(Object language) {
    return 'Wollen Sie das Übersetzungsmodell für $language wirklich entfernen?';
  }

  @override
  String get cancel => 'Abbrechen';

  @override
  String get remove => 'Entfernen';

  @override
  String get not_installed => 'Nicht installiert';

  @override
  String get downloading => 'Herunterladen...';

  @override
  String get installed => 'Installiert';

  @override
  String get download_failed => 'Herunterladen fehlgeschlagen';

  @override
  String failed_to_remove_model(Object language) {
    return 'Fehler beim Entfernen des Übersetzungsmodells für $language';
  }

  @override
  String failed_to_download_model(Object language) {
    return 'Fehler beim Herunterladen des Übersetzungsmodells für $language';
  }

  @override
  String get auto_translate_mode => 'Automatische Übersetzung';

  @override
  String get manual_translate_mode => 'Manuelle Übersetzung';

  @override
  String get original_text_mode => 'Originaltextmodell';

  @override
  String get overlay_permission_required => 'Møde kan oversættes på skærmen';

  @override
  String get overlay_permission_required_content =>
      'Dette program bruger tildelinger til at oversætte på skærmen.';

  @override
  String get grant_permission => 'Tildel tildelinger';

  @override
  String get language_afrikaans => 'afrikaans';

  @override
  String get language_albanian => 'albanisch';

  @override
  String get language_arabic => 'arabisch';

  @override
  String get language_belarusian => 'weißrussisch';

  @override
  String get language_bengali => 'bengali';

  @override
  String get language_bulgarian => 'bulgarisch';

  @override
  String get language_catalan => 'katalanisch';

  @override
  String get language_chinese => 'chinesisch';

  @override
  String get language_croatian => 'kroatisch';

  @override
  String get language_czech => 'tschechisch';

  @override
  String get language_danish => 'dänisch';

  @override
  String get language_dutch => 'niederländisch';

  @override
  String get language_english => 'englisch';

  @override
  String get language_esperanto => 'esperanto';

  @override
  String get language_estonian => 'estnisch';

  @override
  String get language_finnish => 'finnisch';

  @override
  String get language_french => 'französisch';

  @override
  String get language_galician => 'galizisch';

  @override
  String get language_georgian => 'georgisch';

  @override
  String get language_german => 'deutsch';

  @override
  String get language_greek => 'griechisch';

  @override
  String get language_gujarati => 'gujarati';

  @override
  String get language_haitian => 'haitianisch';

  @override
  String get language_hebrew => 'hebräisch';

  @override
  String get language_hindi => 'hindi';

  @override
  String get language_hungarian => 'ungarisch';

  @override
  String get language_icelandic => 'isländisch';

  @override
  String get language_indonesian => 'indonesisch';

  @override
  String get language_irish => 'irisch';

  @override
  String get language_italian => 'italienisch';

  @override
  String get language_japanese => 'japanisch';

  @override
  String get language_kannada => 'kannada';

  @override
  String get language_korean => 'koreanisch';

  @override
  String get language_latvian => 'lettisch';

  @override
  String get language_lithuanian => 'litauisch';

  @override
  String get language_macedonian => 'mazedonisch';

  @override
  String get language_malay => 'malaiisch';

  @override
  String get language_maltese => 'maltesisch';

  @override
  String get language_marathi => 'marathi';

  @override
  String get language_norwegian => 'norwegisch';

  @override
  String get language_persian => 'persisch';

  @override
  String get language_polish => 'polnisch';

  @override
  String get language_portuguese => 'portugiesisch';

  @override
  String get language_romanian => 'rumänisch';

  @override
  String get language_russian => 'russisch';

  @override
  String get language_slovak => 'slowakisch';

  @override
  String get language_slovenian => 'slowenisch';

  @override
  String get language_spanish => 'spanisch';

  @override
  String get language_swahili => 'swahili';

  @override
  String get language_swedish => 'schwedisch';

  @override
  String get language_tagalog => 'tagalog';

  @override
  String get language_tamil => 'tamil';

  @override
  String get language_telugu => 'telugu';

  @override
  String get language_thai => 'thailändisch';

  @override
  String get language_turkish => 'türkisch';

  @override
  String get language_ukrainian => 'ukrainisch';

  @override
  String get language_urdu => 'urdu';

  @override
  String get language_vietnamese => 'vietnamesisch';

  @override
  String get language_welsh => 'walisisch';

  @override
  String get enjoying_app => 'Gefällt Ihnen Screen Translate?';

  @override
  String get review_prompt_message =>
      'Wir würden uns über Ihr Feedback freuen! Möchten Sie die App im Google Play Store bewerten?';

  @override
  String get rate_now => 'Jetzt bewerten';

  @override
  String get not_now => 'Nicht jetzt';

  @override
  String get cannot_open_store =>
      'Google Play Store konnte nicht geöffnet werden';

  @override
  String get api_key_required => 'API-Schlüssel erforderlich';

  @override
  String get api_key_setup_prompt =>
      'Bitte richten Sie Ihren ChatGLM-API-Schlüssel ein, um KI-Übersetzung zu verwenden.';

  @override
  String get go_to_settings => 'Zu den Einstellungen';

  @override
  String get api_key_dialog_title => 'KI-Übersetzungs-API-Konfiguration';

  @override
  String get api_key_configuration_title => 'ChatGLM KI-Übersetzung';

  @override
  String get api_key_get_key_from =>
      'Um ChatGLM-Übersetzungen zu nutzen, müssen Sie einen kostenlosen API-Schlüssel von erhalten ';

  @override
  String get api_key_configuration_steps =>
      'API-Schlüssel Konfigurationsschritte';

  @override
  String get api_key_step_1 =>
      '1. Besuchen Sie open.bigmodel.cn und erstellen Sie ein Konto';

  @override
  String get api_key_step_2 => '2. Navigieren Sie zum API-Verwaltungsbereich';

  @override
  String get api_key_step_3 =>
      '3. Generieren Sie einen neuen API-Schlüssel für Ihre Anwendung';

  @override
  String get api_key_input_label => 'ChatGLM API-Schlüssel';

  @override
  String get api_key_input_hint => 'Geben Sie Ihren ChatGLM API-Schlüssel ein';

  @override
  String get api_key_input_error =>
      'Bitte geben Sie einen gültigen API-Schlüssel ein';

  @override
  String get api_key_save_button => 'API-Schlüssel speichern';

  @override
  String get api_key_note =>
      'Ihr API-Schlüssel wird sicher gespeichert und nur für Übersetzungsdienste verwendet.';

  @override
  String get api_key_save_error =>
      'Ungültiger API-Schlüssel. Bitte überprüfen Sie und versuchen Sie es erneut.';

  @override
  String get api_key_save_success => 'API-Schlüssel erfolgreich gespeichert';

  @override
  String get translation_mode_on_device => 'Geräteübersetzung';

  @override
  String get translation_mode_on_device_description =>
      'Verwendet integrierte Übersetzungsmodelle auf Ihrem Gerät. Schnell und offline nutzbar, aber möglicherweise mit begrenzter Sprachunterstützung und Genauigkeit.';

  @override
  String get translation_mode_ai => 'KI-Übersetzung';

  @override
  String get translation_mode_ai_description =>
      'Verwendet fortschrittliche KI-Modelle für genauere und kontextbezogene Übersetzungen. Erfordert Internetverbindung und API-Schlüssel.';

  @override
  String get translation_mode_title => 'Übersetzungsmodus';

  @override
  String get translation_mode_on_device_label => 'Gerät';

  @override
  String get translation_mode_ai_label => 'KI';

  @override
  String get close => 'Schließen';
}
