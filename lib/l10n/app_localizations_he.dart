// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hebrew (`he`).
class AppLocalizationsHe extends AppLocalizations {
  AppLocalizationsHe([String locale = 'he']) : super(locale);

  @override
  String get app_title => 'תרגום מסך';

  @override
  String get source_language => 'מ-';

  @override
  String get target_language => 'ל-';

  @override
  String get stop_translation => 'עצור תרגום';

  @override
  String get translate_screen => 'תרגם מסך';

  @override
  String get source_and_target_cannot_be_the_same =>
      'שפת המקור והיעד לא יכולות להיות זהות';

  @override
  String get manage_translation_models => 'ניהול מודלי תרגום';

  @override
  String model_download_success(Object language) {
    return 'מודל $language הורד בהצלחה';
  }

  @override
  String model_download_error(Object language) {
    return 'שגיאה בהורדת מודל $language';
  }

  @override
  String get model_not_downloaded => 'המודל לא הורד';

  @override
  String get download_model => 'הורד';

  @override
  String get remove_translation_model => 'הסרת מודל תרגום';

  @override
  String remove_translation_model_confirmation(Object language) {
    return 'האם אתה רוצה להסיר את המודל לתרגום לשפה $language?';
  }

  @override
  String get cancel => 'ביטול';

  @override
  String get remove => 'הסרה';

  @override
  String get not_installed => 'לא מותקן';

  @override
  String get downloading => 'מוריד...';

  @override
  String get installed => 'מותקן';

  @override
  String get download_failed => 'הורדה נכשלה';

  @override
  String failed_to_remove_model(Object language) {
    return 'שגיאה בהסרת מודל $language';
  }

  @override
  String failed_to_download_model(Object language) {
    return 'שגיאה בהורדת מודל $language';
  }

  @override
  String get auto_translate_mode => 'Automatizm';

  @override
  String get manual_translate_mode => 'הפוך ידנית';

  @override
  String get original_text_mode => 'מודל טקסט הפוך';

  @override
  String get overlay_permission_required => 'מודל תרגום';

  @override
  String get overlay_permission_required_content =>
      'פרוטם צריך להפוך את המסך לפנימי.';

  @override
  String get grant_permission => 'הפוך את המסך לפנימי';

  @override
  String get language_afrikaans => 'אפריקאנס';

  @override
  String get language_albanian => 'אלבנית';

  @override
  String get language_arabic => 'ערבית';

  @override
  String get language_belarusian => 'בלארוסית';

  @override
  String get language_bengali => 'בנגלית';

  @override
  String get language_bulgarian => 'בולגרית';

  @override
  String get language_catalan => 'קטלאנית';

  @override
  String get language_chinese => 'סינית';

  @override
  String get language_croatian => 'קרואטית';

  @override
  String get language_czech => 'צ\'כית';

  @override
  String get language_danish => 'דנית';

  @override
  String get language_dutch => 'הולנדית';

  @override
  String get language_english => 'אנגלית';

  @override
  String get language_esperanto => 'אספרנטו';

  @override
  String get language_estonian => 'אסטונית';

  @override
  String get language_finnish => 'פינית';

  @override
  String get language_french => 'צרפתית';

  @override
  String get language_galician => 'גליסית';

  @override
  String get language_georgian => 'גאורגית';

  @override
  String get language_german => 'גרמנית';

  @override
  String get language_greek => 'יוונית';

  @override
  String get language_gujarati => 'גוג\'ראטית';

  @override
  String get language_haitian => 'האיטית';

  @override
  String get language_hebrew => 'עברית';

  @override
  String get language_hindi => 'הינדי';

  @override
  String get language_hungarian => 'הונגרית';

  @override
  String get language_icelandic => 'איסלנדית';

  @override
  String get language_indonesian => 'אינדונזית';

  @override
  String get language_irish => 'אירית';

  @override
  String get language_italian => 'איטלקית';

  @override
  String get language_japanese => 'יפנית';

  @override
  String get language_kannada => 'קנדה';

  @override
  String get language_korean => 'קוריאנית';

  @override
  String get language_latvian => 'לטבית';

  @override
  String get language_lithuanian => 'ליטאית';

  @override
  String get language_macedonian => 'מקדונית';

  @override
  String get language_malay => 'מלאית';

  @override
  String get language_maltese => 'מלטזית';

  @override
  String get language_marathi => 'מראטהי';

  @override
  String get language_norwegian => 'נורווגית';

  @override
  String get language_persian => 'פרסית';

  @override
  String get language_polish => 'פולנית';

  @override
  String get language_portuguese => 'פורטוגזית';

  @override
  String get language_romanian => 'רומנית';

  @override
  String get language_russian => 'רוסית';

  @override
  String get language_slovak => 'סלובקית';

  @override
  String get language_slovenian => 'סלובנית';

  @override
  String get language_spanish => 'ספרדית';

  @override
  String get language_swahili => 'סוואהילי';

  @override
  String get language_swedish => 'שוודית';

  @override
  String get language_tagalog => 'טגלוג';

  @override
  String get language_tamil => 'טמילית';

  @override
  String get language_telugu => 'טלוגו';

  @override
  String get language_thai => 'תאית';

  @override
  String get language_turkish => 'טורקית';

  @override
  String get language_ukrainian => 'אוקראינית';

  @override
  String get language_urdu => 'אורדו';

  @override
  String get language_vietnamese => 'וייטנאמית';

  @override
  String get language_welsh => 'וולשית';

  @override
  String get enjoying_app => 'נהנים מ-Screen Translate?';

  @override
  String get review_prompt_message =>
      'נשמח לשמוע את דעתכם! האם תרצו לדרג את האפליקציה ב-Google Play?';

  @override
  String get rate_now => 'דרגו עכשיו';

  @override
  String get not_now => 'לא עכשיו';

  @override
  String get cannot_open_store => 'לא ניתן לפתוח את חנות Google Play';

  @override
  String get api_key_required => 'נדרש מפתח API';

  @override
  String get api_key_setup_prompt =>
      'הגדר את מפתח ה-API של ChatGLM לתרגום מבוסס AI.';

  @override
  String get go_to_settings => 'עבור להגדרות';

  @override
  String get api_key_dialog_title => 'הגדרת API לתרגום AI';

  @override
  String get api_key_configuration_title => 'תרגום ChatGLM עם AI';

  @override
  String get api_key_get_key_from =>
      'כדי להשתמש בתרגומי ChatGLM, עליך לקבל מפתח API חינם מ-';

  @override
  String get api_key_configuration_steps => 'שלבי הגדרת מפתח API';

  @override
  String get api_key_step_1 => '1. בקר ב-open.bigmodel.cn וצור חשבון';

  @override
  String get api_key_step_2 => '2. עבור לסעיף ניהול API';

  @override
  String get api_key_step_3 => '3. צור מפתח API חדש עבור האפליקציה שלך';

  @override
  String get api_key_input_label => 'מפתח API של ChatGLM';

  @override
  String get api_key_input_hint => 'הזן את מפתח ה-API של ChatGLM';

  @override
  String get api_key_input_error => 'אנא הזן מפתח API תקף';

  @override
  String get api_key_save_button => 'שמור מפתח API';

  @override
  String get api_key_note =>
      'מפתח ה-API שלך יישמר בבטחה וישמש רק לשירותי תרגום.';

  @override
  String get api_key_save_error => 'מפתח API לא תקף. בדוק ונסה שוב.';

  @override
  String get api_key_save_success => 'מפתח API נשמר בהצלחה';

  @override
  String get translation_mode_on_device => 'תרגום במכשיר';

  @override
  String get translation_mode_on_device_description =>
      'משתמש במודלי תרגום מובנים במכשיר שלך. מהיר ופועל ללא חיבור לאינטרנט, אך עשוי להיות בעל תמיכת שפה ודיוק מוגבלים.';

  @override
  String get translation_mode_ai => 'תרגום בינה מלאכותית';

  @override
  String get translation_mode_ai_description =>
      'משתמש במודלי בינה מלאכותית מתקדמים לתרגומים מדויקים יותר ובעלי הקשר. דורש חיבור לאינטרנט ומפתח API.';

  @override
  String get translation_mode_title => 'מצב תרגום';

  @override
  String get translation_mode_on_device_label => 'במכשיר';

  @override
  String get translation_mode_ai_label => 'בינה מלאכותית';

  @override
  String get close => 'סגור';
}
