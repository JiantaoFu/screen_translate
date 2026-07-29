// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get app_title => 'Screen Translate';

  @override
  String get source_language => 'From';

  @override
  String get target_language => 'To';

  @override
  String get stop_translation => 'Stop Translation';

  @override
  String get translate_screen => 'Translate Screen';

  @override
  String get source_and_target_cannot_be_the_same =>
      'Source and target languages cannot be the same';

  @override
  String get manage_translation_models => 'Manage Translation Models';

  @override
  String model_download_success(Object language) {
    return '$language model downloaded successfully';
  }

  @override
  String model_download_error(Object language) {
    return 'Failed to download $language model';
  }

  @override
  String get model_not_downloaded => 'Model not downloaded';

  @override
  String get download_model => 'Download';

  @override
  String get remove_translation_model => 'Remove Translation Model';

  @override
  String remove_translation_model_confirmation(Object language) {
    return 'Are you sure you want to remove the $language translation model?';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get remove => 'Remove';

  @override
  String get not_installed => 'Not Installed';

  @override
  String get downloading => 'Downloading...';

  @override
  String get installed => 'Installed';

  @override
  String get download_failed => 'Download Failed';

  @override
  String failed_to_remove_model(Object language) {
    return 'Failed to remove $language model';
  }

  @override
  String failed_to_download_model(Object language) {
    return 'Failed to download $language model';
  }

  @override
  String get auto_translate_mode => 'Auto Translate Mode';

  @override
  String get manual_translate_mode => 'Manual Translate Mode';

  @override
  String get original_text_mode => 'Original Text Mode';

  @override
  String get overlay_permission_required => 'Overlay Permission Required';

  @override
  String get overlay_permission_required_content =>
      'This app needs permission to draw over other apps.';

  @override
  String get grant_permission => 'Grant Permission';

  @override
  String get language_afrikaans => 'Afrikaans';

  @override
  String get language_albanian => 'Albanian';

  @override
  String get language_arabic => 'Arabic';

  @override
  String get language_belarusian => 'Belarusian';

  @override
  String get language_bengali => 'Bengali';

  @override
  String get language_bulgarian => 'Bulgarian';

  @override
  String get language_catalan => 'Catalan';

  @override
  String get language_chinese => 'Chinese';

  @override
  String get language_croatian => 'Croatian';

  @override
  String get language_czech => 'Czech';

  @override
  String get language_danish => 'Danish';

  @override
  String get language_dutch => 'Dutch';

  @override
  String get language_english => 'English';

  @override
  String get language_esperanto => 'Esperanto';

  @override
  String get language_estonian => 'Estonian';

  @override
  String get language_finnish => 'Finnish';

  @override
  String get language_french => 'French';

  @override
  String get language_galician => 'Galician';

  @override
  String get language_georgian => 'Georgian';

  @override
  String get language_german => 'German';

  @override
  String get language_greek => 'Greek';

  @override
  String get language_gujarati => 'Gujarati';

  @override
  String get language_haitian => 'Haitian';

  @override
  String get language_hebrew => 'Hebrew';

  @override
  String get language_hindi => 'Hindi';

  @override
  String get language_hungarian => 'Hungarian';

  @override
  String get language_icelandic => 'Icelandic';

  @override
  String get language_indonesian => 'Indonesian';

  @override
  String get language_irish => 'Irish';

  @override
  String get language_italian => 'Italian';

  @override
  String get language_japanese => 'Japanese';

  @override
  String get language_kannada => 'Kannada';

  @override
  String get language_korean => 'Korean';

  @override
  String get language_latvian => 'Latvian';

  @override
  String get language_lithuanian => 'Lithuanian';

  @override
  String get language_macedonian => 'Macedonian';

  @override
  String get language_malay => 'Malay';

  @override
  String get language_maltese => 'Maltese';

  @override
  String get language_marathi => 'Marathi';

  @override
  String get language_norwegian => 'Norwegian';

  @override
  String get language_persian => 'Persian';

  @override
  String get language_polish => 'Polish';

  @override
  String get language_portuguese => 'Portuguese';

  @override
  String get language_romanian => 'Romanian';

  @override
  String get language_russian => 'Russian';

  @override
  String get language_slovak => 'Slovak';

  @override
  String get language_slovenian => 'Slovenian';

  @override
  String get language_spanish => 'Spanish';

  @override
  String get language_swahili => 'Swahili';

  @override
  String get language_swedish => 'Swedish';

  @override
  String get language_tagalog => 'Tagalog';

  @override
  String get language_tamil => 'Tamil';

  @override
  String get language_telugu => 'Telugu';

  @override
  String get language_thai => 'Thai';

  @override
  String get language_turkish => 'Turkish';

  @override
  String get language_ukrainian => 'Ukrainian';

  @override
  String get language_urdu => 'Urdu';

  @override
  String get language_vietnamese => 'Vietnamese';

  @override
  String get language_welsh => 'Welsh';

  @override
  String get enjoying_app => 'Enjoying Screen Translate?';

  @override
  String get review_prompt_message =>
      'We\'d love to hear your feedback! Would you like to rate the app on Google Play?';

  @override
  String get rate_now => 'Rate Now';

  @override
  String get not_now => 'Not Now';

  @override
  String get cannot_open_store => 'Could not open Google Play Store';

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
  String get translation_mode_on_device => 'On-Device Translation';

  @override
  String get translation_mode_on_device_description =>
      'Uses built-in translation models on your device. Fast and works offline, but may have limited language support and accuracy.';

  @override
  String get translation_mode_ai => 'AI-Powered Translation';

  @override
  String get translation_mode_ai_description =>
      'Uses advanced AI models for more accurate and contextual translations. Requires an internet connection and API key.';

  @override
  String get translation_mode_title => 'Translation Mode';

  @override
  String get translation_mode_on_device_label => 'On-Device';

  @override
  String get translation_mode_ai_label => 'AI';

  @override
  String get close => 'Close';

  @override
  String get translation_settings_title => 'Translation Settings';

  @override
  String get translation_quality_section => 'TRANSLATION QUALITY';

  @override
  String get mode_quick_title => 'Quick';

  @override
  String get mode_quick_subtitle =>
      'Instant · Always available · No setup needed';

  @override
  String get mode_ai_enhanced_title => 'AI Enhanced';

  @override
  String get mode_ai_enhanced_subtitle =>
      'Better quality · Works offline · Download a language pack';

  @override
  String get mode_cloud_ai_title => 'Cloud AI';

  @override
  String get mode_cloud_ai_subtitle =>
      'Best quality · Requires internet · API key needed';

  @override
  String language_packs_header(String size) {
    return 'Language Packs  ·  ~$size each';
  }

  @override
  String pack_downloading_progress(String percent) {
    return 'Downloading… $percent%';
  }

  @override
  String get pack_ready_to_use => 'Ready to use';

  @override
  String get pack_failed_tap_retry => 'Failed — tap Retry';

  @override
  String get pack_ready_badge => 'Ready';

  @override
  String get retry => 'Retry';

  @override
  String pack_is_ready_snackbar(String name) {
    return '$name is ready!';
  }

  @override
  String get download_failed_connection =>
      'Download failed. Please check your connection.';

  @override
  String get remove_language_pack_title => 'Remove language pack?';

  @override
  String remove_ai_pack_confirm(String name) {
    return 'Remove the offline AI pack for $name?';
  }

  @override
  String remove_quick_pack_confirm(String name) {
    return 'Remove the offline Quick-translation pack for $name?';
  }

  @override
  String get failed_to_remove_pack => 'Failed to remove language pack.';

  @override
  String get connect_ai_account_title => 'Connect your AI account';

  @override
  String get connect_ai_account_prefix => 'Get a free API key from ';

  @override
  String get connect_ai_account_suffix => ' and paste it below.';

  @override
  String get api_key_hint_short => 'Paste your API key here';

  @override
  String get save_and_verify => 'Save & Verify';

  @override
  String get cloud_ai_connected => 'Connected! Cloud AI is ready.';

  @override
  String get advanced_section_label => 'Advanced';

  @override
  String get text_merge_sensitivity_title => 'Text merge sensitivity';

  @override
  String get text_merge_sensitivity_description =>
      'Controls how nearby text blocks are grouped. Reduce if translation accuracy drops.';

  @override
  String get merge_precise => 'Precise';

  @override
  String get merge_aggressive => 'Aggressive';

  @override
  String get select_language_pair_hint => 'Select a language pair';

  @override
  String get download_ai_model_title => 'Download local AI model?';

  @override
  String get download_ai_model_description =>
      'This pack is typically 100–500MB. It downloads in the background; this pair will be ready to use once it finishes.';

  @override
  String error_prefix(String error) {
    return 'Error: $error';
  }

  @override
  String get translate_image_button => 'Translate Image';

  @override
  String get choose_translation_text => 'Choose how you want to translate text';

  @override
  String get download_language_pack_title => 'Download a Language Pack';

  @override
  String get download_language_pack_content =>
      'To use AI Enhanced mode, download a language pack first.\n\nGo to Settings to download one.';

  @override
  String get cloud_ai_api_key_required_content =>
      'Cloud AI requires an API key. Set it up in Settings.';

  @override
  String get mode_ai_short_label => 'AI';

  @override
  String get mode_cloud_short_label => 'Cloud';

  @override
  String get image_translation_title => 'Image Translation';

  @override
  String get send_feedback => 'Send Feedback';

  @override
  String get send_feedback_subtitle => 'Report a bug or suggest a feature';

  @override
  String get ai_pair_unsupported_title => 'Language Not Supported Yet';

  @override
  String get ai_pair_unsupported_content =>
      'AI mode doesn\'t have a model for this language pair yet. Let us know you\'d like it — it helps us decide what to build next.';

  @override
  String get request_language_pair => 'Request This Language';

  @override
  String get language_request_sent => 'Thanks! We\'ve noted your request.';
}
