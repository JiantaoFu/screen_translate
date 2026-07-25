// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Slovak (`sk`).
class AppLocalizationsSk extends AppLocalizations {
  AppLocalizationsSk([String locale = 'sk']) : super(locale);

  @override
  String get app_title => 'Preklad obrazovky';

  @override
  String get source_language => 'Z';

  @override
  String get target_language => 'Do';

  @override
  String get stop_translation => 'Zastaviť preklad';

  @override
  String get translate_screen => 'Preložiť obrazovku';

  @override
  String get source_and_target_cannot_be_the_same =>
      'Zdrojový a cieľový jazyk nemôžu byť rovnaké';

  @override
  String get manage_translation_models => 'Spravovať prekladové modely';

  @override
  String model_download_success(Object language) {
    return 'Model pre $language bol úspešne stiahnutý';
  }

  @override
  String model_download_error(Object language) {
    return 'Chyba pri sťahovaní modelu pre $language';
  }

  @override
  String get model_not_downloaded => 'Model nie je stiahnutý';

  @override
  String get download_model => 'Stiahnuť';

  @override
  String get remove_translation_model => 'Odebratť prekladový model';

  @override
  String remove_translation_model_confirmation(Object language) {
    return 'Opravdu chcete odstranit prekladový model pre jazyk $language?';
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
    return 'Nelze odstranit model pre jazyk $language';
  }

  @override
  String failed_to_download_model(Object language) {
    return 'Nelze stahnout model pre jazyk $language';
  }

  @override
  String get auto_translate_mode => 'Automatiská prekladovač';

  @override
  String get manual_translate_mode => 'Manuálne prekladováč';

  @override
  String get original_text_mode => 'Zdrojový text';

  @override
  String get overlay_permission_required => 'Módul prekladu';

  @override
  String get overlay_permission_required_content =>
      'Tento program vyzaduje opračování prekladu na obrazovke.';

  @override
  String get grant_permission => 'Opračovat';

  @override
  String get language_afrikaans => 'Afrikánčina';

  @override
  String get language_albanian => 'Albánčina';

  @override
  String get language_arabic => 'Arabčina';

  @override
  String get language_belarusian => 'Bieloruština';

  @override
  String get language_bengali => 'Bengálčina';

  @override
  String get language_bulgarian => 'Bulharčina';

  @override
  String get language_catalan => 'Katalánčina';

  @override
  String get language_chinese => 'Čínština';

  @override
  String get language_croatian => 'Chorvátčina';

  @override
  String get language_czech => 'Čeština';

  @override
  String get language_danish => 'Dánčina';

  @override
  String get language_dutch => 'Holandčina';

  @override
  String get language_english => 'Angličtina';

  @override
  String get language_esperanto => 'Esperanto';

  @override
  String get language_estonian => 'Estónčina';

  @override
  String get language_finnish => 'Fínčina';

  @override
  String get language_french => 'Francúzština';

  @override
  String get language_galician => 'Galícijčina';

  @override
  String get language_georgian => 'Gruzínčina';

  @override
  String get language_german => 'Nemčina';

  @override
  String get language_greek => 'Gréčtina';

  @override
  String get language_gujarati => 'Gudžarátčina';

  @override
  String get language_haitian => 'Haitčina';

  @override
  String get language_hebrew => 'Hebrejčina';

  @override
  String get language_hindi => 'Hindčina';

  @override
  String get language_hungarian => 'Maďarčina';

  @override
  String get language_icelandic => 'Islandčina';

  @override
  String get language_indonesian => 'Indonézština';

  @override
  String get language_irish => 'Írčina';

  @override
  String get language_italian => 'Taliančina';

  @override
  String get language_japanese => 'Japončina';

  @override
  String get language_kannada => 'Kannadčina';

  @override
  String get language_korean => 'Kórejčina';

  @override
  String get language_latvian => 'Lotyština';

  @override
  String get language_lithuanian => 'Litovčina';

  @override
  String get language_macedonian => 'Macedónčina';

  @override
  String get language_malay => 'Malajčina';

  @override
  String get language_maltese => 'Maltčina';

  @override
  String get language_marathi => 'Maráthčina';

  @override
  String get language_norwegian => 'Nórčina';

  @override
  String get language_persian => 'Perzština';

  @override
  String get language_polish => 'Poľština';

  @override
  String get language_portuguese => 'Portugalčina';

  @override
  String get language_romanian => 'Rumunčina';

  @override
  String get language_russian => 'Ruština';

  @override
  String get language_slovak => 'Slovenčina';

  @override
  String get language_slovenian => 'Slovinčina';

  @override
  String get language_spanish => 'Španielčina';

  @override
  String get language_swahili => 'Svahilčina';

  @override
  String get language_swedish => 'Švédčina';

  @override
  String get language_tagalog => 'Tagalčina';

  @override
  String get language_tamil => 'Tamilčina';

  @override
  String get language_telugu => 'Telugu';

  @override
  String get language_thai => 'Thajčina';

  @override
  String get language_turkish => 'Turečtina';

  @override
  String get language_ukrainian => 'Ukrajinčina';

  @override
  String get language_urdu => 'Urdčina';

  @override
  String get language_vietnamese => 'Vietnamčina';

  @override
  String get language_welsh => 'Waleština';

  @override
  String get enjoying_app => 'Páči sa vám Screen Translate?';

  @override
  String get review_prompt_message =>
      'Radi by sme počuli váš názor! Chceli by ste aplikáciu ohodnotiť v Google Play?';

  @override
  String get rate_now => 'Hodnotiť teraz';

  @override
  String get not_now => 'Nie teraz';

  @override
  String get cannot_open_store => 'Nepodarilo sa otvoriť Google Play Store';

  @override
  String get api_key_required => 'Vyžaduje sa API kľúč';

  @override
  String get api_key_setup_prompt =>
      'Nastavte si svoj ChatGLM API kľúč pre AI preklad.';

  @override
  String get go_to_settings => 'Prejsť do Nastavení';

  @override
  String get api_key_dialog_title => 'Konfigurácia API pre AI preklad';

  @override
  String get api_key_configuration_title => 'ChatGLM AI preklad';

  @override
  String get api_key_get_key_from =>
      'Ak chcete používať preklady ChatGLM, musíte získať bezplatný API kľúč z ';

  @override
  String get api_key_configuration_steps => 'Kroky konfigurácie API kľúča';

  @override
  String get api_key_step_1 =>
      '1. Navštívte open.bigmodel.cn a vytvorte si účet';

  @override
  String get api_key_step_2 => '2. Prejdite do sekcie Správy API';

  @override
  String get api_key_step_3 =>
      '3. Vygenerujte nový API kľúč pre svoju aplikáciu';

  @override
  String get api_key_input_label => 'ChatGLM API kľúč';

  @override
  String get api_key_input_hint => 'Zadajte svoj ChatGLM API kľúč';

  @override
  String get api_key_input_error => 'Prosím, zadajte platný API kľúč';

  @override
  String get api_key_save_button => 'Uložiť API kľúč';

  @override
  String get api_key_note =>
      'Váš API kľúč bude bezpečne uložený a použitý len pre prekladové služby.';

  @override
  String get api_key_save_error =>
      'Neplatný API kľúč. Skontrolujte a skúste znova.';

  @override
  String get api_key_save_success => 'API kľúč bol úspešne uložený';

  @override
  String get translation_mode_on_device => 'Preklad na Zariadení';

  @override
  String get translation_mode_on_device_description =>
      'Používa vstavaté prekladové modely na vašom zariadení. Rýchly a funguje offline, ale môže mať obmedzenú jazykovú podporu a presnosť.';

  @override
  String get translation_mode_ai => 'Preklad s AI';

  @override
  String get translation_mode_ai_description =>
      'Používa pokročilé modely AI pre presnejšie a kontextové preklady. Vyžaduje pripojenie na internet a kľúč API.';

  @override
  String get translation_mode_title => 'Prekladový Režim';

  @override
  String get translation_mode_on_device_label => 'Na Zariadení';

  @override
  String get translation_mode_ai_label => 'AI';

  @override
  String get close => 'Zavrieť';
}
