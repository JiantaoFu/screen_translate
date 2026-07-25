// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class AppLocalizationsNl extends AppLocalizations {
  AppLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get app_title => 'Schermvertaling';

  @override
  String get source_language => 'Van';

  @override
  String get target_language => 'Naar';

  @override
  String get stop_translation => 'Vertaling stoppen';

  @override
  String get translate_screen => 'Scherm vertalen';

  @override
  String get source_and_target_cannot_be_the_same =>
      'Bron- en doeltaal kunnen niet hetzelfde zijn';

  @override
  String get manage_translation_models => 'Vertaalmodellen beheren';

  @override
  String model_download_success(Object language) {
    return 'Model $language succesvol gedownload';
  }

  @override
  String model_download_error(Object language) {
    return 'Fout bij downloaden van model $language';
  }

  @override
  String get model_not_downloaded => 'Model niet gedownload';

  @override
  String get download_model => 'Downloaden';

  @override
  String get remove_translation_model => 'Vertaalmodel verwijderen';

  @override
  String remove_translation_model_confirmation(Object language) {
    return 'Weet je zeker dat je het vertaalmodel voor $language wilt verwijderen?';
  }

  @override
  String get cancel => 'Annuleren';

  @override
  String get remove => 'Verwijderen';

  @override
  String get not_installed => 'Niet geinstalleerd';

  @override
  String get downloading => 'Downloaden...';

  @override
  String get installed => 'Geinstalleerd';

  @override
  String get download_failed => 'Downloaden mislukt';

  @override
  String failed_to_remove_model(Object language) {
    return 'Fout bij verwijderen van vertaalmodel voor $language';
  }

  @override
  String failed_to_download_model(Object language) {
    return 'Fout bij downloaden van vertaalmodel voor $language';
  }

  @override
  String get auto_translate_mode => 'Automatische vertaling';

  @override
  String get manual_translate_mode => 'Handmatige vertaling';

  @override
  String get original_text_mode => 'Oriënterende tekst';

  @override
  String get overlay_permission_required => 'Vertalingsmode';

  @override
  String get overlay_permission_required_content =>
      'Dit programma heeft vereist om te vertalen op het scherm.';

  @override
  String get grant_permission => 'Geef toestemming';

  @override
  String get language_afrikaans => 'Afrikaans';

  @override
  String get language_albanian => 'Albanees';

  @override
  String get language_arabic => 'Arabisch';

  @override
  String get language_belarusian => 'Wit-Russisch';

  @override
  String get language_bengali => 'Bengaals';

  @override
  String get language_bulgarian => 'Bulgaars';

  @override
  String get language_catalan => 'Catalaans';

  @override
  String get language_chinese => 'Chinees';

  @override
  String get language_croatian => 'Kroatisch';

  @override
  String get language_czech => 'Tsjechisch';

  @override
  String get language_danish => 'Deens';

  @override
  String get language_dutch => 'Nederlands';

  @override
  String get language_english => 'Engels';

  @override
  String get language_esperanto => 'Esperanto';

  @override
  String get language_estonian => 'Estisch';

  @override
  String get language_finnish => 'Fins';

  @override
  String get language_french => 'Frans';

  @override
  String get language_galician => 'Galicisch';

  @override
  String get language_georgian => 'Georgisch';

  @override
  String get language_german => 'Duits';

  @override
  String get language_greek => 'Grieks';

  @override
  String get language_gujarati => 'Gujarati';

  @override
  String get language_haitian => 'Haïtiaans';

  @override
  String get language_hebrew => 'Hebreeuws';

  @override
  String get language_hindi => 'Hindi';

  @override
  String get language_hungarian => 'Hongaars';

  @override
  String get language_icelandic => 'IJslands';

  @override
  String get language_indonesian => 'Indonesisch';

  @override
  String get language_irish => 'Iers';

  @override
  String get language_italian => 'Italiaans';

  @override
  String get language_japanese => 'Japans';

  @override
  String get language_kannada => 'Kannada';

  @override
  String get language_korean => 'Koreaans';

  @override
  String get language_latvian => 'Lets';

  @override
  String get language_lithuanian => 'Litouws';

  @override
  String get language_macedonian => 'Macedonisch';

  @override
  String get language_malay => 'Maleis';

  @override
  String get language_maltese => 'Maltees';

  @override
  String get language_marathi => 'Marathi';

  @override
  String get language_norwegian => 'Noors';

  @override
  String get language_persian => 'Perzisch';

  @override
  String get language_polish => 'Pools';

  @override
  String get language_portuguese => 'Portugees';

  @override
  String get language_romanian => 'Roemeens';

  @override
  String get language_russian => 'Russisch';

  @override
  String get language_slovak => 'Slowaaks';

  @override
  String get language_slovenian => 'Sloveens';

  @override
  String get language_spanish => 'Spaans';

  @override
  String get language_swahili => 'Swahili';

  @override
  String get language_swedish => 'Zweeds';

  @override
  String get language_tagalog => 'Tagalog';

  @override
  String get language_tamil => 'Tamil';

  @override
  String get language_telugu => 'Telugu';

  @override
  String get language_thai => 'Thais';

  @override
  String get language_turkish => 'Turks';

  @override
  String get language_ukrainian => 'Oekraïens';

  @override
  String get language_urdu => 'Urdu';

  @override
  String get language_vietnamese => 'Vietnamees';

  @override
  String get language_welsh => 'Welsh';

  @override
  String get enjoying_app => 'Bevalt Screen Translate je?';

  @override
  String get review_prompt_message =>
      'We zouden graag je mening horen! Wil je de app beoordelen in Google Play?';

  @override
  String get rate_now => 'Nu beoordelen';

  @override
  String get not_now => 'Niet nu';

  @override
  String get cannot_open_store => 'Kan Google Play Store niet openen';

  @override
  String get api_key_required => 'API-sleutel vereist';

  @override
  String get api_key_setup_prompt =>
      'Stel uw ChatGLM API-sleutel in voor AI-vertaling.';

  @override
  String get go_to_settings => 'Ga naar Instellingen';

  @override
  String get api_key_dialog_title => 'Configuratie van AI-vertaling API';

  @override
  String get api_key_configuration_title => 'ChatGLM AI-vertaling';

  @override
  String get api_key_get_key_from =>
      'Om ChatGLM-vertalingen te gebruiken, moet u een gratis API-sleutel verkrijgen van ';

  @override
  String get api_key_configuration_steps =>
      'Configuratiestappen voor API-sleutel';

  @override
  String get api_key_step_1 =>
      '1. Bezoek open.bigmodel.cn en maak een account aan';

  @override
  String get api_key_step_2 => '2. Navigeer naar de API-beheer sectie';

  @override
  String get api_key_step_3 =>
      '3. Genereer een nieuwe API-sleutel voor uw applicatie';

  @override
  String get api_key_input_label => 'ChatGLM API-sleutel';

  @override
  String get api_key_input_hint => 'Voer uw ChatGLM API-sleutel in';

  @override
  String get api_key_input_error => 'Voer een geldige API-sleutel in';

  @override
  String get api_key_save_button => 'API-sleutel opslaan';

  @override
  String get api_key_note =>
      'Uw API-sleutel wordt veilig opgeslagen en alleen gebruikt voor vertaaldiensten.';

  @override
  String get api_key_save_error =>
      'Ongeldige API-sleutel. Controleer en probeer opnieuw.';

  @override
  String get api_key_save_success => 'API-sleutel succesvol opgeslagen';

  @override
  String get translation_mode_on_device => 'Vertaling op Apparaat';

  @override
  String get translation_mode_on_device_description =>
      'Gebruikt ingebouwde vertalingsmodellen op uw apparaat. Snel en werkt offline, maar kan beperkte taalondersteuning en nauwkeurigheid hebben.';

  @override
  String get translation_mode_ai => 'AI-Vertaling';

  @override
  String get translation_mode_ai_description =>
      'Gebruikt geavanceerde AI-modellen voor nauwkeurigere en contextuele vertalingen. Vereist internetverbinding en API-sleutel.';

  @override
  String get translation_mode_title => 'Vertaalmodus';

  @override
  String get translation_mode_on_device_label => 'Op Apparaat';

  @override
  String get translation_mode_ai_label => 'AI';

  @override
  String get close => 'Sluiten';
}
