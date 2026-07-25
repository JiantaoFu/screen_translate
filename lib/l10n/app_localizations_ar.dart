// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get app_title => 'ترجمة الشاشة';

  @override
  String get source_language => 'من';

  @override
  String get target_language => 'إلى';

  @override
  String get stop_translation => 'إيقاف الترجمة';

  @override
  String get translate_screen => 'ترجمة الشاشة';

  @override
  String get source_and_target_cannot_be_the_same =>
      'لا يمكن أن تكون لغة المصدر والهدف متطابقة';

  @override
  String get manage_translation_models => 'إدارة نماذج الترجمة';

  @override
  String model_download_success(Object language) {
    return 'تم تنزيل نموذج $language بنجاح';
  }

  @override
  String model_download_error(Object language) {
    return 'حدث خطأ أثناء تنزيل نموذج $language';
  }

  @override
  String get model_not_downloaded => 'لم يتم تنزيل النموذج';

  @override
  String get download_model => 'تنزيل';

  @override
  String get remove_translation_model => 'حذف نموذج الترجمة';

  @override
  String remove_translation_model_confirmation(Object language) {
    return 'هل تريد حذف نموذج الترجمة للغة $language؟';
  }

  @override
  String get cancel => 'الغاء';

  @override
  String get remove => 'حذف';

  @override
  String get not_installed => 'لم يتم تنزيل';

  @override
  String get downloading => 'تنزيل...';

  @override
  String get installed => 'تم تنزيل';

  @override
  String get download_failed => 'فشل تنزيل';

  @override
  String failed_to_remove_model(Object language) {
    return 'فشل حذف نموذج $language';
  }

  @override
  String failed_to_download_model(Object language) {
    return 'فشل تنزيل نموذج $language';
  }

  @override
  String get auto_translate_mode => 'مودة الترجمة الاوتوماتيكية';

  @override
  String get manual_translate_mode => 'مودة الترجمة اليدوي';

  @override
  String get original_text_mode => 'مودة النص الأصلي';

  @override
  String get overlay_permission_required => 'المسموح لرسم على الشاشة';

  @override
  String get overlay_permission_required_content =>
      'هذا البرنامج يحتاج اذن لرسم على الشاشة';

  @override
  String get grant_permission => 'المسموح';

  @override
  String get language_afrikaans => 'الأفريكانية';

  @override
  String get language_albanian => 'الألبانية';

  @override
  String get language_arabic => 'العربية';

  @override
  String get language_belarusian => 'البيلاروسية';

  @override
  String get language_bengali => 'البنغالية';

  @override
  String get language_bulgarian => 'البلغارية';

  @override
  String get language_catalan => 'الكتالانية';

  @override
  String get language_chinese => 'الصينية';

  @override
  String get language_croatian => 'الكرواتية';

  @override
  String get language_czech => 'التشيكية';

  @override
  String get language_danish => 'الدنماركية';

  @override
  String get language_dutch => 'الهولندية';

  @override
  String get language_english => 'الإنجليزية';

  @override
  String get language_esperanto => 'الإسبرانتو';

  @override
  String get language_estonian => 'الإستونية';

  @override
  String get language_finnish => 'الفنلندية';

  @override
  String get language_french => 'الفرنسية';

  @override
  String get language_galician => 'الجاليكية';

  @override
  String get language_georgian => 'الجورجية';

  @override
  String get language_german => 'الألمانية';

  @override
  String get language_greek => 'اليونانية';

  @override
  String get language_gujarati => 'الغوجاراتية';

  @override
  String get language_haitian => 'الهايتية';

  @override
  String get language_hebrew => 'العبرية';

  @override
  String get language_hindi => 'الهندية';

  @override
  String get language_hungarian => 'المجرية';

  @override
  String get language_icelandic => 'الآيسلندية';

  @override
  String get language_indonesian => 'الإندونيسية';

  @override
  String get language_irish => 'الأيرلندية';

  @override
  String get language_italian => 'الإيطالية';

  @override
  String get language_japanese => 'اليابانية';

  @override
  String get language_kannada => 'الكانادا';

  @override
  String get language_korean => 'الكورية';

  @override
  String get language_latvian => 'اللاتفية';

  @override
  String get language_lithuanian => 'الليتوانية';

  @override
  String get language_macedonian => 'المقدونية';

  @override
  String get language_malay => 'الملايو';

  @override
  String get language_maltese => 'المالطية';

  @override
  String get language_marathi => 'المراثية';

  @override
  String get language_norwegian => 'النرويجية';

  @override
  String get language_persian => 'الفارسية';

  @override
  String get language_polish => 'البولندية';

  @override
  String get language_portuguese => 'البرتغالية';

  @override
  String get language_romanian => 'الرومانية';

  @override
  String get language_russian => 'الروسية';

  @override
  String get language_slovak => 'السلوفاكية';

  @override
  String get language_slovenian => 'السلوفينية';

  @override
  String get language_spanish => 'الإسبانية';

  @override
  String get language_swahili => 'السواحيلية';

  @override
  String get language_swedish => 'السويدية';

  @override
  String get language_tagalog => 'التاغالوغية';

  @override
  String get language_tamil => 'التاميلية';

  @override
  String get language_telugu => 'التيلوغوية';

  @override
  String get language_thai => 'التايلاندية';

  @override
  String get language_turkish => 'التركية';

  @override
  String get language_ukrainian => 'الأوكرانية';

  @override
  String get language_urdu => 'الأردية';

  @override
  String get language_vietnamese => 'الفيتنامية';

  @override
  String get language_welsh => 'الويلزية';

  @override
  String get enjoying_app => 'هل تستمتع بـ Screen Translate؟';

  @override
  String get review_prompt_message =>
      'نود سماع رأيك! هل ترغب في تقييم التطبيق على Google Play؟';

  @override
  String get rate_now => 'قيّم الآن';

  @override
  String get not_now => 'ليس الآن';

  @override
  String get cannot_open_store => 'تعذر فتح متجر Google Play';

  @override
  String get api_key_required => 'مطلوب مفتاح API';

  @override
  String get api_key_setup_prompt =>
      'يرجى إعداد مفتاح ChatGLM API للترجمة باستخدام الذكاء الاصطناعي.';

  @override
  String get go_to_settings => 'الذهاب إلى الإعدادات';

  @override
  String get api_key_dialog_title =>
      'إعداد واجهة برمجة التطبيقات للترجمة بالذكاء الاصطناعي';

  @override
  String get api_key_configuration_title => 'ترجمة ChatGLM بالذكاء الاصطناعي';

  @override
  String get api_key_get_key_from =>
      'لاستخدام ترجمات ChatGLM، تحتاج إلى الحصول على مفتاح API مجاني من ';

  @override
  String get api_key_configuration_steps => 'خطوات إعداد مفتاح API';

  @override
  String get api_key_step_1 => '1. قم بزيارة open.bigmodel.cn وإنشاء حساب';

  @override
  String get api_key_step_2 => '2. انتقل إلى قسم إدارة API';

  @override
  String get api_key_step_3 => '3. قم بإنشاء مفتاح API جديد لتطبيقك';

  @override
  String get api_key_input_label => 'مفتاح API الخاص بـ ChatGLM';

  @override
  String get api_key_input_hint => 'أدخل مفتاح API الخاص بـ ChatGLM';

  @override
  String get api_key_input_error => 'يرجى إدخال مفتاح API صالح';

  @override
  String get api_key_save_button => 'حفظ مفتاح API';

  @override
  String get api_key_note =>
      'سيتم تخزين مفتاح API الخاص بك بشكل آمن واستخدامه فقط لخدمات الترجمة.';

  @override
  String get api_key_save_error =>
      'مفتاح API غير صالح. يرجى التحقق والمحاولة مرة أخرى.';

  @override
  String get api_key_save_success => 'تم حفظ مفتاح API بنجاح';

  @override
  String get translation_mode_on_device => 'الترجمة على الجهاز';

  @override
  String get translation_mode_on_device_description =>
      'يستخدم نماذج الترجمة المدمجة على جهازك. سريع ويعمل دون اتصال بالإنترنت، ولكن قد يكون دعم اللغة والدقة محدودًا.';

  @override
  String get translation_mode_ai => 'الترجمة بالذكاء الاصطناعي';

  @override
  String get translation_mode_ai_description =>
      'يستخدم نماذج الذكاء الاصطناعي المتقدمة للحصول على ترجمات أكثر دقة وسياقًا. يتطلب اتصالًا بالإنترنت ومفتاح API.';

  @override
  String get translation_mode_title => 'وضع الترجمة';

  @override
  String get translation_mode_on_device_label => 'على الجهاز';

  @override
  String get translation_mode_ai_label => 'الذكاء الاصطناعي';

  @override
  String get close => 'إغلاق';
}
