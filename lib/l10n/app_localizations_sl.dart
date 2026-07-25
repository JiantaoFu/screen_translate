// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Slovenian (`sl`).
class AppLocalizationsSl extends AppLocalizations {
  AppLocalizationsSl([String locale = 'sl']) : super(locale);

  @override
  String get app_title => 'Prevajanje zaslona';

  @override
  String get source_language => 'Iz';

  @override
  String get target_language => 'V';

  @override
  String get stop_translation => 'Ustavi prevajanje';

  @override
  String get translate_screen => 'Prevedi zaslon';

  @override
  String get source_and_target_cannot_be_the_same =>
      'Izvorni in ciljni jezik ne moreta biti enaka';

  @override
  String get manage_translation_models => 'Upravljanje prevajalskih modelov';

  @override
  String model_download_success(Object language) {
    return 'Model za $language je bil uspešno prenesen';
  }

  @override
  String model_download_error(Object language) {
    return 'Napaka pri prenosu modela za $language';
  }

  @override
  String get model_not_downloaded => 'Model ni prenesen';

  @override
  String get download_model => 'Prenesi';

  @override
  String get remove_translation_model => 'Obrisi model prevajanja';

  @override
  String remove_translation_model_confirmation(Object language) {
    return 'Da li ste sigurni da zelite obrisati model prevajanja za $language?';
  }

  @override
  String get cancel => 'Prekliši';

  @override
  String get remove => 'Obrisi';

  @override
  String get not_installed => 'Ni instaliran';

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
  String get auto_translate_mode => 'Automatski prevod';

  @override
  String get manual_translate_mode => 'Rucno prevod';

  @override
  String get original_text_mode => 'Originalni tekst';

  @override
  String get overlay_permission_required => 'Način prevodovanja';

  @override
  String get overlay_permission_required_content =>
      'Ovaj program zahteva dozvolu za prevođenje na ekranskoj plošci.';

  @override
  String get grant_permission => 'Dohvati dozvolu';

  @override
  String get language_afrikaans => 'Afrikanščina';

  @override
  String get language_albanian => 'Albanščina';

  @override
  String get language_arabic => 'Arabščina';

  @override
  String get language_belarusian => 'Beloruščina';

  @override
  String get language_bengali => 'Bengalščina';

  @override
  String get language_bulgarian => 'Bolgarščina';

  @override
  String get language_catalan => 'Katalonščina';

  @override
  String get language_chinese => 'Kitajščina';

  @override
  String get language_croatian => 'Hrvaščina';

  @override
  String get language_czech => 'Češčina';

  @override
  String get language_danish => 'Danščina';

  @override
  String get language_dutch => 'Nizozemščina';

  @override
  String get language_english => 'Angleščina';

  @override
  String get language_esperanto => 'Esperanto';

  @override
  String get language_estonian => 'Estonščina';

  @override
  String get language_finnish => 'Finščina';

  @override
  String get language_french => 'Francoščina';

  @override
  String get language_galician => 'Galicijščina';

  @override
  String get language_georgian => 'Gruzijščina';

  @override
  String get language_german => 'Nemščina';

  @override
  String get language_greek => 'Grščina';

  @override
  String get language_gujarati => 'Gudžaratščina';

  @override
  String get language_haitian => 'Haitijska kreolščina';

  @override
  String get language_hebrew => 'Hebrejščina';

  @override
  String get language_hindi => 'Hindijščina';

  @override
  String get language_hungarian => 'Madžarščina';

  @override
  String get language_icelandic => 'Islandščina';

  @override
  String get language_indonesian => 'Indonezijščina';

  @override
  String get language_irish => 'Irščina';

  @override
  String get language_italian => 'Italijanščina';

  @override
  String get language_japanese => 'Japonščina';

  @override
  String get language_kannada => 'Kanada';

  @override
  String get language_korean => 'Korejščina';

  @override
  String get language_latvian => 'Latvijščina';

  @override
  String get language_lithuanian => 'Litovščina';

  @override
  String get language_macedonian => 'Makedonščina';

  @override
  String get language_malay => 'Malajščina';

  @override
  String get language_maltese => 'Malteščina';

  @override
  String get language_marathi => 'Maratščina';

  @override
  String get language_norwegian => 'Norveščina';

  @override
  String get language_persian => 'Perzijščina';

  @override
  String get language_polish => 'Poljščina';

  @override
  String get language_portuguese => 'Portugalščina';

  @override
  String get language_romanian => 'Romunščina';

  @override
  String get language_russian => 'Ruščina';

  @override
  String get language_slovak => 'Slovaščina';

  @override
  String get language_slovenian => 'Slovenščina';

  @override
  String get language_spanish => 'Španščina';

  @override
  String get language_swahili => 'Svahilščina';

  @override
  String get language_swedish => 'Švedščina';

  @override
  String get language_tagalog => 'Tagalog';

  @override
  String get language_tamil => 'Tamilščina';

  @override
  String get language_telugu => 'Telugu';

  @override
  String get language_thai => 'Tajščina';

  @override
  String get language_turkish => 'Turščina';

  @override
  String get language_ukrainian => 'Ukrajinščina';

  @override
  String get language_urdu => 'Urdujščina';

  @override
  String get language_vietnamese => 'Vietnamščina';

  @override
  String get language_welsh => 'Valižanščina';

  @override
  String get enjoying_app => 'Vam je všeč Screen Translate?';

  @override
  String get review_prompt_message =>
      'Radi bi slišali vaše mnenje! Ali bi ocenili aplikacijo v Google Play?';

  @override
  String get rate_now => 'Oceni zdaj';

  @override
  String get not_now => 'Ne zdaj';

  @override
  String get cannot_open_store => 'Ni mogoče odpreti Google Play Store';

  @override
  String get api_key_required => 'Potreben je API ključ';

  @override
  String get api_key_setup_prompt =>
      'Nastavite svoj ChatGLM API ključ za AI prevajanje.';

  @override
  String get go_to_settings => 'Pojdi v Nastavitve';

  @override
  String get api_key_dialog_title => 'Konfiguracija API za AI prevajanje';

  @override
  String get api_key_configuration_title => 'ChatGLM AI prevajanje';

  @override
  String get api_key_get_key_from =>
      'Za uporabo prevodov ChatGLM morate pridobiti brezplačen API ključ iz ';

  @override
  String get api_key_configuration_steps => 'Koraki konfiguracije API ključa';

  @override
  String get api_key_step_1 =>
      '1. Obiščite open.bigmodel.cn in ustvarite račun';

  @override
  String get api_key_step_2 => '2. Pojdite v razdelek za upravljanje API';

  @override
  String get api_key_step_3 => '3. Ustvarite nov API ključ za svojo aplikacijo';

  @override
  String get api_key_input_label => 'ChatGLM API ključ';

  @override
  String get api_key_input_hint => 'Vnesite svoj ChatGLM API ključ';

  @override
  String get api_key_input_error => 'Prosimo, vnesite veljaven API ključ';

  @override
  String get api_key_save_button => 'Shrani API ključ';

  @override
  String get api_key_note =>
      'Vaš API ključ bo varno shranjen in uporabljen samo za prevajalske storitve.';

  @override
  String get api_key_save_error =>
      'Neveljaven API ključ. Preverite in poskusite znova.';

  @override
  String get api_key_save_success => 'API ključ je bil uspešno shranjen';

  @override
  String get translation_mode_on_device => 'Prevajanje na Napravi';

  @override
  String get translation_mode_on_device_description =>
      'Uporablja vgrajene prevajalske modele na vaši napravi. Hitro in deluje brez povezave, vendar ima lahko omejeno jezikovno podporo in natančnost.';

  @override
  String get translation_mode_ai => 'Prevajanje z AI';

  @override
  String get translation_mode_ai_description =>
      'Uporablja napredne AI modele za natančnejše in kontekstualne prevode. Zahteva internetno povezavo in ključ API.';

  @override
  String get translation_mode_title => 'Način Prevajanja';

  @override
  String get translation_mode_on_device_label => 'Na Napravi';

  @override
  String get translation_mode_ai_label => 'AI';

  @override
  String get close => 'Zapri';
}
