// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get app_title => '屏幕翻译';

  @override
  String get source_language => '源语言';

  @override
  String get target_language => '目标语言';

  @override
  String get stop_translation => '停止翻译';

  @override
  String get translate_screen => '翻译屏幕';

  @override
  String get source_and_target_cannot_be_the_same => '源语言和目标语言不能相同';

  @override
  String get manage_translation_models => '管理翻译模型';

  @override
  String model_download_success(Object language) {
    return '$language模型下载成功';
  }

  @override
  String model_download_error(Object language) {
    return '下载$language模型失败';
  }

  @override
  String get model_not_downloaded => '模型未下载';

  @override
  String get download_model => '下载';

  @override
  String get remove_translation_model => '移除翻译模型';

  @override
  String remove_translation_model_confirmation(Object language) {
    return '确定要移除$language翻译模型吗?';
  }

  @override
  String get cancel => '取消';

  @override
  String get remove => '移除';

  @override
  String get not_installed => '未安装';

  @override
  String get downloading => '下载中...';

  @override
  String get installed => '已安装';

  @override
  String get download_failed => '下载失败';

  @override
  String failed_to_remove_model(Object language) {
    return '移除$language翻译模型失败';
  }

  @override
  String failed_to_download_model(Object language) {
    return '下载$language翻译模型失败';
  }

  @override
  String get auto_translate_mode => '自动翻译模式';

  @override
  String get manual_translate_mode => '手动翻译模式';

  @override
  String get original_text_mode => '原文模式';

  @override
  String get overlay_permission_required => '翻译模型';

  @override
  String get overlay_permission_required_content => '此程序需要屏幕覆盖权限';

  @override
  String get grant_permission => '授予权限';

  @override
  String get language_afrikaans => '南非语';

  @override
  String get language_albanian => '阿尔巴尼亚语';

  @override
  String get language_arabic => '阿拉伯语';

  @override
  String get language_belarusian => '白俄罗斯语';

  @override
  String get language_bengali => '孟加拉语';

  @override
  String get language_bulgarian => '保加利亚语';

  @override
  String get language_catalan => '加泰罗尼亚语';

  @override
  String get language_chinese => '中文';

  @override
  String get language_croatian => '克罗地亚语';

  @override
  String get language_czech => '捷克语';

  @override
  String get language_danish => '丹麦语';

  @override
  String get language_dutch => '荷兰语';

  @override
  String get language_english => '英语';

  @override
  String get language_esperanto => '世界语';

  @override
  String get language_estonian => '爱沙尼亚语';

  @override
  String get language_finnish => '芬兰语';

  @override
  String get language_french => '法语';

  @override
  String get language_galician => '加利西亚语';

  @override
  String get language_georgian => '格鲁吉亚语';

  @override
  String get language_german => '德语';

  @override
  String get language_greek => '希腊语';

  @override
  String get language_gujarati => '古吉拉特语';

  @override
  String get language_haitian => '海地克里奥尔语';

  @override
  String get language_hebrew => '希伯来语';

  @override
  String get language_hindi => '印地语';

  @override
  String get language_hungarian => '匈牙利语';

  @override
  String get language_icelandic => '冰岛语';

  @override
  String get language_indonesian => '印度尼西亚语';

  @override
  String get language_irish => '爱尔兰语';

  @override
  String get language_italian => '意大利语';

  @override
  String get language_japanese => '日语';

  @override
  String get language_kannada => '卡纳达语';

  @override
  String get language_korean => '韩语';

  @override
  String get language_latvian => '拉脱维亚语';

  @override
  String get language_lithuanian => '立陶宛语';

  @override
  String get language_macedonian => '马其顿语';

  @override
  String get language_malay => '马来语';

  @override
  String get language_maltese => '马耳他语';

  @override
  String get language_marathi => '马拉地语';

  @override
  String get language_norwegian => '挪威语';

  @override
  String get language_persian => '波斯语';

  @override
  String get language_polish => '波兰语';

  @override
  String get language_portuguese => '葡萄牙语';

  @override
  String get language_romanian => '罗马尼亚语';

  @override
  String get language_russian => '俄语';

  @override
  String get language_slovak => '斯洛伐克语';

  @override
  String get language_slovenian => '斯洛文尼亚语';

  @override
  String get language_spanish => '西班牙语';

  @override
  String get language_swahili => '斯瓦希里语';

  @override
  String get language_swedish => '瑞典语';

  @override
  String get language_tagalog => '他加禄语';

  @override
  String get language_tamil => '泰米尔语';

  @override
  String get language_telugu => '泰卢固语';

  @override
  String get language_thai => '泰语';

  @override
  String get language_turkish => '土耳其语';

  @override
  String get language_ukrainian => '乌克兰语';

  @override
  String get language_urdu => '乌尔都语';

  @override
  String get language_vietnamese => '越南语';

  @override
  String get language_welsh => '威尔士语';

  @override
  String get enjoying_app => '喜欢 Screen Translate 吗？';

  @override
  String get review_prompt_message => '我们很想听听您的反馈！您是否愿意在 Google Play 上评价这个应用？';

  @override
  String get rate_now => '立即评价';

  @override
  String get not_now => '暂不评价';

  @override
  String get cannot_open_store => '无法打开 Google Play Store';

  @override
  String get api_key_required => '需要 API 密钥';

  @override
  String get api_key_setup_prompt => '请设置您的 ChatGLM API 密钥以使用 AI 翻译。';

  @override
  String get go_to_settings => '转到设置';

  @override
  String get api_key_dialog_title => 'AI翻译API配置';

  @override
  String get api_key_configuration_title => 'ChatGLM AI翻译';

  @override
  String get api_key_get_key_from => '要使用ChatGLM翻译，您需要从获取免费的API密钥 ';

  @override
  String get api_key_configuration_steps => 'API密钥配置步骤';

  @override
  String get api_key_step_1 => '1. 访问open.bigmodel.cn并创建账户';

  @override
  String get api_key_step_2 => '2. 导航到API管理部分';

  @override
  String get api_key_step_3 => '3. 为您的应用程序生成新的API密钥';

  @override
  String get api_key_input_label => 'ChatGLM API密钥';

  @override
  String get api_key_input_hint => '输入您的ChatGLM API密钥';

  @override
  String get api_key_input_error => '请输入有效的API密钥';

  @override
  String get api_key_save_button => '保存API密钥';

  @override
  String get api_key_note => '您的API密钥将安全存储，仅用于翻译服务。';

  @override
  String get api_key_save_error => '无效的API密钥。请检查并重试。';

  @override
  String get api_key_save_success => 'API密钥保存成功';

  @override
  String get translation_mode_on_device => '设备内翻译';

  @override
  String get translation_mode_on_device_description =>
      '使用设备内置的翻译模型。快速且可离线使用，但语言支持和准确性可能有限。';

  @override
  String get translation_mode_ai => 'AI翻译';

  @override
  String get translation_mode_ai_description =>
      '使用先进的AI模型进行更精确和上下文相关的翻译。需要互联网连接和API密钥。';

  @override
  String get translation_mode_title => '翻译模式';

  @override
  String get translation_mode_on_device_label => '设备内';

  @override
  String get translation_mode_ai_label => 'AI';

  @override
  String get close => '关闭';
}
