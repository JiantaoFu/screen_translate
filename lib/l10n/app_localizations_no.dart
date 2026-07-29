// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Norwegian (`no`).
class AppLocalizationsNo extends AppLocalizations {
  AppLocalizationsNo([String locale = 'no']) : super(locale);

  @override
  String get app_title => 'Skjermoversettelse';

  @override
  String get source_language => 'Fra';

  @override
  String get target_language => 'Til';

  @override
  String get stop_translation => 'Stopp oversettelse';

  @override
  String get translate_screen => 'Oversett skjerm';

  @override
  String get source_and_target_cannot_be_the_same =>
      'Kilde- og målspråk kan ikke være like';

  @override
  String get manage_translation_models => 'Administrer oversettelsesmodeller';

  @override
  String model_download_success(Object language) {
    return 'Modell for $language er lastet ned';
  }

  @override
  String model_download_error(Object language) {
    return 'Kunne ikke laste ned modell for $language';
  }

  @override
  String get model_not_downloaded => 'Modell ikke lastet ned';

  @override
  String get download_model => 'Last ned';

  @override
  String get remove_translation_model => 'Fjern oversettelsesmodel';

  @override
  String remove_translation_model_confirmation(Object language) {
    return 'Er du sikker på at du vil fjerne oversettelsesmodel for $language?';
  }

  @override
  String get cancel => 'Avbryt';

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
  String get auto_translate_mode => 'Automatisk oversettelse';

  @override
  String get manual_translate_mode => 'Manuell oversettelse';

  @override
  String get original_text_mode => 'Originaltekstmodel';

  @override
  String get overlay_permission_required => 'Oversættelsesmodel';

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
  String get language_belarusian => 'Hviterussisk';

  @override
  String get language_bengali => 'Bengali';

  @override
  String get language_bulgarian => 'Bulgarsk';

  @override
  String get language_catalan => 'Katalansk';

  @override
  String get language_chinese => 'Kinesisk';

  @override
  String get language_croatian => 'Kroatisk';

  @override
  String get language_czech => 'Tsjekkisk';

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
  String get language_galician => 'Galisisk';

  @override
  String get language_georgian => 'Georgisk';

  @override
  String get language_german => 'Tysk';

  @override
  String get language_greek => 'Gresk';

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
  String get language_latvian => 'Latvisk';

  @override
  String get language_lithuanian => 'Litauisk';

  @override
  String get language_macedonian => 'Makedonsk';

  @override
  String get language_malay => 'Malayisk';

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
  String get language_romanian => 'Rumensk';

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
  String get enjoying_app => 'Liker du Screen Translate?';

  @override
  String get review_prompt_message =>
      'Vi vil gjerne høre din mening! Vil du vurdere appen på Google Play?';

  @override
  String get rate_now => 'Vurder nå';

  @override
  String get not_now => 'Ikke nå';

  @override
  String get cannot_open_store => 'Kunne ikke åpne Google Play Store';

  @override
  String get api_key_required => 'API-nøkkel kreves';

  @override
  String get api_key_setup_prompt =>
      'Sett opp din ChatGLM API-nøkkel for AI-oversettelse.';

  @override
  String get go_to_settings => 'Gå til Innstillinger';

  @override
  String get api_key_dialog_title => 'Konfigurasjon av AI-oversettings-API';

  @override
  String get api_key_configuration_title => 'ChatGLM AI-oversettelse';

  @override
  String get api_key_get_key_from =>
      'For å bruke ChatGLM-oversettelser, må du skaffe en gratis API-nøkkel fra ';

  @override
  String get api_key_configuration_steps =>
      'Konfigurasjonstrinn for API-nøkkel';

  @override
  String get api_key_step_1 => '1. Besøk open.bigmodel.cn og opprett en konto';

  @override
  String get api_key_step_2 => '2. Naviger til API-administrasjonsseksjonen';

  @override
  String get api_key_step_3 =>
      '3. Generer en ny API-nøkkel for din applikasjon';

  @override
  String get api_key_input_label => 'ChatGLM API-nøkkel';

  @override
  String get api_key_input_hint => 'Skriv inn din ChatGLM API-nøkkel';

  @override
  String get api_key_input_error => 'Vennligst skriv inn en gyldig API-nøkkel';

  @override
  String get api_key_save_button => 'Lagre API-nøkkel';

  @override
  String get api_key_note =>
      'Din API-nøkkel vil bli lagret sikkert og kun brukt for oversettelsestjenester.';

  @override
  String get api_key_save_error => 'Ugyldig API-nøkkel. Sjekk og prøv igjen.';

  @override
  String get api_key_save_success => 'API-nøkkel lagret vellykket';

  @override
  String get translation_mode_on_device => 'Oversettelse på Enhet';

  @override
  String get translation_mode_on_device_description =>
      'Bruker innebygde oversettelsesmodeller på enheten din. Rask og fungerer frakoblet, men kan ha begrenset språkstøtte og nøyaktighet.';

  @override
  String get translation_mode_ai => 'AI-Oversettelse';

  @override
  String get translation_mode_ai_description =>
      'Bruker avanserte AI-modeller for mer nøyaktige og kontekstuelle oversettelser. Krever internettforbindelse og API-nøkkel.';

  @override
  String get translation_mode_title => 'Oversettelsesmodus';

  @override
  String get translation_mode_on_device_label => 'På Enhet';

  @override
  String get translation_mode_ai_label => 'AI';

  @override
  String get close => 'Lukk';

  @override
  String get translation_settings_title => 'Oversettelsesinnstillinger';

  @override
  String get translation_quality_section => 'OVERSETTELSESKVALITET';

  @override
  String get mode_quick_title => 'Rask';

  @override
  String get mode_quick_subtitle =>
      'Umiddelbar · Alltid tilgjengelig · Ingen oppsett nødvendig';

  @override
  String get mode_ai_enhanced_title => 'AI-forbedret';

  @override
  String get mode_ai_enhanced_subtitle =>
      'Bedre kvalitet · Fungerer offline · Last ned en språkpakke';

  @override
  String get mode_cloud_ai_title => 'Sky-AI';

  @override
  String get mode_cloud_ai_subtitle =>
      'Best kvalitet · Krever internett · API-nøkkel kreves';

  @override
  String language_packs_header(String size) {
    return 'Språkpakker  ·  ~$size hver';
  }

  @override
  String pack_downloading_progress(String percent) {
    return 'Laster ned… $percent%';
  }

  @override
  String get pack_ready_to_use => 'Klar til bruk';

  @override
  String get pack_failed_tap_retry => 'Mislyktes — trykk for å prøve igjen';

  @override
  String get pack_ready_badge => 'Klar';

  @override
  String get retry => 'Prøv igjen';

  @override
  String pack_is_ready_snackbar(String name) {
    return '$name er klar!';
  }

  @override
  String get download_failed_connection =>
      'Nedlasting mislyktes. Sjekk tilkoblingen din.';

  @override
  String get remove_language_pack_title => 'Fjerne språkpakke?';

  @override
  String remove_ai_pack_confirm(String name) {
    return 'Fjerne offline AI-pakken for $name?';
  }

  @override
  String remove_quick_pack_confirm(String name) {
    return 'Fjerne offline hurtigoversettelsespakken for $name?';
  }

  @override
  String get failed_to_remove_pack => 'Kunne ikke fjerne språkpakken.';

  @override
  String get connect_ai_account_title => 'Koble til AI-kontoen din';

  @override
  String get connect_ai_account_prefix => 'Få en gratis API-nøkkel fra ';

  @override
  String get connect_ai_account_suffix => ' og lim den inn nedenfor.';

  @override
  String get api_key_hint_short => 'Lim inn API-nøkkelen din her';

  @override
  String get save_and_verify => 'Lagre og verifiser';

  @override
  String get cloud_ai_connected => 'Tilkoblet! Sky-AI er klar.';

  @override
  String get advanced_section_label => 'Avansert';

  @override
  String get text_merge_sensitivity_title => 'Følsomhet for tekstsammenslåing';

  @override
  String get text_merge_sensitivity_description =>
      'Styrer hvordan nærliggende tekstblokker grupperes. Reduser hvis oversettelsesnøyaktigheten synker.';

  @override
  String get merge_precise => 'Presis';

  @override
  String get merge_aggressive => 'Aggressiv';

  @override
  String get select_language_pair_hint => 'Velg et språkpar';

  @override
  String get download_ai_model_title => 'Laste ned lokal AI-modell?';

  @override
  String get download_ai_model_description =>
      'Denne pakken er vanligvis 100–500 MB. Den lastes ned i bakgrunnen; dette paret vil være klart til bruk så snart det er ferdig.';

  @override
  String error_prefix(String error) {
    return 'Feil: $error';
  }

  @override
  String get translate_image_button => 'Oversett bilde';

  @override
  String get choose_translation_text => 'Velg hvordan du vil oversette tekst';

  @override
  String get download_language_pack_title => 'Last ned en språkpakke';

  @override
  String get download_language_pack_content =>
      'For å bruke AI-forbedret-modus, last ned en språkpakke først.\n\nGå til Innstillinger for å laste ned en.';

  @override
  String get cloud_ai_api_key_required_content =>
      'Sky-AI krever en API-nøkkel. Sett den opp i Innstillinger.';

  @override
  String get mode_ai_short_label => 'AI';

  @override
  String get mode_cloud_short_label => 'Sky';

  @override
  String get image_translation_title => 'Bildeoversettelse';

  @override
  String get send_feedback => 'Send tilbakemelding';

  @override
  String get send_feedback_subtitle =>
      'Rapporter en feil eller foreslå en funksjon';

  @override
  String get ai_pair_unsupported_title => 'Språket støttes ikke ennå';

  @override
  String get ai_pair_unsupported_content =>
      'AI-modus har ennå ikke en modell for dette språkparet. Gi oss beskjed om at du vil ha det — det hjelper oss å bestemme hva vi skal bygge videre.';

  @override
  String get request_language_pair => 'Be om dette språket';

  @override
  String get language_request_sent =>
      'Takk! Vi har registrert forespørselen din.';
}
