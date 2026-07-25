// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Croatian (`hr`).
class AppLocalizationsHr extends AppLocalizations {
  AppLocalizationsHr([String locale = 'hr']) : super(locale);

  @override
  String get app_title => 'Prijevod zaslona';

  @override
  String get source_language => 'Iz';

  @override
  String get target_language => 'U';

  @override
  String get stop_translation => 'Zaustavi prijevod';

  @override
  String get translate_screen => 'Prevedi zaslon';

  @override
  String get source_and_target_cannot_be_the_same =>
      'Izvorni i ciljni jezik ne mogu biti isti';

  @override
  String get manage_translation_models => 'Upravljanje modelima prijevoda';

  @override
  String model_download_success(Object language) {
    return 'Model za $language uspješno preuzet';
  }

  @override
  String model_download_error(Object language) {
    return 'Greška pri preuzimanju modela za $language';
  }

  @override
  String get model_not_downloaded => 'Model nije preuzet';

  @override
  String get download_model => 'Preuzmi';

  @override
  String get remove_translation_model => 'Obrisi model prijevoda';

  @override
  String remove_translation_model_confirmation(Object language) {
    return 'Da li ste sigurni da zelite obrisati model prijevoda za $language?';
  }

  @override
  String get cancel => 'Odustani';

  @override
  String get remove => 'Obrisi';

  @override
  String get not_installed => 'Nije instaliran';

  @override
  String get downloading => 'Preuzimanje';

  @override
  String get installed => 'Instaliran';

  @override
  String get download_failed => 'Preuzimanje neuspješno';

  @override
  String failed_to_remove_model(Object language) {
    return 'Greška pri brisanju modela $language';
  }

  @override
  String failed_to_download_model(Object language) {
    return 'Greška pri preuzimanju modela $language';
  }

  @override
  String get auto_translate_mode => 'Automatiski prijevod';

  @override
  String get manual_translate_mode => 'Rucni prijevod';

  @override
  String get original_text_mode => 'Originalni tekst';

  @override
  String get overlay_permission_required => 'Način prevodovanja';

  @override
  String get overlay_permission_required_content =>
      'Ovaj program zahteva dozvolu za prevod na ekranu.';

  @override
  String get grant_permission => 'Dozvola';

  @override
  String get language_afrikaans => 'Afrikaans';

  @override
  String get language_albanian => 'Albanski';

  @override
  String get language_arabic => 'Arapski';

  @override
  String get language_belarusian => 'Bjeloruski';

  @override
  String get language_bengali => 'Bengalski';

  @override
  String get language_bulgarian => 'Bugarski';

  @override
  String get language_catalan => 'Katalonski';

  @override
  String get language_chinese => 'Kineski';

  @override
  String get language_croatian => 'Hrvatski';

  @override
  String get language_czech => 'Češki';

  @override
  String get language_danish => 'Danski';

  @override
  String get language_dutch => 'Nizozemski';

  @override
  String get language_english => 'Engleski';

  @override
  String get language_esperanto => 'Esperanto';

  @override
  String get language_estonian => 'Estonski';

  @override
  String get language_finnish => 'Finski';

  @override
  String get language_french => 'Francuski';

  @override
  String get language_galician => 'Galicijski';

  @override
  String get language_georgian => 'Gruzijski';

  @override
  String get language_german => 'Njemački';

  @override
  String get language_greek => 'Grčki';

  @override
  String get language_gujarati => 'Gujarati';

  @override
  String get language_haitian => 'Haićanski';

  @override
  String get language_hebrew => 'Hebrejski';

  @override
  String get language_hindi => 'Hindi';

  @override
  String get language_hungarian => 'Mađarski';

  @override
  String get language_icelandic => 'Islandski';

  @override
  String get language_indonesian => 'Indonezijski';

  @override
  String get language_irish => 'Irski';

  @override
  String get language_italian => 'Talijanski';

  @override
  String get language_japanese => 'Japanski';

  @override
  String get language_kannada => 'Kannada';

  @override
  String get language_korean => 'Korejski';

  @override
  String get language_latvian => 'Latvijski';

  @override
  String get language_lithuanian => 'Litavski';

  @override
  String get language_macedonian => 'Makedonski';

  @override
  String get language_malay => 'Malajski';

  @override
  String get language_maltese => 'Malteški';

  @override
  String get language_marathi => 'Marathi';

  @override
  String get language_norwegian => 'Norveški';

  @override
  String get language_persian => 'Perzijski';

  @override
  String get language_polish => 'Poljski';

  @override
  String get language_portuguese => 'Portugalski';

  @override
  String get language_romanian => 'Rumunjski';

  @override
  String get language_russian => 'Ruski';

  @override
  String get language_slovak => 'Slovački';

  @override
  String get language_slovenian => 'Slovenski';

  @override
  String get language_spanish => 'Španjolski';

  @override
  String get language_swahili => 'Svahili';

  @override
  String get language_swedish => 'Švedski';

  @override
  String get language_tagalog => 'Tagalog';

  @override
  String get language_tamil => 'Tamilski';

  @override
  String get language_telugu => 'Telugu';

  @override
  String get language_thai => 'Tajlandski';

  @override
  String get language_turkish => 'Turski';

  @override
  String get language_ukrainian => 'Ukrajinski';

  @override
  String get language_urdu => 'Urdu';

  @override
  String get language_vietnamese => 'Vijetnamski';

  @override
  String get language_welsh => 'Velški';

  @override
  String get enjoying_app => 'Sviđa li vam se Screen Translate?';

  @override
  String get review_prompt_message =>
      'Željeli bismo čuti vaše mišljenje! Želite li ocijeniti aplikaciju na Google Playu?';

  @override
  String get rate_now => 'Ocijeni sada';

  @override
  String get not_now => 'Ne sada';

  @override
  String get cannot_open_store => 'Nije moguće otvoriti Google Play Store';

  @override
  String get api_key_required => 'Potreban je API ključ';

  @override
  String get api_key_setup_prompt =>
      'Postavite svoj ChatGLM API ključ za AI prijevod.';

  @override
  String get go_to_settings => 'Idi na Postavke';

  @override
  String get api_key_dialog_title => 'Konfiguracija API-ja za AI prijevod';

  @override
  String get api_key_configuration_title => 'ChatGLM AI prijevod';

  @override
  String get api_key_get_key_from =>
      'Za korištenje ChatGLM prijevoda, morate dobiti besplatni API ključ s ';

  @override
  String get api_key_configuration_steps => 'Koraci konfiguracije API ključa';

  @override
  String get api_key_step_1 => '1. Posjetite open.bigmodel.cn i stvorite račun';

  @override
  String get api_key_step_2 => '2. Idite u odjeljak za upravljanje API-jem';

  @override
  String get api_key_step_3 =>
      '3. Generirajte novi API ključ za svoju aplikaciju';

  @override
  String get api_key_input_label => 'ChatGLM API ključ';

  @override
  String get api_key_input_hint => 'Unesite svoj ChatGLM API ključ';

  @override
  String get api_key_input_error => 'Molimo unesite valjani API ključ';

  @override
  String get api_key_save_button => 'Spremi API ključ';

  @override
  String get api_key_note =>
      'Vaš API ključ bit će sigurno pohranjen i korišten samo za usluge prijevoda.';

  @override
  String get api_key_save_error =>
      'Nevažeći API ključ. Provjerite i pokušajte ponovno.';

  @override
  String get api_key_save_success => 'API ključ je uspješno spremljen';

  @override
  String get translation_mode_on_device => 'Prijevod na Uređaju';

  @override
  String get translation_mode_on_device_description =>
      'Koristi ugrađene modele prijevoda na vašem uređaju. Brzo i radi izvan mreže, ali može imati ograničenu jezičnu podršku i preciznost.';

  @override
  String get translation_mode_ai => 'AI Prijevod';

  @override
  String get translation_mode_ai_description =>
      'Koristi napredne AI modele za preciznije i kontekstualne prijevode. Zahtijeva internetsku vezu i API ključ.';

  @override
  String get translation_mode_title => 'Način Prijevoda';

  @override
  String get translation_mode_on_device_label => 'Na Uređaju';

  @override
  String get translation_mode_ai_label => 'AI';

  @override
  String get close => 'Zatvori';
}
