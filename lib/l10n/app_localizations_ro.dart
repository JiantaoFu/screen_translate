// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Romanian Moldavian Moldovan (`ro`).
class AppLocalizationsRo extends AppLocalizations {
  AppLocalizationsRo([String locale = 'ro']) : super(locale);

  @override
  String get app_title => 'Traducere ecran';

  @override
  String get source_language => 'Din';

  @override
  String get target_language => 'În';

  @override
  String get stop_translation => 'Oprește traducerea';

  @override
  String get translate_screen => 'Traduce ecranul';

  @override
  String get source_and_target_cannot_be_the_same =>
      'Limba sursă și limba țintă nu pot fi identice';

  @override
  String get manage_translation_models => 'Gestionează modelele de traducere';

  @override
  String model_download_success(Object language) {
    return 'Model pentru $language descărcat cu succes';
  }

  @override
  String model_download_error(Object language) {
    return 'Eroare la descărcarea modelului pentru $language';
  }

  @override
  String get model_not_downloaded => 'Model nedescărcat';

  @override
  String get download_model => 'Descarcă';

  @override
  String get remove_translation_model => 'Elimina modelul de traducere';

  @override
  String remove_translation_model_confirmation(Object language) {
    return 'Sigur doriti eliminarea modelului de traducere pentru $language?';
  }

  @override
  String get cancel => 'Anulează';

  @override
  String get remove => 'Elimina';

  @override
  String get not_installed => 'Nedeinstalat';

  @override
  String get downloading => 'Descarcă...';

  @override
  String get installed => 'Dinamit';

  @override
  String get download_failed => 'Descarcărea a esuat';

  @override
  String failed_to_remove_model(Object language) {
    return 'Eliminarea modelului de traducere a esuat pentru $language';
  }

  @override
  String failed_to_download_model(Object language) {
    return 'Descarcarea modelului de traducere a esuat pentru $language';
  }

  @override
  String get auto_translate_mode => 'Módul de traducere automat';

  @override
  String get manual_translate_mode => 'Módul de traducere manual';

  @override
  String get original_text_mode => 'Módul text original';

  @override
  String get overlay_permission_required => 'Módul de traducere';

  @override
  String get overlay_permission_required_content =>
      'Acest program necesita permisiuni pentru a traduce pe ecran.';

  @override
  String get grant_permission => 'Aceepte permisiuni';

  @override
  String get language_afrikaans => 'Afrikaans';

  @override
  String get language_albanian => 'Albaneză';

  @override
  String get language_arabic => 'Arabă';

  @override
  String get language_belarusian => 'Belarusă';

  @override
  String get language_bengali => 'Bengali';

  @override
  String get language_bulgarian => 'Bulgară';

  @override
  String get language_catalan => 'Catalană';

  @override
  String get language_chinese => 'Chineză';

  @override
  String get language_croatian => 'Croată';

  @override
  String get language_czech => 'Cehă';

  @override
  String get language_danish => 'Daneză';

  @override
  String get language_dutch => 'Olandeză';

  @override
  String get language_english => 'Engleză';

  @override
  String get language_esperanto => 'Esperanto';

  @override
  String get language_estonian => 'Estonă';

  @override
  String get language_finnish => 'Finlandeză';

  @override
  String get language_french => 'Franceză';

  @override
  String get language_galician => 'Galiciană';

  @override
  String get language_georgian => 'Georgiană';

  @override
  String get language_german => 'Germană';

  @override
  String get language_greek => 'Greacă';

  @override
  String get language_gujarati => 'Gujarati';

  @override
  String get language_haitian => 'Haitiană';

  @override
  String get language_hebrew => 'Ebraică';

  @override
  String get language_hindi => 'Hindi';

  @override
  String get language_hungarian => 'Maghiară';

  @override
  String get language_icelandic => 'Islandeză';

  @override
  String get language_indonesian => 'Indoneziană';

  @override
  String get language_irish => 'Irlandeză';

  @override
  String get language_italian => 'Italiană';

  @override
  String get language_japanese => 'Japoneză';

  @override
  String get language_kannada => 'Kannada';

  @override
  String get language_korean => 'Coreeană';

  @override
  String get language_latvian => 'Letonă';

  @override
  String get language_lithuanian => 'Lituaniană';

  @override
  String get language_macedonian => 'Macedoneană';

  @override
  String get language_malay => 'Malaeză';

  @override
  String get language_maltese => 'Malteză';

  @override
  String get language_marathi => 'Marathi';

  @override
  String get language_norwegian => 'Norvegiană';

  @override
  String get language_persian => 'Persană';

  @override
  String get language_polish => 'Poloneză';

  @override
  String get language_portuguese => 'Portugheză';

  @override
  String get language_romanian => 'Română';

  @override
  String get language_russian => 'Rusă';

  @override
  String get language_slovak => 'Slovacă';

  @override
  String get language_slovenian => 'Slovenă';

  @override
  String get language_spanish => 'Spaniolă';

  @override
  String get language_swahili => 'Swahili';

  @override
  String get language_swedish => 'Suedeză';

  @override
  String get language_tagalog => 'Tagalog';

  @override
  String get language_tamil => 'Tamil';

  @override
  String get language_telugu => 'Telugu';

  @override
  String get language_thai => 'Thailandeză';

  @override
  String get language_turkish => 'Turcă';

  @override
  String get language_ukrainian => 'Ucraineană';

  @override
  String get language_urdu => 'Urdu';

  @override
  String get language_vietnamese => 'Vietnameză';

  @override
  String get language_welsh => 'Galeză';

  @override
  String get enjoying_app => 'Îți place Screen Translate?';

  @override
  String get review_prompt_message =>
      'Am dori să auzim părerea ta! Vrei să evaluezi aplicația pe Google Play?';

  @override
  String get rate_now => 'Evaluează acum';

  @override
  String get not_now => 'Nu acum';

  @override
  String get cannot_open_store => 'Nu s-a putut deschide Google Play Store';

  @override
  String get api_key_required => 'Cheie API necesară';

  @override
  String get api_key_setup_prompt =>
      'Configurați-vă cheia API ChatGLM pentru traducere AI.';

  @override
  String get go_to_settings => 'Mergeți la Setări';

  @override
  String get api_key_dialog_title => 'Configurare API Traducere AI';

  @override
  String get api_key_configuration_title => 'Traducere ChatGLM cu AI';

  @override
  String get api_key_get_key_from =>
      'Pentru a utiliza traducerile ChatGLM, trebuie să obțineți o cheie API gratuită de la ';

  @override
  String get api_key_configuration_steps => 'Pași de Configurare a Cheii API';

  @override
  String get api_key_step_1 => '1. Vizitați open.bigmodel.cn și creați un cont';

  @override
  String get api_key_step_2 => '2. Navigați la secțiunea de Gestionare API';

  @override
  String get api_key_step_3 =>
      '3. Generați o nouă cheie API pentru aplicația dvs.';

  @override
  String get api_key_input_label => 'Cheie API ChatGLM';

  @override
  String get api_key_input_hint => 'Introduceți cheia API ChatGLM';

  @override
  String get api_key_input_error =>
      'Vă rugăm să introduceți o cheie API validă';

  @override
  String get api_key_save_button => 'Salvați Cheia API';

  @override
  String get api_key_note =>
      'Cheia dvs. API va fi stocată în siguranță și utilizată doar pentru servicii de traducere.';

  @override
  String get api_key_save_error =>
      'Cheie API invalidă. Verificați și încercați din nou.';

  @override
  String get api_key_save_success => 'Cheie API Salvată cu Succes';

  @override
  String get translation_mode_on_device => 'Traducere pe Dispozitiv';

  @override
  String get translation_mode_on_device_description =>
      'Utilizează modele de traducere integrate pe dispozitivul dvs. Rapid și funcționează offline, dar poate avea suport lingvistic și precizie limitate.';

  @override
  String get translation_mode_ai => 'Traducere cu IA';

  @override
  String get translation_mode_ai_description =>
      'Utilizează modele de IA avansate pentru traduceri mai precise și contextuale. Necesită conexiune la internet și cheie API.';

  @override
  String get translation_mode_title => 'Mod de Traducere';

  @override
  String get translation_mode_on_device_label => 'Pe Dispozitiv';

  @override
  String get translation_mode_ai_label => 'IA';

  @override
  String get close => 'Închide';
}
