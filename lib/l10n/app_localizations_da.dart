// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Danish (`da`).
class AppLocalizationsDa extends AppLocalizations {
  AppLocalizationsDa([String locale = 'da']) : super(locale);

  @override
  String get app_title => 'Skærmoversættelse';

  @override
  String get source_language => 'Fra';

  @override
  String get target_language => 'Til';

  @override
  String get stop_translation => 'Stop oversættelse';

  @override
  String get translate_screen => 'Oversæt skærm';

  @override
  String get source_and_target_cannot_be_the_same =>
      'Kilde- og målsprog kan ikke være ens';

  @override
  String get manage_translation_models => 'Administrer oversættelsesmodeller';

  @override
  String model_download_success(Object language) {
    return 'Model for $language er blevet downloadet';
  }

  @override
  String model_download_error(Object language) {
    return 'Fejl under download af model for $language';
  }

  @override
  String get model_not_downloaded => 'Model ikke downloadet';

  @override
  String get download_model => 'Download';

  @override
  String get remove_translation_model => 'Fjern oversættelsesmodel';

  @override
  String remove_translation_model_confirmation(Object language) {
    return 'Er du sikker paa at du vil fjerne oversættelsesmodel for $language?';
  }

  @override
  String get cancel => 'Annuller';

  @override
  String get remove => 'Fjern';

  @override
  String get not_installed => 'Ikke installert';

  @override
  String get downloading => 'Henter...';

  @override
  String get installed => 'Installert';

  @override
  String get download_failed => 'Download feilet';

  @override
  String failed_to_remove_model(Object language) {
    return 'Feilet at slette model for $language';
  }

  @override
  String failed_to_download_model(Object language) {
    return 'Feilet at hente model for $language';
  }

  @override
  String get auto_translate_mode => 'Automatisk oversættelse';

  @override
  String get manual_translate_mode => 'Manuel oversættelse';

  @override
  String get original_text_mode => 'Originaltekstmodel';

  @override
  String get overlay_permission_required => 'Møde kan oversættes på skærmen';

  @override
  String get overlay_permission_required_content =>
      'Dette program bruger tildelinger til at oversætte på skærmen.';

  @override
  String get grant_permission => 'Tildel tildelinger';

  @override
  String get language_afrikaans => 'Afrikaans';

  @override
  String get language_albanian => 'Albansk';

  @override
  String get language_arabic => 'Arabisk';

  @override
  String get language_belarusian => 'Hviderussisk';

  @override
  String get language_bengali => 'Bengalsk';

  @override
  String get language_bulgarian => 'Bulgarsk';

  @override
  String get language_catalan => 'Catalansk';

  @override
  String get language_chinese => 'Kinesisk';

  @override
  String get language_croatian => 'Kroatisk';

  @override
  String get language_czech => 'Tjekkisk';

  @override
  String get language_danish => 'Dansk';

  @override
  String get language_dutch => 'Nederlandsk';

  @override
  String get language_english => 'Engelsk';

  @override
  String get language_esperanto => 'Esperanto';

  @override
  String get language_estonian => 'Estisk';

  @override
  String get language_finnish => 'Finsk';

  @override
  String get language_french => 'Fransk';

  @override
  String get language_galician => 'Galicisk';

  @override
  String get language_georgian => 'Georgisk';

  @override
  String get language_german => 'Tysk';

  @override
  String get language_greek => 'Græsk';

  @override
  String get language_gujarati => 'Gujarati';

  @override
  String get language_haitian => 'Haitisk';

  @override
  String get language_hebrew => 'Hebraisk';

  @override
  String get language_hindi => 'Hindi';

  @override
  String get language_hungarian => 'Ungarsk';

  @override
  String get language_icelandic => 'Islandsk';

  @override
  String get language_indonesian => 'Indonesisk';

  @override
  String get language_irish => 'Irsk';

  @override
  String get language_italian => 'Italiensk';

  @override
  String get language_japanese => 'Japansk';

  @override
  String get language_kannada => 'Kannada';

  @override
  String get language_korean => 'Koreansk';

  @override
  String get language_latvian => 'Lettisk';

  @override
  String get language_lithuanian => 'Litauisk';

  @override
  String get language_macedonian => 'Makedonsk';

  @override
  String get language_malay => 'Malaysisk';

  @override
  String get language_maltese => 'Maltesisk';

  @override
  String get language_marathi => 'Marathi';

  @override
  String get language_norwegian => 'Norsk';

  @override
  String get language_persian => 'Persisk';

  @override
  String get language_polish => 'Polsk';

  @override
  String get language_portuguese => 'Portugisisk';

  @override
  String get language_romanian => 'Rumænsk';

  @override
  String get language_russian => 'Russisk';

  @override
  String get language_slovak => 'Slovakisk';

  @override
  String get language_slovenian => 'Slovensk';

  @override
  String get language_spanish => 'Spansk';

  @override
  String get language_swahili => 'Swahili';

  @override
  String get language_swedish => 'Svensk';

  @override
  String get language_tagalog => 'Tagalog';

  @override
  String get language_tamil => 'Tamil';

  @override
  String get language_telugu => 'Telugu';

  @override
  String get language_thai => 'Thai';

  @override
  String get language_turkish => 'Tyrkisk';

  @override
  String get language_ukrainian => 'Ukrainsk';

  @override
  String get language_urdu => 'Urdu';

  @override
  String get language_vietnamese => 'Vietnamesisk';

  @override
  String get language_welsh => 'Walisisk';

  @override
  String get enjoying_app => 'Kan du lide Screen Translate?';

  @override
  String get review_prompt_message =>
      'Vi vil gerne høre din mening! Vil du bedømme appen på Google Play?';

  @override
  String get rate_now => 'Bedøm nu';

  @override
  String get not_now => 'Ikke nu';

  @override
  String get cannot_open_store => 'Kunne ikke åbne Google Play Store';

  @override
  String get api_key_required => 'API-nøgle påkrævet';

  @override
  String get api_key_setup_prompt =>
      'Konfigurer din ChatGLM API-nøgle til AI-oversættelse.';

  @override
  String get go_to_settings => 'Gå til Indstillinger';

  @override
  String get api_key_dialog_title => 'Konfiguration af AI-oversættelses-API';

  @override
  String get api_key_configuration_title => 'ChatGLM AI-oversættelse';

  @override
  String get api_key_get_key_from =>
      'For at bruge ChatGLM-oversættelser skal du skaffe en gratis API-nøgle fra ';

  @override
  String get api_key_configuration_steps => 'Konfigurationstrin for API-nøgle';

  @override
  String get api_key_step_1 => '1. Besøg open.bigmodel.cn og opret en konto';

  @override
  String get api_key_step_2 => '2. Naviger til API-administrationssektionen';

  @override
  String get api_key_step_3 => '3. Generer en ny API-nøgle til din applikation';

  @override
  String get api_key_input_label => 'ChatGLM API-nøgle';

  @override
  String get api_key_input_hint => 'Indtast din ChatGLM API-nøgle';

  @override
  String get api_key_input_error => 'Indtast venligst en gyldig API-nøgle';

  @override
  String get api_key_save_button => 'Gem API-nøgle';

  @override
  String get api_key_note =>
      'Din API-nøgle vil blive gemt sikkert og kun bruges til oversættelsestjenester.';

  @override
  String get api_key_save_error =>
      'Ugyldig API-nøgle. Kontroller og prøv igen.';

  @override
  String get api_key_save_success => 'API-nøgle gemt succesfuldt';

  @override
  String get translation_mode_on_device => 'Oversættelse på Enhed';

  @override
  String get translation_mode_on_device_description =>
      'Bruger integrerede oversættelsesmodeller på din enhed. Hurtig og fungerer offline, men kan have begrænset sprogstøtte og nøjagtighed.';

  @override
  String get translation_mode_ai => 'AI-Oversættelse';

  @override
  String get translation_mode_ai_description =>
      'Bruger avancerede AI-modeller til mere præcise og kontekstuelle oversættelser. Kræver internetforbindelse og API-nøgle.';

  @override
  String get translation_mode_title => 'Oversættelsestilstand';

  @override
  String get translation_mode_on_device_label => 'På Enhed';

  @override
  String get translation_mode_ai_label => 'AI';

  @override
  String get close => 'Luk';
}
