// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Thai (`th`).
class AppLocalizationsTh extends AppLocalizations {
  AppLocalizationsTh([String locale = 'th']) : super(locale);

  @override
  String get app_title => 'แปลหน้าจอ';

  @override
  String get source_language => 'จาก';

  @override
  String get target_language => 'เป็น';

  @override
  String get stop_translation => 'หยุดการแปล';

  @override
  String get translate_screen => 'แปลหน้าจอ';

  @override
  String get source_and_target_cannot_be_the_same =>
      'ภาษาต้นทางและปลายทางต้องไม่เหมือนกัน';

  @override
  String get manage_translation_models => 'จัดการโมเดลการแปล';

  @override
  String model_download_success(Object language) {
    return 'ดาวน์โหลดโมเดลสำหรับภาษา$languageสำเร็จ';
  }

  @override
  String model_download_error(Object language) {
    return 'เกิดข้อผิดพลาดขณะดาวน์โหลดโมเดลสำหรับภาษา$language';
  }

  @override
  String get model_not_downloaded => 'ยังไม่ได้ดาวน์โหลดโมเดล';

  @override
  String get download_model => 'ดาวน์โหลด';

  @override
  String get remove_translation_model => 'ลบโมเดลการแปล';

  @override
  String remove_translation_model_confirmation(Object language) {
    return 'ยืนยันการลบโมเดลการแปลสำหรับภาษา$language';
  }

  @override
  String get cancel => 'ยกเลิก';

  @override
  String get remove => 'ลบ';

  @override
  String get not_installed => 'ยังไม่ได้ติดตั้ง';

  @override
  String get downloading => 'กำลังดาวน์โหลด...';

  @override
  String get installed => 'ติดตั้งแล้ว';

  @override
  String get download_failed => 'การดาวน์โหลดล้มเหลว';

  @override
  String failed_to_remove_model(Object language) {
    return 'การลบโมเดลล้มเหลวสำหรับภาษา$language';
  }

  @override
  String failed_to_download_model(Object language) {
    return 'การดาวน์โหลดโมเดลล้มเหลวสำหรับภาษา$language';
  }

  @override
  String get auto_translate_mode => 'โหมดการแปลอัตโนมัติ';

  @override
  String get manual_translate_mode => 'โหมดการแปลที่ต้องการ';

  @override
  String get original_text_mode => 'โหมดข้อความเดิม';

  @override
  String get overlay_permission_required => 'โหมดการแปล';

  @override
  String get overlay_permission_required_content =>
      'โปรแกรมนี้ต้องการสิทธิ์ในการแปลบนหน้าจอ';

  @override
  String get grant_permission => 'อนุญาตสิทธิ์';

  @override
  String get language_afrikaans => 'ภาษาแอฟริกานส์';

  @override
  String get language_albanian => 'ภาษาแอลเบเนีย';

  @override
  String get language_arabic => 'ภาษาอาหรับ';

  @override
  String get language_belarusian => 'ภาษาเบลารุส';

  @override
  String get language_bengali => 'ภาษาเบงกาลี';

  @override
  String get language_bulgarian => 'ภาษาบัลแกเรีย';

  @override
  String get language_catalan => 'ภาษาคาตาลัน';

  @override
  String get language_chinese => 'ภาษาจีน';

  @override
  String get language_croatian => 'ภาษาโครเอเชีย';

  @override
  String get language_czech => 'ภาษาเช็ก';

  @override
  String get language_danish => 'ภาษาเดนมาร์ก';

  @override
  String get language_dutch => 'ภาษาดัตช์';

  @override
  String get language_english => 'ภาษาอังกฤษ';

  @override
  String get language_esperanto => 'ภาษาเอสเปรันโต';

  @override
  String get language_estonian => 'ภาษาเอสโตเนีย';

  @override
  String get language_finnish => 'ภาษาฟินแลนด์';

  @override
  String get language_french => 'ภาษาฝรั่งเศส';

  @override
  String get language_galician => 'ภาษากาลิเซีย';

  @override
  String get language_georgian => 'ภาษาจอร์เจีย';

  @override
  String get language_german => 'ภาษาเยอรมัน';

  @override
  String get language_greek => 'ภาษากรีก';

  @override
  String get language_gujarati => 'ภาษาคุชราต';

  @override
  String get language_haitian => 'ภาษาเฮติ';

  @override
  String get language_hebrew => 'ภาษาฮีบรู';

  @override
  String get language_hindi => 'ภาษาฮินดี';

  @override
  String get language_hungarian => 'ภาษาฮังการี';

  @override
  String get language_icelandic => 'ภาษาไอซ์แลนด์';

  @override
  String get language_indonesian => 'ภาษาอินโดนีเซีย';

  @override
  String get language_irish => 'ภาษาไอริช';

  @override
  String get language_italian => 'ภาษาอิตาลี';

  @override
  String get language_japanese => 'ภาษาญี่ปุ่น';

  @override
  String get language_kannada => 'ภาษากันนาดา';

  @override
  String get language_korean => 'ภาษาเกาหลี';

  @override
  String get language_latvian => 'ภาษาลัตเวีย';

  @override
  String get language_lithuanian => 'ภาษาลิทัวเนีย';

  @override
  String get language_macedonian => 'ภาษามาซิโดเนีย';

  @override
  String get language_malay => 'ภาษามาเลย์';

  @override
  String get language_maltese => 'ภาษามอลตา';

  @override
  String get language_marathi => 'ภาษามราฐี';

  @override
  String get language_norwegian => 'ภาษานอร์เวย์';

  @override
  String get language_persian => 'ภาษาเปอร์เซีย';

  @override
  String get language_polish => 'ภาษาโปแลนด์';

  @override
  String get language_portuguese => 'ภาษาโปรตุเกส';

  @override
  String get language_romanian => 'ภาษาโรมาเนีย';

  @override
  String get language_russian => 'ภาษารัสเซีย';

  @override
  String get language_slovak => 'ภาษาสโลวัก';

  @override
  String get language_slovenian => 'ภาษาสโลวีเนีย';

  @override
  String get language_spanish => 'ภาษาสเปน';

  @override
  String get language_swahili => 'ภาษาสวาฮีลี';

  @override
  String get language_swedish => 'ภาษาสวีเดน';

  @override
  String get language_tagalog => 'ภาษาตากาล็อก';

  @override
  String get language_tamil => 'ภาษาทมิฬ';

  @override
  String get language_telugu => 'ภาษาเตลูกู';

  @override
  String get language_thai => 'ภาษาไทย';

  @override
  String get language_turkish => 'ภาษาตุรกี';

  @override
  String get language_ukrainian => 'ภาษายูเครน';

  @override
  String get language_urdu => 'ภาษาอูรดู';

  @override
  String get language_vietnamese => 'ภาษาเวียดนาม';

  @override
  String get language_welsh => 'ภาษาเวลส์';

  @override
  String get enjoying_app => 'คุณชอบ Screen Translate ไหม?';

  @override
  String get review_prompt_message =>
      'เราอยากฟังความคิดเห็นของคุณ! คุณอยากให้คะแนนแอปบน Google Play ไหม?';

  @override
  String get rate_now => 'ให้คะแนนตอนนี้';

  @override
  String get not_now => 'ไม่ตอนนี้';

  @override
  String get cannot_open_store => 'ไม่สามารถเปิด Google Play Store ได้';

  @override
  String get api_key_required => 'ต้องใช้คีย์ API';

  @override
  String get api_key_setup_prompt =>
      'ตั้งค่าคีย์ API ของ ChatGLM สำหรับการแปลด้วย AI';

  @override
  String get go_to_settings => 'ไปที่การตั้งค่า';

  @override
  String get api_key_dialog_title => 'การกำหนดค่า API การแปลภาษา AI';

  @override
  String get api_key_configuration_title => 'การแปลภาษา ChatGLM ด้วย AI';

  @override
  String get api_key_get_key_from =>
      'หากต้องการใช้การแปลภาษา ChatGLM คุณต้องรับคีย์ API ฟรีจาก ';

  @override
  String get api_key_configuration_steps => 'ขั้นตอนการกำหนดค่าคีย์ API';

  @override
  String get api_key_step_1 => '1. เยี่ยมชม open.bigmodel.cn และสร้างบัญชี';

  @override
  String get api_key_step_2 => '2. ไปที่ส่วนการจัดการ API';

  @override
  String get api_key_step_3 => '3. สร้างคีย์ API ใหม่สำหรับแอปพลิเคชันของคุณ';

  @override
  String get api_key_input_label => 'คีย์ API ของ ChatGLM';

  @override
  String get api_key_input_hint => 'ป้อนคีย์ API ของ ChatGLM';

  @override
  String get api_key_input_error => 'โปรดป้อนคีย์ API ที่ถูกต้อง';

  @override
  String get api_key_save_button => 'บันทึกคีย์ API';

  @override
  String get api_key_note =>
      'คีย์ API ของคุณจะถูกจัดเก็บอย่างปลอดภัยและใช้เฉพาะสำหรับบริการแปลภาษาเท่านั้น';

  @override
  String get api_key_save_error =>
      'คีย์ API ไม่ถูกต้อง กรุณาตรวจสอบและลองอีกครั้ง';

  @override
  String get api_key_save_success => 'บันทึกคีย์ API สำเร็จ';

  @override
  String get translation_mode_on_device => 'การแปลบนอุปกรณ์';

  @override
  String get translation_mode_on_device_description =>
      'ใช้โมเดลการแปลภาษาในตัวบนอุปกรณ์ของคุณ ทำงานได้เร็วและสามารถใช้งานออฟไลน์ แต่อาจมีการสนับสนุนภาษาและความแม่นยำที่จำกัด';

  @override
  String get translation_mode_ai => 'การแปลด้วย AI';

  @override
  String get translation_mode_ai_description =>
      'ใช้โมเดล AI ขั้นสูงสำหรับการแปลที่แม่นยำและมีบริบท ต้องการการเชื่อมต่ออินเทอร์เน็ตและคีย์ API';

  @override
  String get translation_mode_title => 'โหมดการแปล';

  @override
  String get translation_mode_on_device_label => 'บนอุปกรณ์';

  @override
  String get translation_mode_ai_label => 'AI';

  @override
  String get close => 'ปิด';
}
