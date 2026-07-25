// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Swedish (`sv`).
class AppLocalizationsSv extends AppLocalizations {
  AppLocalizationsSv([String locale = 'sv']) : super(locale);

  @override
  String get app_title => 'Skärmöversättning';

  @override
  String get source_language => 'Från';

  @override
  String get target_language => 'Till';

  @override
  String get stop_translation => 'Stoppa översättning';

  @override
  String get translate_screen => 'Översätt skärm';

  @override
  String get source_and_target_cannot_be_the_same =>
      'Käll- och målspråk kan inte vara samma';

  @override
  String get manage_translation_models => 'Hantera översättningsmodeller';

  @override
  String model_download_success(Object language) {
    return 'Modell för $language har laddats ned';
  }

  @override
  String model_download_error(Object language) {
    return 'Fel vid nedladdning av modell för $language';
  }

  @override
  String get model_not_downloaded => 'Modell inte nedladdad';

  @override
  String get download_model => 'Ladda ned';

  @override
  String get remove_translation_model => 'Färga översättningsmodell';

  @override
  String remove_translation_model_confirmation(Object language) {
    return 'Vill du verkligen färga översättningsmodell för $language?';
  }

  @override
  String get cancel => 'Avbryt';

  @override
  String get remove => 'Färga';

  @override
  String get not_installed => 'Inte installerat';

  @override
  String get downloading => 'Nedladdning...';

  @override
  String get installed => 'Installerat';

  @override
  String get download_failed => 'Nedladdning av modell misslyckades';

  @override
  String failed_to_remove_model(Object language) {
    return 'Misslyckades att ta bort modell för $language';
  }

  @override
  String failed_to_download_model(Object language) {
    return 'Misslyckades att ladda ner modell för $language';
  }

  @override
  String get auto_translate_mode => 'Automatisk översättning';

  @override
  String get manual_translate_mode => 'Manuell översättning';

  @override
  String get original_text_mode => 'Originaltextmodell';

  @override
  String get overlay_permission_required => 'Översättningsmodell';

  @override
  String get overlay_permission_required_content =>
      'Denna programkrav dobbelklickar på skärm förstärkning';

  @override
  String get grant_permission => 'Giv tillräckliga tillräckliga';

  @override
  String get language_afrikaans => 'Afrikaans';

  @override
  String get language_albanian => 'Albanska';

  @override
  String get language_arabic => 'Arabiska';

  @override
  String get language_belarusian => 'Vitryska';

  @override
  String get language_bengali => 'Bengali';

  @override
  String get language_bulgarian => 'Bulgariska';

  @override
  String get language_catalan => 'Katalanska';

  @override
  String get language_chinese => 'Kinesiska';

  @override
  String get language_croatian => 'Kroatiska';

  @override
  String get language_czech => 'Tjeckiska';

  @override
  String get language_danish => 'Danska';

  @override
  String get language_dutch => 'Nederländska';

  @override
  String get language_english => 'Engelska';

  @override
  String get language_esperanto => 'Esperanto';

  @override
  String get language_estonian => 'Estniska';

  @override
  String get language_finnish => 'Finska';

  @override
  String get language_french => 'Franska';

  @override
  String get language_galician => 'Galiciska';

  @override
  String get language_georgian => 'Georgiska';

  @override
  String get language_german => 'Tyska';

  @override
  String get language_greek => 'Grekiska';

  @override
  String get language_gujarati => 'Gujarati';

  @override
  String get language_haitian => 'Haitiska';

  @override
  String get language_hebrew => 'Hebreiska';

  @override
  String get language_hindi => 'Hindi';

  @override
  String get language_hungarian => 'Ungerska';

  @override
  String get language_icelandic => 'Isländska';

  @override
  String get language_indonesian => 'Indonesiska';

  @override
  String get language_irish => 'Iriska';

  @override
  String get language_italian => 'Italienska';

  @override
  String get language_japanese => 'Japanska';

  @override
  String get language_kannada => 'Kannada';

  @override
  String get language_korean => 'Koreanska';

  @override
  String get language_latvian => 'Lettiska';

  @override
  String get language_lithuanian => 'Litauiska';

  @override
  String get language_macedonian => 'Makedonska';

  @override
  String get language_malay => 'Malajiska';

  @override
  String get language_maltese => 'Maltesiska';

  @override
  String get language_marathi => 'Marathi';

  @override
  String get language_norwegian => 'Norska';

  @override
  String get language_persian => 'Persiska';

  @override
  String get language_polish => 'Polska';

  @override
  String get language_portuguese => 'Portugisiska';

  @override
  String get language_romanian => 'Rumänska';

  @override
  String get language_russian => 'Ryska';

  @override
  String get language_slovak => 'Slovakiska';

  @override
  String get language_slovenian => 'Slovenska';

  @override
  String get language_spanish => 'Spanska';

  @override
  String get language_swahili => 'Swahili';

  @override
  String get language_swedish => 'Svenska';

  @override
  String get language_tagalog => 'Tagalog';

  @override
  String get language_tamil => 'Tamil';

  @override
  String get language_telugu => 'Telugu';

  @override
  String get language_thai => 'Thailändska';

  @override
  String get language_turkish => 'Turkiska';

  @override
  String get language_ukrainian => 'Ukrainska';

  @override
  String get language_urdu => 'Urdu';

  @override
  String get language_vietnamese => 'Vietnamesiska';

  @override
  String get language_welsh => 'Walesiska';

  @override
  String get enjoying_app => 'Gillar du Screen Translate?';

  @override
  String get review_prompt_message =>
      'Vi skulle gärna höra din åsikt! Vill du betygsätta appen på Google Play?';

  @override
  String get rate_now => 'Betygsätt nu';

  @override
  String get not_now => 'Inte nu';

  @override
  String get cannot_open_store => 'Kunde inte öppna Google Play Store';

  @override
  String get api_key_required => 'API-nyckel krävs';

  @override
  String get api_key_setup_prompt =>
      'Konfigurera din ChatGLM API-nyckel för AI-översättning.';

  @override
  String get go_to_settings => 'Gå till Inställningar';

  @override
  String get api_key_dialog_title => 'Konfiguration av AI-översättnings-API';

  @override
  String get api_key_configuration_title => 'ChatGLM AI-översättning';

  @override
  String get api_key_get_key_from =>
      'För att använda ChatGLM-översättningar måste du skaffa en gratis API-nyckel från ';

  @override
  String get api_key_configuration_steps => 'Konfigurationssteg för API-nyckel';

  @override
  String get api_key_step_1 => '1. Besök open.bigmodel.cn och skapa ett konto';

  @override
  String get api_key_step_2 => '2. Navigera till API-hanteringssektionen';

  @override
  String get api_key_step_3 =>
      '3. Generera en ny API-nyckel för din applikation';

  @override
  String get api_key_input_label => 'ChatGLM API-nyckel';

  @override
  String get api_key_input_hint => 'Ange din ChatGLM API-nyckel';

  @override
  String get api_key_input_error => 'Ange en giltig API-nyckel';

  @override
  String get api_key_save_button => 'Spara API-nyckel';

  @override
  String get api_key_note =>
      'Din API-nyckel kommer att lagras säkert och användas endast för översättningstjänster.';

  @override
  String get api_key_save_error =>
      'Ogiltig API-nyckel. Kontrollera och försök igen.';

  @override
  String get api_key_save_success => 'API-nyckel sparad framgångsrikt';

  @override
  String get translation_mode_on_device => 'Översättning på Enheten';

  @override
  String get translation_mode_on_device_description =>
      'Använder inbyggda översättningsmodeller på din enhet. Snabb och fungerar offline, men kan ha begränsat språkstöd och precision.';

  @override
  String get translation_mode_ai => 'AI-Översättning';

  @override
  String get translation_mode_ai_description =>
      'Använder avancerade AI-modeller för mer exakta och kontextuella översättningar. Kräver internetanslutning och API-nyckel.';

  @override
  String get translation_mode_title => 'Översättningsläge';

  @override
  String get translation_mode_on_device_label => 'På Enheten';

  @override
  String get translation_mode_ai_label => 'AI';

  @override
  String get close => 'Stäng';
}
