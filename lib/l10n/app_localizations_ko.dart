// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get app_title => '화면 번역';

  @override
  String get source_language => '원본';

  @override
  String get target_language => '대상';

  @override
  String get stop_translation => '번역 중지';

  @override
  String get translate_screen => '화면 번역';

  @override
  String get source_and_target_cannot_be_the_same => '원본 언어와 대상 언어가 같을 수 없습니다';

  @override
  String get manage_translation_models => '번역 모델 관리';

  @override
  String model_download_success(Object language) {
    return '$language 모델 다운로드 완료';
  }

  @override
  String model_download_error(Object language) {
    return '$language 모델 다운로드 실패';
  }

  @override
  String get model_not_downloaded => '모델이 다운로드되지 않음';

  @override
  String get download_model => '다운로드';

  @override
  String get remove_translation_model => '번역 모델 삭제';

  @override
  String remove_translation_model_confirmation(Object language) {
    return '$language번역 모델을 삭제합니다か?';
  }

  @override
  String get cancel => '죽기';

  @override
  String get remove => ' 삭제';

  @override
  String get not_installed => '설치되지 않음';

  @override
  String get downloading => '다운로드 중...';

  @override
  String get installed => '설치된 모델';

  @override
  String get download_failed => '다운로드 실패';

  @override
  String failed_to_remove_model(Object language) {
    return '$language 모델 삭제 실패';
  }

  @override
  String failed_to_download_model(Object language) {
    return '$language 모델 다운로드 실패';
  }

  @override
  String get auto_translate_mode => '자동 트랜스';

  @override
  String get manual_translate_mode => '마달 트랜스';

  @override
  String get original_text_mode => '예전 텍스트 모델';

  @override
  String get overlay_permission_required => '번역 모델';

  @override
  String get overlay_permission_required_content =>
      '이 프로그램은 스크림에 대한 번역을 위한 기능을 필요하면들다.';

  @override
  String get grant_permission => '기능을 통해 주기';

  @override
  String get language_afrikaans => '아프리칸스어';

  @override
  String get language_albanian => '알바니아어';

  @override
  String get language_arabic => '아랍어';

  @override
  String get language_belarusian => '벨라루스어';

  @override
  String get language_bengali => '벵골어';

  @override
  String get language_bulgarian => '불가리아어';

  @override
  String get language_catalan => '카탈로니아어';

  @override
  String get language_chinese => '중국어';

  @override
  String get language_croatian => '크로아티아어';

  @override
  String get language_czech => '체코어';

  @override
  String get language_danish => '덴마크어';

  @override
  String get language_dutch => '네덜란드어';

  @override
  String get language_english => '영어';

  @override
  String get language_esperanto => '에스페란토어';

  @override
  String get language_estonian => '에스토니아어';

  @override
  String get language_finnish => '핀란드어';

  @override
  String get language_french => '프랑스어';

  @override
  String get language_galician => '갈리시아어';

  @override
  String get language_georgian => '조지아어';

  @override
  String get language_german => '독일어';

  @override
  String get language_greek => '그리스어';

  @override
  String get language_gujarati => '구자라트어';

  @override
  String get language_haitian => '아이티어';

  @override
  String get language_hebrew => '히브리어';

  @override
  String get language_hindi => '힌디어';

  @override
  String get language_hungarian => '헝가리어';

  @override
  String get language_icelandic => '아이슬란드어';

  @override
  String get language_indonesian => '인도네시아어';

  @override
  String get language_irish => '아일랜드어';

  @override
  String get language_italian => '이탈리아어';

  @override
  String get language_japanese => '일본어';

  @override
  String get language_kannada => '칸나다어';

  @override
  String get language_korean => '한국어';

  @override
  String get language_latvian => '라트비아어';

  @override
  String get language_lithuanian => '리투아니아어';

  @override
  String get language_macedonian => '마케도니아어';

  @override
  String get language_malay => '말레이어';

  @override
  String get language_maltese => '몰타어';

  @override
  String get language_marathi => '마라티어';

  @override
  String get language_norwegian => '노르웨이어';

  @override
  String get language_persian => '페르시아어';

  @override
  String get language_polish => '폴란드어';

  @override
  String get language_portuguese => '포르투갈어';

  @override
  String get language_romanian => '루마니아어';

  @override
  String get language_russian => '러시아어';

  @override
  String get language_slovak => '슬로바키아어';

  @override
  String get language_slovenian => '슬로베니아어';

  @override
  String get language_spanish => '스페인어';

  @override
  String get language_swahili => '스와힐리어';

  @override
  String get language_swedish => '스웨덴어';

  @override
  String get language_tagalog => '타갈로그어';

  @override
  String get language_tamil => '타밀어';

  @override
  String get language_telugu => '텔루구어';

  @override
  String get language_thai => '태국어';

  @override
  String get language_turkish => '터키어';

  @override
  String get language_ukrainian => '우크라이나어';

  @override
  String get language_urdu => '우르두어';

  @override
  String get language_vietnamese => '베트남어';

  @override
  String get language_welsh => '웨일스어';

  @override
  String get enjoying_app => 'Screen Translate가 마음에 드시나요?';

  @override
  String get review_prompt_message =>
      '사용자 여러분의 소중한 의견을 듣고 싶습니다! Google Play에서 앱을 평가해 주시겠어요?';

  @override
  String get rate_now => '지금 평가하기';

  @override
  String get not_now => '나중에';

  @override
  String get cannot_open_store => 'Google Play 스토어를 열 수 없습니다';

  @override
  String get api_key_required => 'API 키 필요';

  @override
  String get api_key_setup_prompt => 'AI 번역을 사용하려면 ChatGLM API 키를 설정하세요.';

  @override
  String get go_to_settings => '설정으로 이동';

  @override
  String get api_key_dialog_title => 'AI 번역 API 구성';

  @override
  String get api_key_configuration_title => 'ChatGLM AI 번역';

  @override
  String get api_key_get_key_from => 'ChatGLM 번역을 사용하려면 에서 무료 API 키를 받아야 합니다 ';

  @override
  String get api_key_configuration_steps => 'API 키 구성 단계';

  @override
  String get api_key_step_1 => '1. open.bigmodel.cn을 방문하여 계정 생성';

  @override
  String get api_key_step_2 => '2. API 관리 섹션으로 이동';

  @override
  String get api_key_step_3 => '3. 애플리케이션용 새 API 키 생성';

  @override
  String get api_key_input_label => 'ChatGLM API 키';

  @override
  String get api_key_input_hint => 'ChatGLM API 키를 입력하세요';

  @override
  String get api_key_input_error => '유효한 API 키를 입력하세요';

  @override
  String get api_key_save_button => 'API 키 저장';

  @override
  String get api_key_note => 'API 키는 안전하게 저장되며 번역 서비스에만 사용됩니다.';

  @override
  String get api_key_save_error => '잘못된 API 키입니다. 확인하고 다시 시도하세요.';

  @override
  String get api_key_save_success => 'API 키가 성공적으로 저장되었습니다';

  @override
  String get translation_mode_on_device => '기기 내 번역';

  @override
  String get translation_mode_on_device_description =>
      '기기에 내장된 번역 모델을 사용합니다. 빠르고 오프라인에서 작동하지만, 언어 지원과 정확도가 제한될 수 있습니다.';

  @override
  String get translation_mode_ai => 'AI 번역';

  @override
  String get translation_mode_ai_description =>
      '더 정확하고 문맥에 맞는 번역을 위해 고급 AI 모델을 사용합니다. 인터넷 연결과 API 키가 필요합니다.';

  @override
  String get translation_mode_title => '번역 모드';

  @override
  String get translation_mode_on_device_label => '기기 내';

  @override
  String get translation_mode_ai_label => 'AI';

  @override
  String get close => '닫기';
}
