// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Czech (`cs`).
class AppLocalizationsCs extends AppLocalizations {
  AppLocalizationsCs([String locale = 'cs']) : super(locale);

  @override
  String get app_title => 'Překlad obrazovky';

  @override
  String get source_language => 'Z';

  @override
  String get target_language => 'Do';

  @override
  String get stop_translation => 'Zastavit překlad';

  @override
  String get translate_screen => 'Přeložit obrazovku';

  @override
  String get source_and_target_cannot_be_the_same =>
      'Zdrojový a cílový jazyk nemohou být stejné';

  @override
  String get manage_translation_models => 'Spravovat překladové modely';

  @override
  String model_download_success(Object language) {
    return 'Model pro jazyk $language byl úspěšně stažen';
  }

  @override
  String model_download_error(Object language) {
    return 'Chyba při stahování modelu pro jazyk $language';
  }

  @override
  String get model_not_downloaded => 'Model není stažen';

  @override
  String get download_model => 'Stáhnout';

  @override
  String get remove_translation_model => 'Odebrat překladový model';

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
  String get auto_translate_mode => 'Moodel pro automatické prevod';

  @override
  String get manual_translate_mode => 'Moodel pro rucní prevod';

  @override
  String get original_text_mode => 'Moodel pro stredni text';

  @override
  String get overlay_permission_required => 'Moodel pro prevod';

  @override
  String get overlay_permission_required_content => 'Moodel pro stredni text';

  @override
  String get grant_permission => 'Moodel pro strany';

  @override
  String get language_afrikaans => 'afrikánština';

  @override
  String get language_albanian => 'albánština';

  @override
  String get language_arabic => 'arabština';

  @override
  String get language_belarusian => 'běloruština';

  @override
  String get language_bengali => 'bengálština';

  @override
  String get language_bulgarian => 'bulharština';

  @override
  String get language_catalan => 'katalánština';

  @override
  String get language_chinese => 'čínština';

  @override
  String get language_croatian => 'chorvatština';

  @override
  String get language_czech => 'čeština';

  @override
  String get language_danish => 'dánština';

  @override
  String get language_dutch => 'nizozemština';

  @override
  String get language_english => 'angličtina';

  @override
  String get language_esperanto => 'esperanto';

  @override
  String get language_estonian => 'estonština';

  @override
  String get language_finnish => 'finština';

  @override
  String get language_french => 'francouzština';

  @override
  String get language_galician => 'galicijština';

  @override
  String get language_georgian => 'gruzínština';

  @override
  String get language_german => 'němčina';

  @override
  String get language_greek => 'řečtina';

  @override
  String get language_gujarati => 'gudžarátština';

  @override
  String get language_haitian => 'haitština';

  @override
  String get language_hebrew => 'hebrejština';

  @override
  String get language_hindi => 'hindština';

  @override
  String get language_hungarian => 'maďarština';

  @override
  String get language_icelandic => 'islandština';

  @override
  String get language_indonesian => 'indonéština';

  @override
  String get language_irish => 'irština';

  @override
  String get language_italian => 'italština';

  @override
  String get language_japanese => 'japonština';

  @override
  String get language_kannada => 'kannadština';

  @override
  String get language_korean => 'korejština';

  @override
  String get language_latvian => 'lotyština';

  @override
  String get language_lithuanian => 'litevština';

  @override
  String get language_macedonian => 'makedonština';

  @override
  String get language_malay => 'malajština';

  @override
  String get language_maltese => 'maltština';

  @override
  String get language_marathi => 'maráthština';

  @override
  String get language_norwegian => 'norština';

  @override
  String get language_persian => 'perština';

  @override
  String get language_polish => 'polština';

  @override
  String get language_portuguese => 'portugalština';

  @override
  String get language_romanian => 'rumunština';

  @override
  String get language_russian => 'ruština';

  @override
  String get language_slovak => 'slovenština';

  @override
  String get language_slovenian => 'slovinština';

  @override
  String get language_spanish => 'španělština';

  @override
  String get language_swahili => 'svahilština';

  @override
  String get language_swedish => 'švédština';

  @override
  String get language_tagalog => 'tagalština';

  @override
  String get language_tamil => 'tamilština';

  @override
  String get language_telugu => 'telugština';

  @override
  String get language_thai => 'thajština';

  @override
  String get language_turkish => 'turečtina';

  @override
  String get language_ukrainian => 'ukrajinština';

  @override
  String get language_urdu => 'urdština';

  @override
  String get language_vietnamese => 'vietnamština';

  @override
  String get language_welsh => 'velština';

  @override
  String get enjoying_app => 'Líbí se vám Screen Translate?';

  @override
  String get review_prompt_message =>
      'Rádi bychom slyšeli váš názor! Chcete aplikaci ohodnotit v Google Play?';

  @override
  String get rate_now => 'Hodnotit nyní';

  @override
  String get not_now => 'Ne teď';

  @override
  String get cannot_open_store => 'Nepodařilo se otevřít Google Play Store';

  @override
  String get api_key_required => 'Vyžadován klíč API';

  @override
  String get api_key_setup_prompt =>
      'Nastavte si klíč API ChatGLM pro překlad pomocí AI.';

  @override
  String get go_to_settings => 'Přejít do Nastavení';

  @override
  String get api_key_dialog_title => 'Konfigurace API překladu AI';

  @override
  String get api_key_configuration_title => 'Překlad ChatGLM s AI';

  @override
  String get api_key_get_key_from =>
      'Chcete-li používat překlady ChatGLM, musíte získat bezplatný klíč API z ';

  @override
  String get api_key_configuration_steps => 'Kroky konfigurace klíče API';

  @override
  String get api_key_step_1 =>
      '1. Navštivte open.bigmodel.cn a vytvořte si účet';

  @override
  String get api_key_step_2 => '2. Přejděte do sekce Správy API';

  @override
  String get api_key_step_3 => '3. Vygenerujte nový klíč API pro vaši aplikaci';

  @override
  String get api_key_input_label => 'Klíč API ChatGLM';

  @override
  String get api_key_input_hint => 'Zadejte svůj klíč API ChatGLM';

  @override
  String get api_key_input_error => 'Zadejte prosím platný klíč API';

  @override
  String get api_key_save_button => 'Uložit klíč API';

  @override
  String get api_key_note =>
      'Váš klíč API bude bezpečně uložen a použit pouze pro překladové služby.';

  @override
  String get api_key_save_error =>
      'Neplatný klíč API. Zkontrolujte a zkuste to znovu.';

  @override
  String get api_key_save_success => 'Klíč API byl úspěšně uložen';

  @override
  String get translation_mode_on_device => 'Překlad na Zařízení';

  @override
  String get translation_mode_on_device_description =>
      'Používá vestavěné překladové modely na vašem zařízení. Rychlé a funguje offline, ale může mít omezené jazykové podpory a přesnosti.';

  @override
  String get translation_mode_ai => 'Překlad s AI';

  @override
  String get translation_mode_ai_description =>
      'Používá pokročilé modely AI pro přesnější a kontextové překlady. Vyžaduje připojení k internetu a klíč API.';

  @override
  String get translation_mode_title => 'Překladový Režim';

  @override
  String get translation_mode_on_device_label => 'Na Zařízení';

  @override
  String get translation_mode_ai_label => 'AI';

  @override
  String get close => 'Zavřít';
}
