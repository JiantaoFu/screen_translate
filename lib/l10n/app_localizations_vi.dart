// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get app_title => 'Dịch màn hình';

  @override
  String get source_language => 'Từ';

  @override
  String get target_language => 'Sang';

  @override
  String get stop_translation => 'Dừng dịch';

  @override
  String get translate_screen => 'Dịch màn hình';

  @override
  String get source_and_target_cannot_be_the_same =>
      'Ngôn ngữ nguồn và đích không thể giống nhau';

  @override
  String get manage_translation_models => 'Quản lý mô hình dịch';

  @override
  String model_download_success(Object language) {
    return 'Đã tải xong mô hình cho $language';
  }

  @override
  String model_download_error(Object language) {
    return 'Lỗi khi tải mô hình cho $language';
  }

  @override
  String get model_not_downloaded => 'Chưa tải mô hình';

  @override
  String get download_model => 'Tải về';

  @override
  String get remove_translation_model => 'Xoá mô hình dịch';

  @override
  String remove_translation_model_confirmation(Object language) {
    return 'Bắt đầu xóa mô hình dịch cho $language. Hành động này không thể huyết hết.';
  }

  @override
  String get cancel => 'Huyết';

  @override
  String get remove => 'Xoá';

  @override
  String get not_installed => 'Chưa cung cấp';

  @override
  String get downloading => 'Đang tải...';

  @override
  String get installed => 'Đã cung cấp';

  @override
  String get download_failed => 'Tải về thất bại';

  @override
  String failed_to_remove_model(Object language) {
    return 'Lỗi khi xóa mô hình dịch cho $language';
  }

  @override
  String failed_to_download_model(Object language) {
    return 'Lỗi khi tải mô hình dịch cho $language';
  }

  @override
  String get auto_translate_mode => 'Chế độ dịch';

  @override
  String get manual_translate_mode => 'Chế độ dịch thực tế';

  @override
  String get original_text_mode => 'Chế độ văn bản gốc';

  @override
  String get overlay_permission_required => 'Chế độ dịch';

  @override
  String get overlay_permission_required_content =>
      'Chương trình nếu cần quyền trạch tại màn hình';

  @override
  String get grant_permission => 'Cung cấp quyền trạch';

  @override
  String get language_afrikaans => 'Tiếng Afrikaans';

  @override
  String get language_albanian => 'Tiếng Albania';

  @override
  String get language_arabic => 'Tiếng Ả Rập';

  @override
  String get language_belarusian => 'Tiếng Belarus';

  @override
  String get language_bengali => 'Tiếng Bengali';

  @override
  String get language_bulgarian => 'Tiếng Bulgaria';

  @override
  String get language_catalan => 'Tiếng Catalan';

  @override
  String get language_chinese => 'Tiếng Trung';

  @override
  String get language_croatian => 'Tiếng Croatia';

  @override
  String get language_czech => 'Tiếng Séc';

  @override
  String get language_danish => 'Tiếng Đan Mạch';

  @override
  String get language_dutch => 'Tiếng Hà Lan';

  @override
  String get language_english => 'Tiếng Anh';

  @override
  String get language_esperanto => 'Tiếng Esperanto';

  @override
  String get language_estonian => 'Tiếng Estonia';

  @override
  String get language_finnish => 'Tiếng Phần Lan';

  @override
  String get language_french => 'Tiếng Pháp';

  @override
  String get language_galician => 'Tiếng Galicia';

  @override
  String get language_georgian => 'Tiếng Georgia';

  @override
  String get language_german => 'Tiếng Đức';

  @override
  String get language_greek => 'Tiếng Hy Lạp';

  @override
  String get language_gujarati => 'Tiếng Gujarat';

  @override
  String get language_haitian => 'Tiếng Haiti';

  @override
  String get language_hebrew => 'Tiếng Do Thái';

  @override
  String get language_hindi => 'Tiếng Hindi';

  @override
  String get language_hungarian => 'Tiếng Hungary';

  @override
  String get language_icelandic => 'Tiếng Iceland';

  @override
  String get language_indonesian => 'Tiếng Indonesia';

  @override
  String get language_irish => 'Tiếng Ireland';

  @override
  String get language_italian => 'Tiếng Ý';

  @override
  String get language_japanese => 'Tiếng Nhật';

  @override
  String get language_kannada => 'Tiếng Kannada';

  @override
  String get language_korean => 'Tiếng Hàn';

  @override
  String get language_latvian => 'Tiếng Latvia';

  @override
  String get language_lithuanian => 'Tiếng Lithuania';

  @override
  String get language_macedonian => 'Tiếng Macedonia';

  @override
  String get language_malay => 'Tiếng Mã Lai';

  @override
  String get language_maltese => 'Tiếng Malta';

  @override
  String get language_marathi => 'Tiếng Marathi';

  @override
  String get language_norwegian => 'Tiếng Na Uy';

  @override
  String get language_persian => 'Tiếng Ba Tư';

  @override
  String get language_polish => 'Tiếng Ba Lan';

  @override
  String get language_portuguese => 'Tiếng Bồ Đào Nha';

  @override
  String get language_romanian => 'Tiếng Romania';

  @override
  String get language_russian => 'Tiếng Nga';

  @override
  String get language_slovak => 'Tiếng Slovakia';

  @override
  String get language_slovenian => 'Tiếng Slovenia';

  @override
  String get language_spanish => 'Tiếng Tây Ban Nha';

  @override
  String get language_swahili => 'Tiếng Swahili';

  @override
  String get language_swedish => 'Tiếng Thụy Điển';

  @override
  String get language_tagalog => 'Tiếng Tagalog';

  @override
  String get language_tamil => 'Tiếng Tamil';

  @override
  String get language_telugu => 'Tiếng Telugu';

  @override
  String get language_thai => 'Tiếng Thái';

  @override
  String get language_turkish => 'Tiếng Thổ Nhĩ Kỳ';

  @override
  String get language_ukrainian => 'Tiếng Ukraina';

  @override
  String get language_urdu => 'Tiếng Urdu';

  @override
  String get language_vietnamese => 'Tiếng Việt';

  @override
  String get language_welsh => 'Tiếng Wales';

  @override
  String get enjoying_app => 'Bạn có thích Screen Translate không?';

  @override
  String get review_prompt_message =>
      'Chúng tôi rất muốn nghe ý kiến của bạn! Bạn có muốn đánh giá ứng dụng trên Google Play không?';

  @override
  String get rate_now => 'Đánh giá ngay';

  @override
  String get not_now => 'Không phải bây giờ';

  @override
  String get cannot_open_store => 'Không thể mở Google Play Store';

  @override
  String get api_key_required => 'Yêu cầu khóa API';

  @override
  String get api_key_setup_prompt =>
      'Thiết lập khóa API ChatGLM của bạn cho dịch thuật AI.';

  @override
  String get go_to_settings => 'Đi đến Cài đặt';

  @override
  String get api_key_dialog_title => 'Cấu hình API Dịch thuật AI';

  @override
  String get api_key_configuration_title => 'Dịch thuật ChatGLM với AI';

  @override
  String get api_key_get_key_from =>
      'Để sử dụng bản dịch ChatGLM, bạn cần lấy khóa API miễn phí từ ';

  @override
  String get api_key_configuration_steps => 'Các bước cấu hình khóa API';

  @override
  String get api_key_step_1 => '1. Truy cập open.bigmodel.cn và tạo tài khoản';

  @override
  String get api_key_step_2 => '2. Điều hướng đến phần Quản lý API';

  @override
  String get api_key_step_3 => '3. Tạo khóa API mới cho ứng dụng của bạn';

  @override
  String get api_key_input_label => 'Khóa API ChatGLM';

  @override
  String get api_key_input_hint => 'Nhập khóa API ChatGLM của bạn';

  @override
  String get api_key_input_error => 'Vui lòng nhập khóa API hợp lệ';

  @override
  String get api_key_save_button => 'Lưu Khóa API';

  @override
  String get api_key_note =>
      'Khóa API của bạn sẽ được lưu trữ an toàn và chỉ được sử dụng cho các dịch vụ dịch thuật.';

  @override
  String get api_key_save_error =>
      'Khóa API không hợp lệ. Kiểm tra và thử lại.';

  @override
  String get api_key_save_success => 'Đã lưu Khóa API thành công';

  @override
  String get translation_mode_on_device => 'Dịch Trên Thiết Bị';

  @override
  String get translation_mode_on_device_description =>
      'Sử dụng các mô hình dịch được tích hợp trên thiết bị của bạn. Nhanh và hoạt động ngoại tuyến, nhưng có thể có hỗ trợ ngôn ngữ và độ chính xác hạn chế.';

  @override
  String get translation_mode_ai => 'Dịch bằng AI';

  @override
  String get translation_mode_ai_description =>
      'Sử dụng các mô hình AI tiên tiến để dịch chính xác và theo ngữ cảnh hơn. Yêu cầu kết nối internet và khóa API.';

  @override
  String get translation_mode_title => 'Chế Độ Dịch';

  @override
  String get translation_mode_on_device_label => 'Trên Thiết Bị';

  @override
  String get translation_mode_ai_label => 'AI';

  @override
  String get close => 'Đóng';
}
