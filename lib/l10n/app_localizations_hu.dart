// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hungarian (`hu`).
class AppLocalizationsHu extends AppLocalizations {
  AppLocalizationsHu([String locale = 'hu']) : super(locale);

  @override
  String get app_title => 'Képernyőfordítás';

  @override
  String get source_language => 'Erről';

  @override
  String get target_language => 'Erre';

  @override
  String get stop_translation => 'Fordítás leállítása';

  @override
  String get translate_screen => 'Képernyő fordítása';

  @override
  String get source_and_target_cannot_be_the_same =>
      'A forrás- és célnyelv nem lehet ugyanaz';

  @override
  String get manage_translation_models => 'Fordítási modellek kezelése';

  @override
  String model_download_success(Object language) {
    return 'A(z) $language modell sikeresen letöltve';
  }

  @override
  String model_download_error(Object language) {
    return 'Hiba történt a(z) $language modell letöltése közben';
  }

  @override
  String get model_not_downloaded => 'A modell nincs letöltve';

  @override
  String get download_model => 'Letöltés';

  @override
  String get remove_translation_model => 'Modell torlása';

  @override
  String remove_translation_model_confirmation(Object language) {
    return 'Biztos benne, hogy törli a $language fordítást?';
  }

  @override
  String get cancel => 'Mégse';

  @override
  String get remove => 'Torol';

  @override
  String get not_installed => 'Nincs telepítve';

  @override
  String get downloading => 'Letöltés...';

  @override
  String get installed => 'Telepítve';

  @override
  String get download_failed => 'Letöltés hiba';

  @override
  String failed_to_remove_model(Object language) {
    return 'Hiba történt a(z) $language modell torlásakor';
  }

  @override
  String failed_to_download_model(Object language) {
    return 'Hiba történt a(z) $language modell letöltése közben';
  }

  @override
  String get auto_translate_mode => 'Automatikus forrásközépfordítás';

  @override
  String get manual_translate_mode => 'Manuális forrásközépfordítás';

  @override
  String get original_text_mode => 'Erre a szöveg';

  @override
  String get overlay_permission_required => 'Fordítás náluk';

  @override
  String get overlay_permission_required_content =>
      'Fordítás náluk, hogy a kepernyő főnépének megfeleljen';

  @override
  String get grant_permission => 'Engedély';

  @override
  String get language_afrikaans => 'Afrikaans';

  @override
  String get language_albanian => 'Albán';

  @override
  String get language_arabic => 'Arab';

  @override
  String get language_belarusian => 'Fehérorosz';

  @override
  String get language_bengali => 'Bengáli';

  @override
  String get language_bulgarian => 'Bolgár';

  @override
  String get language_catalan => 'Katalán';

  @override
  String get language_chinese => 'Kínai';

  @override
  String get language_croatian => 'Horvát';

  @override
  String get language_czech => 'Cseh';

  @override
  String get language_danish => 'Dán';

  @override
  String get language_dutch => 'Holland';

  @override
  String get language_english => 'Angol';

  @override
  String get language_esperanto => 'Eszperantó';

  @override
  String get language_estonian => 'Észt';

  @override
  String get language_finnish => 'Finn';

  @override
  String get language_french => 'Francia';

  @override
  String get language_galician => 'Galíciai';

  @override
  String get language_georgian => 'Grúz';

  @override
  String get language_german => 'Német';

  @override
  String get language_greek => 'Görög';

  @override
  String get language_gujarati => 'Gudzsaráti';

  @override
  String get language_haitian => 'Haiti';

  @override
  String get language_hebrew => 'Héber';

  @override
  String get language_hindi => 'Hindi';

  @override
  String get language_hungarian => 'Magyar';

  @override
  String get language_icelandic => 'Izlandi';

  @override
  String get language_indonesian => 'Indonéz';

  @override
  String get language_irish => 'Ír';

  @override
  String get language_italian => 'Olasz';

  @override
  String get language_japanese => 'Japán';

  @override
  String get language_kannada => 'Kannada';

  @override
  String get language_korean => 'Koreai';

  @override
  String get language_latvian => 'Lett';

  @override
  String get language_lithuanian => 'Litván';

  @override
  String get language_macedonian => 'Macedón';

  @override
  String get language_malay => 'Maláj';

  @override
  String get language_maltese => 'Máltai';

  @override
  String get language_marathi => 'Maráthi';

  @override
  String get language_norwegian => 'Norvég';

  @override
  String get language_persian => 'Perzsa';

  @override
  String get language_polish => 'Lengyel';

  @override
  String get language_portuguese => 'Portugál';

  @override
  String get language_romanian => 'Román';

  @override
  String get language_russian => 'Orosz';

  @override
  String get language_slovak => 'Szlovák';

  @override
  String get language_slovenian => 'Szlovén';

  @override
  String get language_spanish => 'Spanyol';

  @override
  String get language_swahili => 'Szuahéli';

  @override
  String get language_swedish => 'Svéd';

  @override
  String get language_tagalog => 'Tagalog';

  @override
  String get language_tamil => 'Tamil';

  @override
  String get language_telugu => 'Telugu';

  @override
  String get language_thai => 'Thai';

  @override
  String get language_turkish => 'Török';

  @override
  String get language_ukrainian => 'Ukrán';

  @override
  String get language_urdu => 'Urdu';

  @override
  String get language_vietnamese => 'Vietnami';

  @override
  String get language_welsh => 'Walesi';

  @override
  String get enjoying_app => 'Tetszik a Screen Translate?';

  @override
  String get review_prompt_message =>
      'Szeretnénk hallani a véleményét! Szeretné értékelni az alkalmazást a Google Playen?';

  @override
  String get rate_now => 'Értékelés most';

  @override
  String get not_now => 'Most nem';

  @override
  String get cannot_open_store =>
      'Nem sikerült megnyitni a Google Play áruházat';

  @override
  String get api_key_required => 'API kulcs szükséges';

  @override
  String get api_key_setup_prompt =>
      'Állítsa be a ChatGLM API kulcsát AI fordításhoz.';

  @override
  String get go_to_settings => 'Ugrás a Beállításokhoz';

  @override
  String get api_key_dialog_title => 'AI fordítási API konfigurálása';

  @override
  String get api_key_configuration_title => 'ChatGLM AI fordítás';

  @override
  String get api_key_get_key_from =>
      'A ChatGLM fordítások használatához szerezzen egy ingyenes API kulcsot ';

  @override
  String get api_key_configuration_steps => 'API kulcs konfigurációs lépések';

  @override
  String get api_key_step_1 =>
      '1. Látogasson el a open.bigmodel.cn oldalra és hozzon létre egy fiókot';

  @override
  String get api_key_step_2 => '2. Navigáljon az API kezelési részhez';

  @override
  String get api_key_step_3 =>
      '3. Generáljon egy új API kulcsot az alkalmazásához';

  @override
  String get api_key_input_label => 'ChatGLM API kulcs';

  @override
  String get api_key_input_hint => 'Adja meg a ChatGLM API kulcsát';

  @override
  String get api_key_input_error => 'Kérem, adjon meg egy érvényes API kulcsot';

  @override
  String get api_key_save_button => 'API kulcs mentése';

  @override
  String get api_key_note =>
      'Az API kulcsa biztonságosan tárolásra kerül és csak fordítási szolgáltatásokhoz lesz felhasználva.';

  @override
  String get api_key_save_error =>
      'Érvénytelen API kulcs. Ellenőrizze és próbálja újra.';

  @override
  String get api_key_save_success => 'API kulcs sikeresen mentve';

  @override
  String get translation_mode_on_device => 'Fordítás Eszközön';

  @override
  String get translation_mode_on_device_description =>
      'Beépített fordítási modelleket használ az eszközén. Gyors és offline is működik, de lehet, hogy korlátozott nyelvi támogatással és pontossággal rendelkezik.';

  @override
  String get translation_mode_ai => 'AI-Fordítás';

  @override
  String get translation_mode_ai_description =>
      'Fejlett AI-modelleket használ pontosabb és kontextuális fordításokhoz. Internetkapcsolatot és API-kulcsot igényel.';

  @override
  String get translation_mode_title => 'Fordítási Mód';

  @override
  String get translation_mode_on_device_label => 'Eszközön';

  @override
  String get translation_mode_ai_label => 'AI';

  @override
  String get close => 'Bezárás';
}
