// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AppLocalizationsBn extends AppLocalizations {
  AppLocalizationsBn([String locale = 'bn']) : super(locale);

  @override
  String get app_title => 'স্ক্রিন অনুবাদ';

  @override
  String get source_language => 'থেকে';

  @override
  String get target_language => 'তে';

  @override
  String get stop_translation => 'অনুবাদ বন্ধ করুন';

  @override
  String get translate_screen => 'স্ক্রিন অনুবাদ করুন';

  @override
  String get source_and_target_cannot_be_the_same =>
      'উৎস এবং লক্ষ্য ভাষা একই হতে পারে না';

  @override
  String get manage_translation_models => 'অনুবাদ মডেল পরিচালনা করুন';

  @override
  String model_download_success(Object language) {
    return '$language মডেল সফলভাবে ডাউনলোড হয়েছে';
  }

  @override
  String model_download_error(Object language) {
    return '$language মডেল ডাউনলোড করতে ত্রুটি হয়েছে';
  }

  @override
  String get model_not_downloaded => 'মডেল ডাউনলোড করা হয়নি';

  @override
  String get download_model => 'ডাউনলোড করুন';

  @override
  String get remove_translation_model => 'অনুবাদ মডেল পরিবর্তন করুন';

  @override
  String remove_translation_model_confirmation(Object language) {
    return 'আপনি কি কোন ভাষা থেকে অনুবাদ মডেল পরিবর্তন করতে চান?';
  }

  @override
  String get cancel => 'বাতিল';

  @override
  String get remove => 'পরিবর্তন';

  @override
  String get not_installed => 'নির্বাচিত';

  @override
  String get downloading => 'ডাউনলোড হচ্ছে...';

  @override
  String get installed => 'ডাউনলোড হয়েছে';

  @override
  String get download_failed => 'ডাউনলোড ব্যর্থ হয়েছে';

  @override
  String failed_to_remove_model(Object language) {
    return '$language মডেল পরিবর্তন করতে ব্যর্থ হয়েছে';
  }

  @override
  String failed_to_download_model(Object language) {
    return '$language মডেল ডাউনলোড করতে ব্যর্থ হয়েছে';
  }

  @override
  String get auto_translate_mode => 'সময় অনুবাদ মডেল';

  @override
  String get manual_translate_mode => 'মানুয়াল অনুবাদ মডেল';

  @override
  String get original_text_mode => 'স্থানী লেখা মডেল';

  @override
  String get overlay_permission_required =>
      'স্ক্রিন রিসিজ করার জন্য অনুমতি প্রদান করুন';

  @override
  String get overlay_permission_required_content =>
      'এই অ্যাপ্লিকেশনে স্ক্রিন রিসিজ করার জন্য অনুমতি প্রদান করুন';

  @override
  String get grant_permission => 'অনুমতি প্রদান';

  @override
  String get language_afrikaans => 'আফ্রিকান্স';

  @override
  String get language_albanian => 'আলবানিয়ান';

  @override
  String get language_arabic => 'আরবি';

  @override
  String get language_belarusian => 'বেলারুশিয়ান';

  @override
  String get language_bengali => 'বাংলা';

  @override
  String get language_bulgarian => 'বুলগেরিয়ান';

  @override
  String get language_catalan => 'ক্যাটালান';

  @override
  String get language_chinese => 'চীনা';

  @override
  String get language_croatian => 'ক্রোয়েশিয়ান';

  @override
  String get language_czech => 'চেক';

  @override
  String get language_danish => 'ড্যানিশ';

  @override
  String get language_dutch => 'ডাচ';

  @override
  String get language_english => 'ইংরেজি';

  @override
  String get language_esperanto => 'এস্পেরান্তো';

  @override
  String get language_estonian => 'এস্তোনিয়ান';

  @override
  String get language_finnish => 'ফিনিশ';

  @override
  String get language_french => 'ফরাসি';

  @override
  String get language_galician => 'গ্যালিশিয়ান';

  @override
  String get language_georgian => 'জর্জিয়ান';

  @override
  String get language_german => 'জার্মান';

  @override
  String get language_greek => 'গ্রিক';

  @override
  String get language_gujarati => 'গুজরাটি';

  @override
  String get language_haitian => 'হাইতিয়ান';

  @override
  String get language_hebrew => 'হিব্রু';

  @override
  String get language_hindi => 'হিন্দি';

  @override
  String get language_hungarian => 'হাঙ্গেরিয়ান';

  @override
  String get language_icelandic => 'আইসল্যান্ডিক';

  @override
  String get language_indonesian => 'ইন্দোনেশিয়ান';

  @override
  String get language_irish => 'আইরিশ';

  @override
  String get language_italian => 'ইতালিয়ান';

  @override
  String get language_japanese => 'জাপানি';

  @override
  String get language_kannada => 'কন্নড়';

  @override
  String get language_korean => 'কোরিয়ান';

  @override
  String get language_latvian => 'লাটভিয়ান';

  @override
  String get language_lithuanian => 'লিথুয়ানিয়ান';

  @override
  String get language_macedonian => 'ম্যাসেডোনিয়ান';

  @override
  String get language_malay => 'মালয়';

  @override
  String get language_maltese => 'মাল্টিজ';

  @override
  String get language_marathi => 'মারাঠি';

  @override
  String get language_norwegian => 'নরওয়েজিয়ান';

  @override
  String get language_persian => 'ফার্সি';

  @override
  String get language_polish => 'পোলিশ';

  @override
  String get language_portuguese => 'পর্তুগিজ';

  @override
  String get language_romanian => 'রোমানিয়ান';

  @override
  String get language_russian => 'রাশিয়ান';

  @override
  String get language_slovak => 'স্লোভাক';

  @override
  String get language_slovenian => 'স্লোভেনিয়ান';

  @override
  String get language_spanish => 'স্প্যানিশ';

  @override
  String get language_swahili => 'সোয়াহিলি';

  @override
  String get language_swedish => 'সুইডিশ';

  @override
  String get language_tagalog => 'তাগালগ';

  @override
  String get language_tamil => 'তামিল';

  @override
  String get language_telugu => 'তেলুগু';

  @override
  String get language_thai => 'থাই';

  @override
  String get language_turkish => 'তুর্কি';

  @override
  String get language_ukrainian => 'ইউক্রেনিয়ান';

  @override
  String get language_urdu => 'উর্দু';

  @override
  String get language_vietnamese => 'ভিয়েতনামি';

  @override
  String get language_welsh => 'ওয়েলশ';

  @override
  String get enjoying_app => 'Screen Translate কেমন লাগছে?';

  @override
  String get review_prompt_message =>
      'আমরা আপনার মতামত শুনতে চাই! Google Play-এ কি আপনি অ্যাপটি রেট করবেন?';

  @override
  String get rate_now => 'এখনই রেট করুন';

  @override
  String get not_now => 'এখন নয়';

  @override
  String get cannot_open_store => 'Google Play Store খুলতে পারছি না';

  @override
  String get api_key_required => 'API কী প্রয়োজন';

  @override
  String get api_key_setup_prompt =>
      'AI অনুবাদের জন্য আপনার ChatGLM API কী সেট করুন।';

  @override
  String get go_to_settings => 'সেটিংস-এ যান';

  @override
  String get api_key_dialog_title => 'AI অনুবাদ API কনফিগারেশন';

  @override
  String get api_key_configuration_title => 'ChatGLM AI অনুবাদ';

  @override
  String get api_key_get_key_from =>
      'ChatGLM অনুবাদ ব্যবহার করতে, আপনাকে একটি বিনামূল্যের API কী পেতে হবে ';

  @override
  String get api_key_configuration_steps => 'API কী কনফিগারেশন পদক্ষেপ';

  @override
  String get api_key_step_1 =>
      '1. open.bigmodel.cn পরিদর্শন করুন এবং একটি অ্যাকাউন্ট তৈরি করুন';

  @override
  String get api_key_step_2 => '2. API ব্যবস্থাপনা বিভাগে যান';

  @override
  String get api_key_step_3 =>
      '3. আপনার অ্যাপ্লিকেশনের জন্য একটি নতুন API কী তৈরি করুন';

  @override
  String get api_key_input_label => 'ChatGLM API কী';

  @override
  String get api_key_input_hint => 'আপনার ChatGLM API কী লিখুন';

  @override
  String get api_key_input_error => 'অনুগ্রহ করে একটি বৈধ API কী লিখুন';

  @override
  String get api_key_save_button => 'API কী সংরক্ষণ করুন';

  @override
  String get api_key_note =>
      'আপনার API কী নিরাপদে সংরক্ষিত হবে এবং শুধুমাত্র অনুবাদ পরিষেবার জন্য ব্যবহৃত হবে।';

  @override
  String get api_key_save_error => 'API কী অবৈধ। পরীক্ষা করে আবার চেষ্টা করুন।';

  @override
  String get api_key_save_success => 'API কী সফলভাবে সংরক্ষিত হয়েছে';

  @override
  String get translation_mode_on_device => 'ডিভাইসে অনুবাদ';

  @override
  String get translation_mode_on_device_description =>
      'আপনার ডিভাইসে অন্তর্নিহিত অনুবাদ মডেল ব্যবহার করে। দ্রুত এবং অফলাইনে কাজ করে, কিন্তু ভাষা সমর্থন এবং সঠিকতা সীমিত হতে পারে।';

  @override
  String get translation_mode_ai => 'AI-চালিত অনুবাদ';

  @override
  String get translation_mode_ai_description =>
      'আরও সঠিক এবং সংদর্ভগত অনুবাদের জন্য উন্নত AI মডেল ব্যবহার করে। ইন্টারনেট সংযোগ এবং API কী প্রয়োজন।';

  @override
  String get translation_mode_title => 'অনুবাদ মোড';

  @override
  String get translation_mode_on_device_label => 'ডিভাইসে';

  @override
  String get translation_mode_ai_label => 'AI';

  @override
  String get close => 'বন্ধ';
}
