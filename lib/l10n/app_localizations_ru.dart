// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get app_title => 'Перевод экрана';

  @override
  String get source_language => 'С';

  @override
  String get target_language => 'На';

  @override
  String get stop_translation => 'Остановить перевод';

  @override
  String get translate_screen => 'Перевести экран';

  @override
  String get source_and_target_cannot_be_the_same =>
      'Исходный и целевой языки не могут быть одинаковыми';

  @override
  String get manage_translation_models => 'Управление моделями перевода';

  @override
  String model_download_success(Object language) {
    return 'Модель $language успешно загружена';
  }

  @override
  String model_download_error(Object language) {
    return 'Ошибка при загрузке модели $language';
  }

  @override
  String get model_not_downloaded => 'Модель не загружена';

  @override
  String get download_model => 'Загрузить';

  @override
  String get remove_translation_model => 'Удалить модель перевода';

  @override
  String remove_translation_model_confirmation(Object language) {
    return 'Вы уверены, что хотите удалить модель перевода для $language?';
  }

  @override
  String get cancel => 'Отмена';

  @override
  String get remove => 'Удалить';

  @override
  String get not_installed => 'Не установлено';

  @override
  String get downloading => 'Загрузка...';

  @override
  String get installed => 'Установлено';

  @override
  String get download_failed => 'Загрузка не удалась';

  @override
  String failed_to_remove_model(Object language) {
    return 'Не удалось удалить модель для $language';
  }

  @override
  String failed_to_download_model(Object language) {
    return 'Не удалось загрузить модель для $language';
  }

  @override
  String get auto_translate_mode => 'Автоматический перевод';

  @override
  String get manual_translate_mode => 'Ручной перевод';

  @override
  String get original_text_mode => 'Модель оригинального текста';

  @override
  String get overlay_permission_required => 'Модель перевода';

  @override
  String get overlay_permission_required_content =>
      'Этот приложение требует разрешения на перевод на экране.';

  @override
  String get grant_permission => 'Позволить разрешения';

  @override
  String get language_afrikaans => 'Африкаанс';

  @override
  String get language_albanian => 'Албанский';

  @override
  String get language_arabic => 'Арабский';

  @override
  String get language_belarusian => 'Белорусский';

  @override
  String get language_bengali => 'Бенгальский';

  @override
  String get language_bulgarian => 'Болгарский';

  @override
  String get language_catalan => 'Каталанский';

  @override
  String get language_chinese => 'Китайский';

  @override
  String get language_croatian => 'Хорватский';

  @override
  String get language_czech => 'Чешский';

  @override
  String get language_danish => 'Датский';

  @override
  String get language_dutch => 'Нидерландский';

  @override
  String get language_english => 'Английский';

  @override
  String get language_esperanto => 'Эсперанто';

  @override
  String get language_estonian => 'Эстонский';

  @override
  String get language_finnish => 'Финский';

  @override
  String get language_french => 'Французский';

  @override
  String get language_galician => 'Галисийский';

  @override
  String get language_georgian => 'Грузинский';

  @override
  String get language_german => 'Немецкий';

  @override
  String get language_greek => 'Греческий';

  @override
  String get language_gujarati => 'Гуджарати';

  @override
  String get language_haitian => 'Гаитянский';

  @override
  String get language_hebrew => 'Иврит';

  @override
  String get language_hindi => 'Хинди';

  @override
  String get language_hungarian => 'Венгерский';

  @override
  String get language_icelandic => 'Исландский';

  @override
  String get language_indonesian => 'Индонезийский';

  @override
  String get language_irish => 'Ирландский';

  @override
  String get language_italian => 'Итальянский';

  @override
  String get language_japanese => 'Японский';

  @override
  String get language_kannada => 'Каннада';

  @override
  String get language_korean => 'Корейский';

  @override
  String get language_latvian => 'Латышский';

  @override
  String get language_lithuanian => 'Литовский';

  @override
  String get language_macedonian => 'Македонский';

  @override
  String get language_malay => 'Малайский';

  @override
  String get language_maltese => 'Мальтийский';

  @override
  String get language_marathi => 'Маратхи';

  @override
  String get language_norwegian => 'Норвежский';

  @override
  String get language_persian => 'Персидский';

  @override
  String get language_polish => 'Польский';

  @override
  String get language_portuguese => 'Португальский';

  @override
  String get language_romanian => 'Румынский';

  @override
  String get language_russian => 'Русский';

  @override
  String get language_slovak => 'Словацкий';

  @override
  String get language_slovenian => 'Словенский';

  @override
  String get language_spanish => 'Испанский';

  @override
  String get language_swahili => 'Суахили';

  @override
  String get language_swedish => 'Шведский';

  @override
  String get language_tagalog => 'Тагальский';

  @override
  String get language_tamil => 'Тамильский';

  @override
  String get language_telugu => 'Телугу';

  @override
  String get language_thai => 'Тайский';

  @override
  String get language_turkish => 'Турецкий';

  @override
  String get language_ukrainian => 'Украинский';

  @override
  String get language_urdu => 'Урду';

  @override
  String get language_vietnamese => 'Вьетнамский';

  @override
  String get language_welsh => 'Валлийский';

  @override
  String get enjoying_app => 'Нравится Screen Translate?';

  @override
  String get review_prompt_message =>
      'Мы будем рады услышать ваш отзыв! Хотите оценить приложение в Google Play?';

  @override
  String get rate_now => 'Оценить сейчас';

  @override
  String get not_now => 'Не сейчас';

  @override
  String get cannot_open_store => 'Не удалось открыть Google Play Store';

  @override
  String get api_key_required => 'Требуется API-ключ';

  @override
  String get api_key_setup_prompt =>
      'Пожалуйста, настройте ваш API-ключ ChatGLM для использования ИИ-перевода.';

  @override
  String get go_to_settings => 'Перейти к настройкам';

  @override
  String get api_key_dialog_title => 'Настройка API для ИИ-перевода';

  @override
  String get api_key_configuration_title => 'ИИ-перевод ChatGLM';

  @override
  String get api_key_get_key_from =>
      'Чтобы использовать переводы ChatGLM, вам нужно получить бесплатный API-ключ от ';

  @override
  String get api_key_configuration_steps => 'Шаги настройки API-ключа';

  @override
  String get api_key_step_1 =>
      '1. Посетите open.bigmodel.cn и создайте учетную запись';

  @override
  String get api_key_step_2 => '2. Перейдите в раздел управления API';

  @override
  String get api_key_step_3 =>
      '3. Создайте новый API-ключ для вашего приложения';

  @override
  String get api_key_input_label => 'API-ключ ChatGLM';

  @override
  String get api_key_input_hint => 'Введите ваш API-ключ ChatGLM';

  @override
  String get api_key_input_error =>
      'Пожалуйста, введите действительный API-ключ';

  @override
  String get api_key_save_button => 'Сохранить API-ключ';

  @override
  String get api_key_note =>
      'Ваш API-ключ будет надежно сохранен и использован только для служб перевода.';

  @override
  String get api_key_save_error =>
      'Неверный API-ключ. Проверьте и попробуйте снова.';

  @override
  String get api_key_save_success => 'API-ключ успешно сохранен';

  @override
  String get translation_mode_on_device => 'Перевод на Устройстве';

  @override
  String get translation_mode_on_device_description =>
      'Использует встроенные модели перевода на вашем устройстве. Быстро и работает без подключения к интернету, но может иметь ограниченную поддержку языков и точность.';

  @override
  String get translation_mode_ai => 'Перевод с ИИ';

  @override
  String get translation_mode_ai_description =>
      'Использует передовые модели ИИ для более точных и контекстных переводов. Требует подключения к интернету и ключа API.';

  @override
  String get translation_mode_title => 'Режим Перевода';

  @override
  String get translation_mode_on_device_label => 'Устройство';

  @override
  String get translation_mode_ai_label => 'ИИ';

  @override
  String get close => 'Закрыть';
}
