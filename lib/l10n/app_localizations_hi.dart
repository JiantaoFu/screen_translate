// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get app_title => 'स्क्रीन अनुवाद';

  @override
  String get source_language => 'से';

  @override
  String get target_language => 'तक';

  @override
  String get stop_translation => 'अनुवाद रोकें';

  @override
  String get translate_screen => 'स्क्रीन का अनुवाद करें';

  @override
  String get source_and_target_cannot_be_the_same =>
      'स्रोत और लक्ष्य भाषा समान नहीं हो सकती';

  @override
  String get manage_translation_models => 'अनुवाद मॉडल प्रबंधित करें';

  @override
  String model_download_success(Object language) {
    return '$language मॉडल सफलतापूर्वक डाउनलोड किया गया';
  }

  @override
  String model_download_error(Object language) {
    return '$language मॉडल डाउनलोड करने में त्रुटि';
  }

  @override
  String get model_not_downloaded => 'मॉडल डाउनलोड नहीं किया गया';

  @override
  String get download_model => 'डाउनलोड करें';

  @override
  String get remove_translation_model => 'मॉडल तरक्की हटाएं';

  @override
  String remove_translation_model_confirmation(Object language) {
    return 'आप किस भाषा के लिए यह अनुवाद मॉडल हटाना चाहते हैं?';
  }

  @override
  String get cancel => 'रद्द करना';

  @override
  String get remove => 'हटाना';

  @override
  String get not_installed => 'निर्माण नहीं किया गया';

  @override
  String get downloading => 'डाउनलोड हो रहा है';

  @override
  String get installed => 'निर्माण किया गया';

  @override
  String get download_failed => 'डाउनलोड नहीं किया गया';

  @override
  String failed_to_remove_model(Object language) {
    return 'अनुवाद मॉडल $language हटाने में त्रुटि';
  }

  @override
  String failed_to_download_model(Object language) {
    return 'अनुवाद मॉडल $language डाउनलोड करने में त्रुटि';
  }

  @override
  String get auto_translate_mode => 'ऑटो अनुवाद मोड';

  @override
  String get manual_translate_mode => 'व्यक्तिगत अनुवाद मोड';

  @override
  String get original_text_mode => 'उर्व्यवस्थित टेक्स्ट मोड';

  @override
  String get overlay_permission_required => 'अनुवाद मोड';

  @override
  String get overlay_permission_required_content =>
      'अनुवाद मोड के लिए आपकी अनुमति आवश्यक है';

  @override
  String get grant_permission => 'अनुमति आवश्यक';

  @override
  String get language_afrikaans => 'अफ्रीकी';

  @override
  String get language_albanian => 'अल्बानियाई';

  @override
  String get language_arabic => 'अरबी';

  @override
  String get language_belarusian => 'बेलारूसी';

  @override
  String get language_bengali => 'बंगाली';

  @override
  String get language_bulgarian => 'बल्गेरियाई';

  @override
  String get language_catalan => 'कैटलन';

  @override
  String get language_chinese => 'चीनी';

  @override
  String get language_croatian => 'क्रोएशियाई';

  @override
  String get language_czech => 'चेक';

  @override
  String get language_danish => 'डेनिश';

  @override
  String get language_dutch => 'डच';

  @override
  String get language_english => 'अंग्रेज़ी';

  @override
  String get language_esperanto => 'एस्पेरांतो';

  @override
  String get language_estonian => 'एस्तोनियाई';

  @override
  String get language_finnish => 'फ़िनिश';

  @override
  String get language_french => 'फ्रेंच';

  @override
  String get language_galician => 'गैलिशियन';

  @override
  String get language_georgian => 'जॉर्जियाई';

  @override
  String get language_german => 'जर्मन';

  @override
  String get language_greek => 'ग्रीक';

  @override
  String get language_gujarati => 'गुजराती';

  @override
  String get language_haitian => 'हैतियन';

  @override
  String get language_hebrew => 'हिब्रू';

  @override
  String get language_hindi => 'हिंदी';

  @override
  String get language_hungarian => 'हंगेरियन';

  @override
  String get language_icelandic => 'आइसलैंडिक';

  @override
  String get language_indonesian => 'इंडोनेशियाई';

  @override
  String get language_irish => 'आयरिश';

  @override
  String get language_italian => 'इतालवी';

  @override
  String get language_japanese => 'जापानी';

  @override
  String get language_kannada => 'कन्नड़';

  @override
  String get language_korean => 'कोरियाई';

  @override
  String get language_latvian => 'लातवियाई';

  @override
  String get language_lithuanian => 'लिथुआनियाई';

  @override
  String get language_macedonian => 'मैसेडोनियन';

  @override
  String get language_malay => 'मलय';

  @override
  String get language_maltese => 'माल्टीज़';

  @override
  String get language_marathi => 'मराठी';

  @override
  String get language_norwegian => 'नॉर्वेजियन';

  @override
  String get language_persian => 'फ़ारसी';

  @override
  String get language_polish => 'पोलिश';

  @override
  String get language_portuguese => 'पुर्तगाली';

  @override
  String get language_romanian => 'रोमानियाई';

  @override
  String get language_russian => 'रूसी';

  @override
  String get language_slovak => 'स्लोवाक';

  @override
  String get language_slovenian => 'स्लोवेनियाई';

  @override
  String get language_spanish => 'स्पेनिश';

  @override
  String get language_swahili => 'स्वाहिली';

  @override
  String get language_swedish => 'स्वीडिश';

  @override
  String get language_tagalog => 'तागालोग';

  @override
  String get language_tamil => 'तमिल';

  @override
  String get language_telugu => 'तेलुगु';

  @override
  String get language_thai => 'थाई';

  @override
  String get language_turkish => 'तुर्की';

  @override
  String get language_ukrainian => 'यूक्रेनी';

  @override
  String get language_urdu => 'उर्दू';

  @override
  String get language_vietnamese => 'वियतनामी';

  @override
  String get language_welsh => 'वेल्श';

  @override
  String get enjoying_app => 'क्या आपको स्क्रीन अनुवाद पसंद आ रहा है?';

  @override
  String get review_prompt_message =>
      'हमें आपकी राय जानने में खुशी होगी! क्या आप गूगल प्ले स्टोर पर हमारे ऐप को रेट करना चाहेंगे?';

  @override
  String get rate_now => 'अब रेट करें';

  @override
  String get not_now => 'अब नहीं';

  @override
  String get cannot_open_store => 'गूगल प्ले स्टोर नहीं खोला जा सकता';

  @override
  String get api_key_required => 'API कुंजी आवश्यक है';

  @override
  String get api_key_setup_prompt =>
      'कृपया AI अनुवाद का उपयोग करने के लिए अपनी ChatGLM API कुंजी सेट करें।';

  @override
  String get go_to_settings => 'सेटिंग्स पर जाएं';

  @override
  String get api_key_dialog_title => 'AI अनुवाद API कॉन्फ़िगरेशन';

  @override
  String get api_key_configuration_title => 'ChatGLM AI अनुवाद';

  @override
  String get api_key_get_key_from =>
      'ChatGLM अनुवाद का उपयोग करने के लिए, आपको से एक मुफ्त API कुंजी प्राप्त करनी होगी ';

  @override
  String get api_key_configuration_steps => 'API कुंजी कॉन्फ़िगरेशन चरण';

  @override
  String get api_key_step_1 => '1. open.bigmodel.cn पर जाएं और एक खाता बनाएं';

  @override
  String get api_key_step_2 => '2. API प्रबंधन अनुभाग पर नेविगेट करें';

  @override
  String get api_key_step_3 =>
      '3. अपने एप्लिकेशन के लिए एक नई API कुंजी जनरेट करें';

  @override
  String get api_key_input_label => 'ChatGLM API कुंजी';

  @override
  String get api_key_input_hint => 'अपनी ChatGLM API कुंजी दर्ज करें';

  @override
  String get api_key_input_error => 'कृपया एक वैध API कुंजी दर्ज करें';

  @override
  String get api_key_save_button => 'API कुंजी सहेजें';

  @override
  String get api_key_note =>
      'आपकी API कुंजी सुरक्षित रूप से संग्रहीत की जाएगी और केवल अनुवाद सेवाओं के लिए उपयोग की जाएगी।';

  @override
  String get api_key_save_error =>
      'अवैध API कुंजी। कृपया जांचें और फिर से प्रयास करें।';

  @override
  String get api_key_save_success => 'API कुंजी सफलतापूर्वक सहेजी गई';

  @override
  String get translation_mode_on_device => 'डिवाइस पर अनुवाद';

  @override
  String get translation_mode_on_device_description =>
      'अपने डिवाइस पर अंतर्निहित अनुवाद मॉडल का उपयोग करता है। तेज़ और ऑफ़लाइन काम करता है, लेकिन भाषा समर्थन और सटीकता सीमित हो सकती है।';

  @override
  String get translation_mode_ai => 'AI-संचालित अनुवाद';

  @override
  String get translation_mode_ai_description =>
      'अधिक सटीक और संदर्भ-संबंधी अनुवादों के लिए उन्नत AI मॉडल का उपयोग करता है। इंटरनेट कनेक्शन और API कुंजी की आवश्यकता होती है।';

  @override
  String get translation_mode_title => 'अनुवाद मोड';

  @override
  String get translation_mode_on_device_label => 'डिवाइस पर';

  @override
  String get translation_mode_ai_label => 'AI';

  @override
  String get close => 'बंद करें';
}
