// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get app_title => 'Ekran çevirisi';

  @override
  String get source_language => 'Kaynak';

  @override
  String get target_language => 'Hedef';

  @override
  String get stop_translation => 'Çeviriyi durdur';

  @override
  String get translate_screen => 'Ekranı çevir';

  @override
  String get source_and_target_cannot_be_the_same =>
      'Kaynak ve hedef dil aynı olamaz';

  @override
  String get manage_translation_models => 'Çeviri modellerini yönet';

  @override
  String model_download_success(Object language) {
    return '$language modeli başarıyla indirildi';
  }

  @override
  String model_download_error(Object language) {
    return '$language modeli indirilirken hata oluştu';
  }

  @override
  String get model_not_downloaded => 'Model indirilmedi';

  @override
  String get download_model => 'İndir';

  @override
  String get remove_translation_model => 'Çeviri modelini kaldır';

  @override
  String remove_translation_model_confirmation(Object language) {
    return 'Kaynak dildeki çeviri modelini silmek istediğinizden emin misiniz? $language';
  }

  @override
  String get cancel => 'Iptal';

  @override
  String get remove => 'Kaldır';

  @override
  String get not_installed => 'Yok';

  @override
  String get downloading => 'Indiriliyor...';

  @override
  String get installed => 'Yüklendi';

  @override
  String get download_failed => 'Indirme hatalı';

  @override
  String failed_to_remove_model(Object language) {
    return 'Çeviri modelini kaldırırken hata oluştu: $language';
  }

  @override
  String failed_to_download_model(Object language) {
    return 'Çeviri modelini indirirken hata oluştu: $language';
  }

  @override
  String get auto_translate_mode => 'Otomatik çeviri modülü';

  @override
  String get manual_translate_mode => 'Manuel çeviri modülü';

  @override
  String get original_text_mode => 'Orjinal metin modülü';

  @override
  String get overlay_permission_required => 'Översättningsmodell';

  @override
  String get overlay_permission_required_content =>
      'Denna programkrav dobbelklickar på skärm förstärkning';

  @override
  String get grant_permission => 'Giv tillräckliga tillräckliga';

  @override
  String get language_afrikaans => 'Afrikaanca';

  @override
  String get language_albanian => 'Arnavutça';

  @override
  String get language_arabic => 'Arapça';

  @override
  String get language_belarusian => 'Belarusça';

  @override
  String get language_bengali => 'Bengalce';

  @override
  String get language_bulgarian => 'Bulgarca';

  @override
  String get language_catalan => 'Katalanca';

  @override
  String get language_chinese => 'Çince';

  @override
  String get language_croatian => 'Hırvatça';

  @override
  String get language_czech => 'Çekçe';

  @override
  String get language_danish => 'Danca';

  @override
  String get language_dutch => 'Hollandaca';

  @override
  String get language_english => 'İngilizce';

  @override
  String get language_esperanto => 'Esperanto';

  @override
  String get language_estonian => 'Estonca';

  @override
  String get language_finnish => 'Fince';

  @override
  String get language_french => 'Fransızca';

  @override
  String get language_galician => 'Galiçyaca';

  @override
  String get language_georgian => 'Gürcüce';

  @override
  String get language_german => 'Almanca';

  @override
  String get language_greek => 'Yunanca';

  @override
  String get language_gujarati => 'Gujaratice';

  @override
  String get language_haitian => 'Haiti Kreolü';

  @override
  String get language_hebrew => 'İbranice';

  @override
  String get language_hindi => 'Hintçe';

  @override
  String get language_hungarian => 'Macarca';

  @override
  String get language_icelandic => 'İzlandaca';

  @override
  String get language_indonesian => 'Endonezce';

  @override
  String get language_irish => 'İrlandaca';

  @override
  String get language_italian => 'İtalyanca';

  @override
  String get language_japanese => 'Japonca';

  @override
  String get language_kannada => 'Kannada';

  @override
  String get language_korean => 'Korece';

  @override
  String get language_latvian => 'Letonca';

  @override
  String get language_lithuanian => 'Litvanca';

  @override
  String get language_macedonian => 'Makedonca';

  @override
  String get language_malay => 'Malayca';

  @override
  String get language_maltese => 'Maltaca';

  @override
  String get language_marathi => 'Maratice';

  @override
  String get language_norwegian => 'Norveççe';

  @override
  String get language_persian => 'Farsça';

  @override
  String get language_polish => 'Lehçe';

  @override
  String get language_portuguese => 'Portekizce';

  @override
  String get language_romanian => 'Romence';

  @override
  String get language_russian => 'Rusça';

  @override
  String get language_slovak => 'Slovakça';

  @override
  String get language_slovenian => 'Slovence';

  @override
  String get language_spanish => 'İspanyolca';

  @override
  String get language_swahili => 'Svahilice';

  @override
  String get language_swedish => 'İsveççe';

  @override
  String get language_tagalog => 'Tagalogca';

  @override
  String get language_tamil => 'Tamilce';

  @override
  String get language_telugu => 'Teluguca';

  @override
  String get language_thai => 'Tayca';

  @override
  String get language_turkish => 'Türkçe';

  @override
  String get language_ukrainian => 'Ukraynaca';

  @override
  String get language_urdu => 'Urduca';

  @override
  String get language_vietnamese => 'Vietnamca';

  @override
  String get language_welsh => 'Galce';

  @override
  String get enjoying_app => 'Screen Translate\'ten memnun musunuz?';

  @override
  String get review_prompt_message =>
      'Geri bildiriminizi duymak isteriz! Google Play\'de uygulamayı değerlendirir misiniz?';

  @override
  String get rate_now => 'Şimdi Değerlendir';

  @override
  String get not_now => 'Şimdi Değil';

  @override
  String get cannot_open_store => 'Google Play Store açılamadı';

  @override
  String get api_key_required => 'API Anahtarı Gerekli';

  @override
  String get api_key_setup_prompt =>
      'AI çevirisi için ChatGLM API anahtarınızı ayarlayın.';

  @override
  String get go_to_settings => 'Ayarlara Git';

  @override
  String get api_key_dialog_title => 'AI Çeviri API Yapılandırması';

  @override
  String get api_key_configuration_title => 'ChatGLM AI Çevirisi';

  @override
  String get api_key_get_key_from =>
      'ChatGLM çevirilerini kullanmak için ücretsiz bir API anahtarı almanız gerekiyor ';

  @override
  String get api_key_configuration_steps =>
      'API Anahtarı Yapılandırma Adımları';

  @override
  String get api_key_step_1 =>
      '1. open.bigmodel.cn\'yi ziyaret edin ve bir hesap oluşturun';

  @override
  String get api_key_step_2 => '2. API Yönetimi bölümüne gidin';

  @override
  String get api_key_step_3 =>
      '3. Uygulamanız için yeni bir API anahtarı oluşturun';

  @override
  String get api_key_input_label => 'ChatGLM API Anahtarı';

  @override
  String get api_key_input_hint => 'ChatGLM API anahtarınızı girin';

  @override
  String get api_key_input_error => 'Lütfen geçerli bir API anahtarı girin';

  @override
  String get api_key_save_button => 'API Anahtarını Kaydet';

  @override
  String get api_key_note =>
      'API anahtarınız güvenli bir şekilde depolanacak ve yalnızca çeviri hizmetleri için kullanılacaktır.';

  @override
  String get api_key_save_error =>
      'Geçersiz API Anahtarı. Kontrol edip tekrar deneyin.';

  @override
  String get api_key_save_success => 'API Anahtarı Başarıyla Kaydedildi';

  @override
  String get translation_mode_on_device => 'Cihaz İçi Çeviri';

  @override
  String get translation_mode_on_device_description =>
      'Cihazınızdaki yerleşik çeviri modellerini kullanır. Hızlı ve çevrimdışı çalışır, ancak sınırlı dil desteği ve doğruluk olabilir.';

  @override
  String get translation_mode_ai => 'AI Çevirisi';

  @override
  String get translation_mode_ai_description =>
      'Daha doğru ve bağlamsal çeviriler için gelişmiş AI modellerini kullanır. İnternet bağlantısı ve API anahtarı gerektirir.';

  @override
  String get translation_mode_title => 'Çeviri Modu';

  @override
  String get translation_mode_on_device_label => 'Cihaz İçi';

  @override
  String get translation_mode_ai_label => 'AI';

  @override
  String get close => 'Kapat';
}
