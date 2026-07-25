// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Finnish (`fi`).
class AppLocalizationsFi extends AppLocalizations {
  AppLocalizationsFi([String locale = 'fi']) : super(locale);

  @override
  String get app_title => 'Näytön kääntäminen';

  @override
  String get source_language => 'Lähtökieli';

  @override
  String get target_language => 'Kohdekieli';

  @override
  String get stop_translation => 'Lopeta kääntäminen';

  @override
  String get translate_screen => 'Käännä näyttö';

  @override
  String get source_and_target_cannot_be_the_same =>
      'Lähde- ja kohdekieli eivät voi olla samat';

  @override
  String get manage_translation_models => 'Hallitse käännösmalleja';

  @override
  String model_download_success(Object language) {
    return 'Malli kielelle $language ladattu onnistuneesti';
  }

  @override
  String model_download_error(Object language) {
    return 'Virhe ladattaessa mallia kielelle $language';
  }

  @override
  String get model_not_downloaded => 'Mallia ei ole ladattu';

  @override
  String get download_model => 'Lataa';

  @override
  String get remove_translation_model => 'Poista käännösmalli';

  @override
  String remove_translation_model_confirmation(Object language) {
    return 'Haluatko varmasti poistaa käännösmallin kielellä $language?';
  }

  @override
  String get cancel => 'Peruuta';

  @override
  String get remove => 'Poista';

  @override
  String get not_installed => 'Ei asennettu';

  @override
  String get downloading => 'Ladataan...';

  @override
  String get installed => 'Asennettu';

  @override
  String get download_failed => 'Lataus epäonnistui';

  @override
  String failed_to_remove_model(Object language) {
    return 'Poistaminen käännösmallista epäonnistui kielellä $language';
  }

  @override
  String failed_to_download_model(Object language) {
    return 'Lataaminen käännösmallista epäonnistui kielellä $language';
  }

  @override
  String get auto_translate_mode => 'Automaattinen käännösmalli asentaminen';

  @override
  String get manual_translate_mode => 'Käännösmalli asentaminen manuaalisesti';

  @override
  String get original_text_mode => 'Käännösmalli asentaminen';

  @override
  String get overlay_permission_required => 'Käännösmalli asentaminen';

  @override
  String get overlay_permission_required_content =>
      'This program requires permission to translate on the screen.';

  @override
  String get grant_permission => 'Give permission';

  @override
  String get language_afrikaans => 'afrikaans';

  @override
  String get language_albanian => 'albania';

  @override
  String get language_arabic => 'arabia';

  @override
  String get language_belarusian => 'valkovenäjä';

  @override
  String get language_bengali => 'bengali';

  @override
  String get language_bulgarian => 'bulgaria';

  @override
  String get language_catalan => 'katalaani';

  @override
  String get language_chinese => 'kiina';

  @override
  String get language_croatian => 'kroatia';

  @override
  String get language_czech => 'tšekki';

  @override
  String get language_danish => 'tanska';

  @override
  String get language_dutch => 'hollanti';

  @override
  String get language_english => 'englanti';

  @override
  String get language_esperanto => 'esperanto';

  @override
  String get language_estonian => 'viro';

  @override
  String get language_finnish => 'suomi';

  @override
  String get language_french => 'ranska';

  @override
  String get language_galician => 'galicia';

  @override
  String get language_georgian => 'georgia';

  @override
  String get language_german => 'saksa';

  @override
  String get language_greek => 'kreikka';

  @override
  String get language_gujarati => 'gujarati';

  @override
  String get language_haitian => 'haiti';

  @override
  String get language_hebrew => 'heprea';

  @override
  String get language_hindi => 'hindi';

  @override
  String get language_hungarian => 'unkari';

  @override
  String get language_icelandic => 'islanti';

  @override
  String get language_indonesian => 'indonesia';

  @override
  String get language_irish => 'iiri';

  @override
  String get language_italian => 'italia';

  @override
  String get language_japanese => 'japani';

  @override
  String get language_kannada => 'kannada';

  @override
  String get language_korean => 'korea';

  @override
  String get language_latvian => 'latvia';

  @override
  String get language_lithuanian => 'liettua';

  @override
  String get language_macedonian => 'makedonia';

  @override
  String get language_malay => 'malaiji';

  @override
  String get language_maltese => 'malta';

  @override
  String get language_marathi => 'marathi';

  @override
  String get language_norwegian => 'norja';

  @override
  String get language_persian => 'persia';

  @override
  String get language_polish => 'puola';

  @override
  String get language_portuguese => 'portugali';

  @override
  String get language_romanian => 'romania';

  @override
  String get language_russian => 'venäjä';

  @override
  String get language_slovak => 'slovakia';

  @override
  String get language_slovenian => 'slovenia';

  @override
  String get language_spanish => 'espanja';

  @override
  String get language_swahili => 'swahili';

  @override
  String get language_swedish => 'ruotsi';

  @override
  String get language_tagalog => 'tagalog';

  @override
  String get language_tamil => 'tamili';

  @override
  String get language_telugu => 'telugu';

  @override
  String get language_thai => 'thai';

  @override
  String get language_turkish => 'turkki';

  @override
  String get language_ukrainian => 'ukraina';

  @override
  String get language_urdu => 'urdu';

  @override
  String get language_vietnamese => 'vietnam';

  @override
  String get language_welsh => 'wales';

  @override
  String get enjoying_app => 'Pidätkö Screen Translatesta?';

  @override
  String get review_prompt_message =>
      'Haluaisimme kuulla mielipiteesi! Haluatko arvioida sovelluksen Google Playssa?';

  @override
  String get rate_now => 'Arvioi nyt';

  @override
  String get not_now => 'Ei nyt';

  @override
  String get cannot_open_store => 'Google Play Storea ei voitu avata';

  @override
  String get api_key_required => 'API Key Required';

  @override
  String get api_key_setup_prompt =>
      'Please set up your ChatGLM API key to use AI translation.';

  @override
  String get go_to_settings => 'Go to Settings';

  @override
  String get api_key_dialog_title => 'AI Translation API Configuration';

  @override
  String get api_key_configuration_title => 'ChatGLM AI Translation';

  @override
  String get api_key_get_key_from =>
      'To use ChatGLM for translations, you need to obtain an free API key from ';

  @override
  String get api_key_configuration_steps => 'API Key Configuration Steps';

  @override
  String get api_key_step_1 =>
      '1. Visit open.bigmodel.cn and create an account';

  @override
  String get api_key_step_2 => '2. Navigate to API Management section';

  @override
  String get api_key_step_3 => '3. Generate a new API key for your application';

  @override
  String get api_key_input_label => 'ChatGLM API Key';

  @override
  String get api_key_input_hint => 'Enter your ChatGLM API key';

  @override
  String get api_key_input_error => 'Please enter a valid API key';

  @override
  String get api_key_save_button => 'Save API Key';

  @override
  String get api_key_note =>
      'Your API key will be securely stored and used only for translation services.';

  @override
  String get api_key_save_error =>
      'Invalid API Key. Please check and try again.';

  @override
  String get api_key_save_success => 'API Key Saved Successfully';

  @override
  String get translation_mode_on_device => 'Käännös Laitteessa';

  @override
  String get translation_mode_on_device_description =>
      'Käyttää laitteeseen sisäänrakennettuja käännösmalleja. Nopea ja toimii offline-tilassa, mutta voi olla rajoitettu kielen tuki ja tarkkuus.';

  @override
  String get translation_mode_ai => 'AI-Käännös';

  @override
  String get translation_mode_ai_description =>
      'Käyttää edistyneitä AI-malleja tarkempiin ja kontekstuaalisiin käännöksiin. Vaatii internet-yhteyden ja API-avaimen.';

  @override
  String get translation_mode_title => 'Käännöstila';

  @override
  String get translation_mode_on_device_label => 'Laitteessa';

  @override
  String get translation_mode_ai_label => 'AI';

  @override
  String get close => 'Sulje';
}
