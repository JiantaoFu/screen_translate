// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Persian (`fa`).
class AppLocalizationsFa extends AppLocalizations {
  AppLocalizationsFa([String locale = 'fa']) : super(locale);

  @override
  String get app_title => 'ترجمه صفحه نمایش';

  @override
  String get source_language => 'از';

  @override
  String get target_language => 'به';

  @override
  String get stop_translation => 'توقف ترجمه';

  @override
  String get translate_screen => 'ترجمه صفحه نمایش';

  @override
  String get source_and_target_cannot_be_the_same =>
      'زبان مبدا و مقصد نمی‌توانند یکسان باشند';

  @override
  String get manage_translation_models => 'مدیریت مدل‌های ترجمه';

  @override
  String model_download_success(Object language) {
    return 'مدل $language با موفقیت دانلود شد';
  }

  @override
  String model_download_error(Object language) {
    return 'خطا در دانلود مدل $language';
  }

  @override
  String get model_not_downloaded => 'مدل دانلود نشده است';

  @override
  String get download_model => 'دانلود';

  @override
  String get remove_translation_model => 'حذف مدل ترجمه';

  @override
  String remove_translation_model_confirmation(Object language) {
    return 'آیا مطمئن هستید که می‌خواهید مدل ترجمه برای $language حذف شود؟';
  }

  @override
  String get cancel => 'لغو';

  @override
  String get remove => 'حذف';

  @override
  String get not_installed => 'نصب نشده است';

  @override
  String get downloading => 'دانلود...';

  @override
  String get installed => 'نصب شده است';

  @override
  String get download_failed => 'دانلود ناموفق';

  @override
  String failed_to_remove_model(Object language) {
    return 'خطا در حذف مدل $language';
  }

  @override
  String failed_to_download_model(Object language) {
    return 'خطا در دانلود مدل $language';
  }

  @override
  String get auto_translate_mode => 'مدل ترجمه';

  @override
  String get manual_translate_mode => 'ترجمه دستی';

  @override
  String get original_text_mode => 'مدل متن اصلی';

  @override
  String get overlay_permission_required => 'مدل ترجمه';

  @override
  String get overlay_permission_required_content =>
      'این برنامه نیاز به دسترسی به صفحه کاربری دارد';

  @override
  String get grant_permission => 'اعطای دسترسی';

  @override
  String get language_afrikaans => 'آفریکانس';

  @override
  String get language_albanian => 'آلبانیایی';

  @override
  String get language_arabic => 'عربی';

  @override
  String get language_belarusian => 'بلاروسی';

  @override
  String get language_bengali => 'بنگالی';

  @override
  String get language_bulgarian => 'بلغاری';

  @override
  String get language_catalan => 'کاتالان';

  @override
  String get language_chinese => 'چینی';

  @override
  String get language_croatian => 'کرواتی';

  @override
  String get language_czech => 'چکی';

  @override
  String get language_danish => 'دانمارکی';

  @override
  String get language_dutch => 'هلندی';

  @override
  String get language_english => 'انگلیسی';

  @override
  String get language_esperanto => 'اسپرانتو';

  @override
  String get language_estonian => 'استونیایی';

  @override
  String get language_finnish => 'فنلاندی';

  @override
  String get language_french => 'فرانسوی';

  @override
  String get language_galician => 'گالیسی';

  @override
  String get language_georgian => 'گرجی';

  @override
  String get language_german => 'آلمانی';

  @override
  String get language_greek => 'یونانی';

  @override
  String get language_gujarati => 'گجراتی';

  @override
  String get language_haitian => 'هائیتی';

  @override
  String get language_hebrew => 'عبری';

  @override
  String get language_hindi => 'هندی';

  @override
  String get language_hungarian => 'مجارستانی';

  @override
  String get language_icelandic => 'ایسلندی';

  @override
  String get language_indonesian => 'اندونزیایی';

  @override
  String get language_irish => 'ایرلندی';

  @override
  String get language_italian => 'ایتالیایی';

  @override
  String get language_japanese => 'ژاپنی';

  @override
  String get language_kannada => 'کانادا';

  @override
  String get language_korean => 'کره‌ای';

  @override
  String get language_latvian => 'لتونیایی';

  @override
  String get language_lithuanian => 'لیتوانیایی';

  @override
  String get language_macedonian => 'مقدونی';

  @override
  String get language_malay => 'مالایی';

  @override
  String get language_maltese => 'مالتی';

  @override
  String get language_marathi => 'مراتی';

  @override
  String get language_norwegian => 'نروژی';

  @override
  String get language_persian => 'فارسی';

  @override
  String get language_polish => 'لهستانی';

  @override
  String get language_portuguese => 'پرتغالی';

  @override
  String get language_romanian => 'رومانیایی';

  @override
  String get language_russian => 'روسی';

  @override
  String get language_slovak => 'اسلواکی';

  @override
  String get language_slovenian => 'اسلوونیایی';

  @override
  String get language_spanish => 'اسپانیایی';

  @override
  String get language_swahili => 'سواحیلی';

  @override
  String get language_swedish => 'سوئدی';

  @override
  String get language_tagalog => 'تاگالوگ';

  @override
  String get language_tamil => 'تامیل';

  @override
  String get language_telugu => 'تلوگو';

  @override
  String get language_thai => 'تایلندی';

  @override
  String get language_turkish => 'ترکی';

  @override
  String get language_ukrainian => 'اوکراینی';

  @override
  String get language_urdu => 'اردو';

  @override
  String get language_vietnamese => 'ویتنامی';

  @override
  String get language_welsh => 'ولزی';

  @override
  String get enjoying_app => 'از Screen Translate لذت می‌برید؟';

  @override
  String get review_prompt_message =>
      'ما علاقه‌مندیم نظر شما را بشنویم! آیا مایلید این برنامه را در Google Play امتیاز دهید؟';

  @override
  String get rate_now => 'امتیاز دهید';

  @override
  String get not_now => 'الان نه';

  @override
  String get cannot_open_store =>
      'امکان باز کردن فروشگاه Google Play وجود ندارد';

  @override
  String get api_key_required => 'کلید API مورد نیاز است';

  @override
  String get api_key_setup_prompt =>
      'کلید API ChatGLM خود را برای ترجمه هوش مصنوعی تنظیم کنید.';

  @override
  String get go_to_settings => 'رفتن به تنظیمات';

  @override
  String get api_key_dialog_title => 'پیکربندی API ترجمه هوش مصنوعی';

  @override
  String get api_key_configuration_title => 'ترجمه ChatGLM با هوش مصنوعی';

  @override
  String get api_key_get_key_from =>
      'برای استفاده از ترجمه‌های ChatGLM، باید یک کلید API رایگان از دریافت کنید ';

  @override
  String get api_key_configuration_steps => 'مراحل پیکربندی کلید API';

  @override
  String get api_key_step_1 =>
      '1. از open.bigmodel.cn بازدید کنید و یک حساب ایجاد کنید';

  @override
  String get api_key_step_2 => '2. به بخش مدیریت API مراجعه کنید';

  @override
  String get api_key_step_3 => '3. یک کلید API جدید برای برنامه خود ایجاد کنید';

  @override
  String get api_key_input_label => 'کلید API ChatGLM';

  @override
  String get api_key_input_hint => 'کلید API ChatGLM خود را وارد کنید';

  @override
  String get api_key_input_error => 'لطفاً یک کلید API معتبر وارد کنید';

  @override
  String get api_key_save_button => 'ذخیره کلید API';

  @override
  String get api_key_note =>
      'کلید API شما به طور امن ذخیره خواهد شد و فقط برای خدمات ترجمه استفاده می‌شود.';

  @override
  String get api_key_save_error =>
      'کلید API نامعتبر است. بررسی کنید و دوباره امتحان کنید.';

  @override
  String get api_key_save_success => 'کلید API با موفقیت ذخیره شد';

  @override
  String get translation_mode_on_device => 'ترجمه در دستگاه';

  @override
  String get translation_mode_on_device_description =>
      'از مدل‌های ترجمه داخلی در دستگاه شما استفاده می‌کند. سریع و بدون اتصال به اینترنت کار می‌کند، اما ممکن است پشتیبانی زبان و دقت محدودی داشته باشد.';

  @override
  String get translation_mode_ai => 'ترجمه با هوش مصنوعی';

  @override
  String get translation_mode_ai_description =>
      'از مدل‌های پیشرفته هوش مصنوعی برای ترجمه‌های دقیق‌تر و متناسب با متن استفاده می‌کند. نیاز به اتصال اینترنت و کلید API دارد.';

  @override
  String get translation_mode_title => 'حالت ترجمه';

  @override
  String get translation_mode_on_device_label => 'در دستگاه';

  @override
  String get translation_mode_ai_label => 'هوش مصنوعی';

  @override
  String get close => 'بستن';
}
