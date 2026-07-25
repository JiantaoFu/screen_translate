// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bulgarian (`bg`).
class AppLocalizationsBg extends AppLocalizations {
  AppLocalizationsBg([String locale = 'bg']) : super(locale);

  @override
  String get app_title => 'Превод на екрана';

  @override
  String get source_language => 'От';

  @override
  String get target_language => 'На';

  @override
  String get stop_translation => 'Спри превода';

  @override
  String get translate_screen => 'Преведи екрана';

  @override
  String get source_and_target_cannot_be_the_same =>
      'Изходният и целевият език не могат да бъдат еднакви';

  @override
  String get manage_translation_models => 'Управление на моделите за превод';

  @override
  String model_download_success(Object language) {
    return 'Моделът за $language е изтеглен успешно';
  }

  @override
  String model_download_error(Object language) {
    return 'Грешка при изтегляне на модела за $language';
  }

  @override
  String get model_not_downloaded => 'Моделът не е изтеглен';

  @override
  String get download_model => 'Изтегли';

  @override
  String get remove_translation_model => 'Премахване на модел за превод';

  @override
  String remove_translation_model_confirmation(Object language) {
    return 'Да съществува модел за $language?';
  }

  @override
  String get cancel => 'Отказ';

  @override
  String get remove => 'Премахване';

  @override
  String get not_installed => 'Не е изтеглен';

  @override
  String get downloading => 'Изтегляне...';

  @override
  String get installed => 'Изтеглен';

  @override
  String get download_failed => 'Неуспешно изтегляне';

  @override
  String failed_to_remove_model(Object language) {
    return 'Неуспешно премахване на модел за $language';
  }

  @override
  String failed_to_download_model(Object language) {
    return 'Неуспешно изтегляне на модел за $language';
  }

  @override
  String get auto_translate_mode => 'Модел за автоматично превод';

  @override
  String get manual_translate_mode => 'Модел за ръчно превод';

  @override
  String get original_text_mode => 'Модел за оригинални текст';

  @override
  String get overlay_permission_required =>
      'Може да се рисуваме над други приложения';

  @override
  String get overlay_permission_required_content =>
      'Това приложение изисква разрешение за рисуване над други приложения.';

  @override
  String get grant_permission => 'Разрешение';

  @override
  String get language_afrikaans => 'африкаанс';

  @override
  String get language_albanian => 'албански';

  @override
  String get language_arabic => 'арабски';

  @override
  String get language_belarusian => 'беларуски';

  @override
  String get language_bengali => 'бенгалски';

  @override
  String get language_bulgarian => 'български';

  @override
  String get language_catalan => 'каталонски';

  @override
  String get language_chinese => 'китайски';

  @override
  String get language_croatian => 'хърватски';

  @override
  String get language_czech => 'чешки';

  @override
  String get language_danish => 'датски';

  @override
  String get language_dutch => 'нидерландски';

  @override
  String get language_english => 'английски';

  @override
  String get language_esperanto => 'есперанто';

  @override
  String get language_estonian => 'естонски';

  @override
  String get language_finnish => 'фински';

  @override
  String get language_french => 'френски';

  @override
  String get language_galician => 'галисийски';

  @override
  String get language_georgian => 'грузински';

  @override
  String get language_german => 'немски';

  @override
  String get language_greek => 'гръцки';

  @override
  String get language_gujarati => 'гуджарати';

  @override
  String get language_haitian => 'хаитянски';

  @override
  String get language_hebrew => 'иврит';

  @override
  String get language_hindi => 'хинди';

  @override
  String get language_hungarian => 'унгарски';

  @override
  String get language_icelandic => 'исландски';

  @override
  String get language_indonesian => 'индонезийски';

  @override
  String get language_irish => 'ирландски';

  @override
  String get language_italian => 'италиански';

  @override
  String get language_japanese => 'японски';

  @override
  String get language_kannada => 'каннада';

  @override
  String get language_korean => 'корейски';

  @override
  String get language_latvian => 'латвийски';

  @override
  String get language_lithuanian => 'литовски';

  @override
  String get language_macedonian => 'македонски';

  @override
  String get language_malay => 'малайски';

  @override
  String get language_maltese => 'малтийски';

  @override
  String get language_marathi => 'марати';

  @override
  String get language_norwegian => 'норвежки';

  @override
  String get language_persian => 'персийски';

  @override
  String get language_polish => 'полски';

  @override
  String get language_portuguese => 'португалски';

  @override
  String get language_romanian => 'румънски';

  @override
  String get language_russian => 'руски';

  @override
  String get language_slovak => 'словашки';

  @override
  String get language_slovenian => 'словенски';

  @override
  String get language_spanish => 'испански';

  @override
  String get language_swahili => 'суахили';

  @override
  String get language_swedish => 'шведски';

  @override
  String get language_tagalog => 'тагалог';

  @override
  String get language_tamil => 'тамилски';

  @override
  String get language_telugu => 'телугу';

  @override
  String get language_thai => 'тайски';

  @override
  String get language_turkish => 'турски';

  @override
  String get language_ukrainian => 'украински';

  @override
  String get language_urdu => 'урду';

  @override
  String get language_vietnamese => 'виетнамски';

  @override
  String get language_welsh => 'уелски';

  @override
  String get enjoying_app => 'Харесвате ли Screen Translate?';

  @override
  String get review_prompt_message =>
      'Бихме искали да чуем вашето мнение! Искате ли да оцените приложението в Google Play?';

  @override
  String get rate_now => 'Оценете сега';

  @override
  String get not_now => 'Не сега';

  @override
  String get cannot_open_store => 'Не може да се отвори Google Play Store';

  @override
  String get api_key_required => 'Изисква се API ключ';

  @override
  String get api_key_setup_prompt =>
      'Конфигурирайте вашия ChatGLM API ключ за AI превод.';

  @override
  String get go_to_settings => 'Отиване в Настройки';

  @override
  String get api_key_dialog_title => 'Конфигуриране на API за AI превод';

  @override
  String get api_key_configuration_title => 'ChatGLM AI превод';

  @override
  String get api_key_get_key_from =>
      'За да използвате ChatGLM преводи, трябва да получите безплатен API ключ от ';

  @override
  String get api_key_configuration_steps =>
      'Стъпки за конфигуриране на API ключ';

  @override
  String get api_key_step_1 => '1. Посетете open.bigmodel.cn и създайте акаунт';

  @override
  String get api_key_step_2 => '2. Отидете в секцията за управление на API';

  @override
  String get api_key_step_3 =>
      '3. Генерирайте нов API ключ за вашето приложение';

  @override
  String get api_key_input_label => 'ChatGLM API ключ';

  @override
  String get api_key_input_hint => 'Въведете вашия ChatGLM API ключ';

  @override
  String get api_key_input_error => 'Моля, въведете валиден API ключ';

  @override
  String get api_key_save_button => 'Запазване на API ключ';

  @override
  String get api_key_note =>
      'Вашият API ключ ще бъде съхранен сигурно и използван само за услуги за превод.';

  @override
  String get api_key_save_error =>
      'Невалиден API ключ. Проверете и опитайте отново.';

  @override
  String get api_key_save_success => 'API ключът е запазен успешно';

  @override
  String get translation_mode_on_device => 'Превод на Устройство';

  @override
  String get translation_mode_on_device_description =>
      'Използва вградени модели за превод на вашето устройство. Бързо и работи офлайн, но може да има ограничена езикова поддръжка и точност.';

  @override
  String get translation_mode_ai => 'Превод с ИИ';

  @override
  String get translation_mode_ai_description =>
      'Използва напреднали модели на ИИ за по-точни и контекстуални преводи. Изисква интернет връзка и API ключ.';

  @override
  String get translation_mode_title => 'Режим на Превод';

  @override
  String get translation_mode_on_device_label => 'На Устройство';

  @override
  String get translation_mode_ai_label => 'ИИ';

  @override
  String get close => 'Затвори';
}
