// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Lithuanian (`lt`).
class AppLocalizationsLt extends AppLocalizations {
  AppLocalizationsLt([String locale = 'lt']) : super(locale);

  @override
  String get app_title => 'Ekrano Vertimas';

  @override
  String get source_language => 'Iš';

  @override
  String get target_language => 'Į';

  @override
  String get stop_translation => 'Sustabdyti Vertimą';

  @override
  String get translate_screen => 'Versti Ekraną';

  @override
  String get source_and_target_cannot_be_the_same =>
      'Šaltinio ir tikslo kalbos negali būti vienodos';

  @override
  String get manage_translation_models => 'Tvarkyti Vertimo Modelius';

  @override
  String model_download_success(Object language) {
    return '$language modelis sėkmingai atsisiųstas';
  }

  @override
  String model_download_error(Object language) {
    return 'Klaida atsisiunčiant $language modelį';
  }

  @override
  String get model_not_downloaded => 'Modelis neatsisiųstas';

  @override
  String get download_model => 'Atsisiųsti';

  @override
  String get remove_translation_model => 'Otrinkti Vertimo Modelių';

  @override
  String remove_translation_model_confirmation(Object language) {
    return 'Ar tikrai norite pasalinti vertimo modelių $language?';
  }

  @override
  String get cancel => 'Atsėsti';

  @override
  String get remove => 'Otrinkti';

  @override
  String get not_installed => 'Neiškautinamas';

  @override
  String get downloading => 'Atsisiųstomas';

  @override
  String get installed => 'Iškautinamas';

  @override
  String get download_failed => 'Atsisiųsti negaliojo';

  @override
  String failed_to_remove_model(Object language) {
    return 'Klaida otrinant $language modelių';
  }

  @override
  String failed_to_download_model(Object language) {
    return 'Klaida atsisiunčiant $language modelį';
  }

  @override
  String get auto_translate_mode => 'Automatiskas vertimas';

  @override
  String get manual_translate_mode => 'Vertimas reėžiu';

  @override
  String get original_text_mode => 'Originalus tekstas';

  @override
  String get overlay_permission_required => 'Vertimo Modelis';

  @override
  String get overlay_permission_required_content =>
      'Šis programas turi butini prieigimo prie ekrano vertimui.';

  @override
  String get grant_permission => 'Griu prieiga';

  @override
  String get language_afrikaans => 'Afrikanų';

  @override
  String get language_albanian => 'Albanų';

  @override
  String get language_arabic => 'Arabų';

  @override
  String get language_belarusian => 'Baltarusių';

  @override
  String get language_bengali => 'Bengalų';

  @override
  String get language_bulgarian => 'Bulgarų';

  @override
  String get language_catalan => 'Katalonų';

  @override
  String get language_chinese => 'Kinų';

  @override
  String get language_croatian => 'Kroatų';

  @override
  String get language_czech => 'Čekų';

  @override
  String get language_danish => 'Danų';

  @override
  String get language_dutch => 'Olandų';

  @override
  String get language_english => 'Anglų';

  @override
  String get language_esperanto => 'Esperanto';

  @override
  String get language_estonian => 'Estų';

  @override
  String get language_finnish => 'Suomių';

  @override
  String get language_french => 'Prancūzų';

  @override
  String get language_galician => 'Galisų';

  @override
  String get language_georgian => 'Gruzinų';

  @override
  String get language_german => 'Vokiečių';

  @override
  String get language_greek => 'Graikų';

  @override
  String get language_gujarati => 'Gudžaratų';

  @override
  String get language_haitian => 'Haičio';

  @override
  String get language_hebrew => 'Hebrajų';

  @override
  String get language_hindi => 'Hindi';

  @override
  String get language_hungarian => 'Vengrų';

  @override
  String get language_icelandic => 'Islandų';

  @override
  String get language_indonesian => 'Indoneziečių';

  @override
  String get language_irish => 'Airių';

  @override
  String get language_italian => 'Italų';

  @override
  String get language_japanese => 'Japonų';

  @override
  String get language_kannada => 'Kanadų';

  @override
  String get language_korean => 'Korėjiečių';

  @override
  String get language_latvian => 'Latvių';

  @override
  String get language_lithuanian => 'Lietuvių';

  @override
  String get language_macedonian => 'Makedonų';

  @override
  String get language_malay => 'Malajų';

  @override
  String get language_maltese => 'Maltiečių';

  @override
  String get language_marathi => 'Maratų';

  @override
  String get language_norwegian => 'Norvegų';

  @override
  String get language_persian => 'Persų';

  @override
  String get language_polish => 'Lenkų';

  @override
  String get language_portuguese => 'Portugalų';

  @override
  String get language_romanian => 'Rumunų';

  @override
  String get language_russian => 'Rusų';

  @override
  String get language_slovak => 'Slovakų';

  @override
  String get language_slovenian => 'Slovėnų';

  @override
  String get language_spanish => 'Ispanų';

  @override
  String get language_swahili => 'Suahilių';

  @override
  String get language_swedish => 'Švedų';

  @override
  String get language_tagalog => 'Tagalų';

  @override
  String get language_tamil => 'Tamilų';

  @override
  String get language_telugu => 'Telugu';

  @override
  String get language_thai => 'Tajų';

  @override
  String get language_turkish => 'Turkų';

  @override
  String get language_ukrainian => 'Ukrainiečių';

  @override
  String get language_urdu => 'Urdu';

  @override
  String get language_vietnamese => 'Vietnamiečių';

  @override
  String get language_welsh => 'Valų';

  @override
  String get enjoying_app => 'Patinka Screen Translate?';

  @override
  String get review_prompt_message =>
      'Norėtume išgirsti jūsų nuomonę! Ar norėtumėte įvertinti programėlę Google Play?';

  @override
  String get rate_now => 'Vertinti dabar';

  @override
  String get not_now => 'Ne dabar';

  @override
  String get cannot_open_store => 'Nepavyko atidaryti Google Play parduotuvės';

  @override
  String get api_key_required => 'Reikalingas API raktas';

  @override
  String get api_key_setup_prompt =>
      'Nustatykite savo ChatGLM API raktą AI vertimui.';

  @override
  String get go_to_settings => 'Eiti į Nustatymus';

  @override
  String get api_key_dialog_title => 'AI Vertimo API Konfigūracija';

  @override
  String get api_key_configuration_title => 'ChatGLM AI Vertimas';

  @override
  String get api_key_get_key_from =>
      'Norėdami naudoti ChatGLM vertimus, turite gauti nemokamą API raktą iš ';

  @override
  String get api_key_configuration_steps => 'API Rakto Konfigūravimo Žingsniai';

  @override
  String get api_key_step_1 =>
      '1. Apsilankykite open.bigmodel.cn ir sukurkite paskyrą';

  @override
  String get api_key_step_2 => '2. Eikite į API Valdymo skyrių';

  @override
  String get api_key_step_3 =>
      '3. Sugeneruokite naują API raktą savo programėlei';

  @override
  String get api_key_input_label => 'ChatGLM API Raktas';

  @override
  String get api_key_input_hint => 'Įveskite savo ChatGLM API raktą';

  @override
  String get api_key_input_error => 'Prašome įvesti galiojantį API raktą';

  @override
  String get api_key_save_button => 'Išsaugoti API Raktą';

  @override
  String get api_key_note =>
      'Jūsų API raktas bus saugiai saugomas ir naudojamas tik vertimo paslaugoms.';

  @override
  String get api_key_save_error =>
      'Netinkamas API raktas. Patikrinkite ir bandykite dar kartą.';

  @override
  String get api_key_save_success => 'API Raktas Sėkmingai Išsaugotas';

  @override
  String get translation_mode_on_device => 'Vertimas Įrenginyje';

  @override
  String get translation_mode_on_device_description =>
      'Naudoja įtaisytus vertimo modelius jūsų įrenginyje. Greitas ir veikia be interneto, tačiau gali turėti ribotą kalbų palaikymą ir tikslumą.';

  @override
  String get translation_mode_ai => 'AI Vertimas';

  @override
  String get translation_mode_ai_description =>
      'Naudoja pažangius AI modelius tikslesnėms ir kontekstinėms vertimams. Reikalauja interneto ryšio ir API rakto.';

  @override
  String get translation_mode_title => 'Vertimo Režimas';

  @override
  String get translation_mode_on_device_label => 'Įrenginyje';

  @override
  String get translation_mode_ai_label => 'AI';

  @override
  String get close => 'Uždaryti';

  @override
  String get translation_settings_title => 'Vertimo nustatymai';

  @override
  String get translation_quality_section => 'VERTIMO KOKYBĖ';

  @override
  String get mode_quick_title => 'Greitas';

  @override
  String get mode_quick_subtitle =>
      'Momentinis · Visada pasiekiamas · Nereikia jokio nustatymo';

  @override
  String get mode_ai_enhanced_title => 'Patobulintas DI';

  @override
  String get mode_ai_enhanced_subtitle =>
      'Geresnė kokybė · Veikia neprisijungus · Atsisiųskite kalbos paketą';

  @override
  String get mode_cloud_ai_title => 'Debesijos DI';

  @override
  String get mode_cloud_ai_subtitle =>
      'Geriausia kokybė · Reikalingas internetas · Reikalingas API raktas';

  @override
  String language_packs_header(String size) {
    return 'Kalbų paketai  ·  po ~$size';
  }

  @override
  String pack_downloading_progress(String percent) {
    return 'Atsisiunčiama… $percent%';
  }

  @override
  String get pack_ready_to_use => 'Paruošta naudoti';

  @override
  String get pack_failed_tap_retry =>
      'Nepavyko — bakstelėkite, kad bandytumėte dar kartą';

  @override
  String get pack_ready_badge => 'Paruošta';

  @override
  String get retry => 'Bandyti dar kartą';

  @override
  String pack_is_ready_snackbar(String name) {
    return '$name paruoštas!';
  }

  @override
  String get download_failed_connection =>
      'Atsisiuntimas nepavyko. Patikrinkite ryšį.';

  @override
  String get remove_language_pack_title => 'Pašalinti kalbos paketą?';

  @override
  String remove_ai_pack_confirm(String name) {
    return 'Pašalinti neprisijungimo DI paketą, skirtą $name?';
  }

  @override
  String remove_quick_pack_confirm(String name) {
    return 'Pašalinti neprisijungimo greito vertimo paketą, skirtą $name?';
  }

  @override
  String get failed_to_remove_pack => 'Nepavyko pašalinti kalbos paketo.';

  @override
  String get connect_ai_account_title => 'Prijunkite savo DI paskyrą';

  @override
  String get connect_ai_account_prefix => 'Gaukite nemokamą API raktą iš ';

  @override
  String get connect_ai_account_suffix => ' ir įklijuokite jį žemiau.';

  @override
  String get api_key_hint_short => 'Įklijuokite savo API raktą čia';

  @override
  String get save_and_verify => 'Išsaugoti ir patvirtinti';

  @override
  String get cloud_ai_connected => 'Prisijungta! Debesijos DI paruoštas.';

  @override
  String get advanced_section_label => 'Papildoma';

  @override
  String get text_merge_sensitivity_title => 'Teksto sujungimo jautrumas';

  @override
  String get text_merge_sensitivity_description =>
      'Valdo, kaip grupuojami netoliese esantys teksto blokai. Sumažinkite, jei sumažėja vertimo tikslumas.';

  @override
  String get merge_precise => 'Tikslus';

  @override
  String get merge_aggressive => 'Agresyvus';

  @override
  String get select_language_pair_hint => 'Pasirinkite kalbų porą';

  @override
  String get download_ai_model_title => 'Atsisiųsti vietinį DI modelį?';

  @override
  String get download_ai_model_description =>
      'Šis paketas paprastai yra 100–500 MB. Jis atsisiunčiamas fone; ši pora bus paruošta naudoti, kai tik baigsis atsisiuntimas.';

  @override
  String error_prefix(String error) {
    return 'Klaida: $error';
  }

  @override
  String get translate_image_button => 'Versti vaizdą';

  @override
  String get choose_translation_text =>
      'Pasirinkite, kaip norite versti tekstą';

  @override
  String get download_language_pack_title => 'Atsisiųsti kalbos paketą';

  @override
  String get download_language_pack_content =>
      'Norėdami naudoti patobulintą DI režimą, pirmiausia atsisiųskite kalbos paketą.\n\nEikite į Nustatymus, kad jį atsisiųstumėte.';

  @override
  String get cloud_ai_api_key_required_content =>
      'Debesijos DI reikalauja API rakto. Nustatykite jį Nustatymuose.';

  @override
  String get mode_ai_short_label => 'DI';

  @override
  String get mode_cloud_short_label => 'Debesija';

  @override
  String get image_translation_title => 'Vaizdo vertimas';
}
