// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Estonian (`et`).
class AppLocalizationsEt extends AppLocalizations {
  AppLocalizationsEt([String locale = 'et']) : super(locale);

  @override
  String get app_title => 'Ekraani tõlkimine';

  @override
  String get source_language => 'Lähtekeel';

  @override
  String get target_language => 'Sihtkeel';

  @override
  String get stop_translation => 'Peata tõlkimine';

  @override
  String get translate_screen => 'Tõlgi ekraan';

  @override
  String get source_and_target_cannot_be_the_same =>
      'Lähte- ja sihtkeel ei saa olla samad';

  @override
  String get manage_translation_models => 'Halda tõlkemudeleid';

  @override
  String model_download_success(Object language) {
    return 'Mudel keelele $language on edukalt alla laaditud';
  }

  @override
  String model_download_error(Object language) {
    return 'Viga mudeli allalaadimisel keelele $language';
  }

  @override
  String get model_not_downloaded => 'Mudel pole alla laaditud';

  @override
  String get download_model => 'Laadi alla';

  @override
  String get remove_translation_model => 'Otsi tõlkemudel';

  @override
  String remove_translation_model_confirmation(Object language) {
    return 'Opravdu chcete odstranit překladový model pro jazyk $language?';
  }

  @override
  String get cancel => 'Zrusit';

  @override
  String get remove => 'Odebrat';

  @override
  String get not_installed => 'Neni nainstalovan';

  @override
  String get downloading => 'Stahovani...';

  @override
  String get installed => 'Nainstalovan';

  @override
  String get download_failed => 'Nelze stahnout';

  @override
  String failed_to_remove_model(Object language) {
    return 'Nelze odstranit model pro jazyk $language';
  }

  @override
  String failed_to_download_model(Object language) {
    return 'Nelze stahnout model pro jazyk $language';
  }

  @override
  String get auto_translate_mode => 'Automatizm';

  @override
  String get manual_translate_mode => 'Traduce manual';

  @override
  String get original_text_mode => 'Text original';

  @override
  String get overlay_permission_required => 'Permission requise';

  @override
  String get overlay_permission_required_content =>
      'Ce programme requiert des permissions pour traduire à l\'écran.';

  @override
  String get grant_permission => 'Accorder les permissions';

  @override
  String get language_afrikaans => 'afrikaans';

  @override
  String get language_albanian => 'albaania';

  @override
  String get language_arabic => 'araabia';

  @override
  String get language_belarusian => 'valgevene';

  @override
  String get language_bengali => 'bengali';

  @override
  String get language_bulgarian => 'bulgaaria';

  @override
  String get language_catalan => 'katalaani';

  @override
  String get language_chinese => 'hiina';

  @override
  String get language_croatian => 'horvaadi';

  @override
  String get language_czech => 'tšehhi';

  @override
  String get language_danish => 'taani';

  @override
  String get language_dutch => 'hollandi';

  @override
  String get language_english => 'inglise';

  @override
  String get language_esperanto => 'esperanto';

  @override
  String get language_estonian => 'eesti';

  @override
  String get language_finnish => 'soome';

  @override
  String get language_french => 'prantsuse';

  @override
  String get language_galician => 'galeegi';

  @override
  String get language_georgian => 'gruusia';

  @override
  String get language_german => 'saksa';

  @override
  String get language_greek => 'kreeka';

  @override
  String get language_gujarati => 'gujarati';

  @override
  String get language_haitian => 'haiti';

  @override
  String get language_hebrew => 'heebrea';

  @override
  String get language_hindi => 'hindi';

  @override
  String get language_hungarian => 'ungari';

  @override
  String get language_icelandic => 'islandi';

  @override
  String get language_indonesian => 'indoneesia';

  @override
  String get language_irish => 'iiri';

  @override
  String get language_italian => 'itaalia';

  @override
  String get language_japanese => 'jaapani';

  @override
  String get language_kannada => 'kannada';

  @override
  String get language_korean => 'korea';

  @override
  String get language_latvian => 'läti';

  @override
  String get language_lithuanian => 'leedu';

  @override
  String get language_macedonian => 'makedoonia';

  @override
  String get language_malay => 'malai';

  @override
  String get language_maltese => 'malta';

  @override
  String get language_marathi => 'marathi';

  @override
  String get language_norwegian => 'norra';

  @override
  String get language_persian => 'pärsia';

  @override
  String get language_polish => 'poola';

  @override
  String get language_portuguese => 'portugali';

  @override
  String get language_romanian => 'rumeenia';

  @override
  String get language_russian => 'vene';

  @override
  String get language_slovak => 'slovaki';

  @override
  String get language_slovenian => 'sloveeni';

  @override
  String get language_spanish => 'hispaania';

  @override
  String get language_swahili => 'suahiili';

  @override
  String get language_swedish => 'rootsi';

  @override
  String get language_tagalog => 'tagalogi';

  @override
  String get language_tamil => 'tamili';

  @override
  String get language_telugu => 'telugu';

  @override
  String get language_thai => 'tai';

  @override
  String get language_turkish => 'türgi';

  @override
  String get language_ukrainian => 'ukraina';

  @override
  String get language_urdu => 'urdu';

  @override
  String get language_vietnamese => 'vietnami';

  @override
  String get language_welsh => 'kõmri';

  @override
  String get enjoying_app => 'Kas teile meeldib Screen Translate?';

  @override
  String get review_prompt_message =>
      'Tahaksime kuulda teie arvamust! Kas soovite rakendust Google Play\'s hinnata?';

  @override
  String get rate_now => 'Hinda kohe';

  @override
  String get not_now => 'Mitte praegu';

  @override
  String get cannot_open_store => 'Google Play poodi ei õnnestunud avada';

  @override
  String get api_key_required => 'API võti on vajalik';

  @override
  String get api_key_setup_prompt =>
      'Seadistage oma ChatGLM API võti AI tõlkeks.';

  @override
  String get go_to_settings => 'Mine Seadetesse';

  @override
  String get api_key_dialog_title => 'AI Tõlke API Konfigureerimine';

  @override
  String get api_key_configuration_title => 'ChatGLM AI Tõlge';

  @override
  String get api_key_get_key_from =>
      'ChatGLM tõlgete kasutamiseks peate saama tasuta API võtme ';

  @override
  String get api_key_configuration_steps => 'API võtme konfigureerimise sammud';

  @override
  String get api_key_step_1 => '1. Külastage open.bigmodel.cn-i ja looge konto';

  @override
  String get api_key_step_2 => '2. Liikuge API haldamise jaotisse';

  @override
  String get api_key_step_3 => '3. Looge oma rakendusele uus API võti';

  @override
  String get api_key_input_label => 'ChatGLM API võti';

  @override
  String get api_key_input_hint => 'Sisestage oma ChatGLM API võti';

  @override
  String get api_key_input_error => 'Palun sisestage kehtiv API võti';

  @override
  String get api_key_save_button => 'Salvesta API võti';

  @override
  String get api_key_note =>
      'Teie API võti salvestatakse turvaliselt ja kasutatakse ainult tõlketeenuste jaoks.';

  @override
  String get api_key_save_error =>
      'Vigane API võti. Kontrollige ja proovige uuesti.';

  @override
  String get api_key_save_success => 'API võti on edukalt salvestatud';

  @override
  String get translation_mode_on_device => 'Tõlge Seadmes';

  @override
  String get translation_mode_on_device_description =>
      'Kasutab seadmesse sisseehitatud tõlkemudeleid. Kiire ja töötab võrguühenduseta, kuid võib olla piiratud keeletoega ja täpsusega.';

  @override
  String get translation_mode_ai => 'AI-Tõlge';

  @override
  String get translation_mode_ai_description =>
      'Kasutab täiustatud AI-mudeleid täpsemateks ja kontekstuaalseteks tõlgeteks. Nõuab internetiühendust ja API-võtit.';

  @override
  String get translation_mode_title => 'Tõlke Režiim';

  @override
  String get translation_mode_on_device_label => 'Seadmes';

  @override
  String get translation_mode_ai_label => 'AI';

  @override
  String get close => 'Sulge';
}
