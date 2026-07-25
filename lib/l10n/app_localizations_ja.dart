// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get app_title => '画面翻訳';

  @override
  String get source_language => '翻訳元';

  @override
  String get target_language => '翻訳先';

  @override
  String get stop_translation => '翻訳を停止';

  @override
  String get translate_screen => '画面を翻訳';

  @override
  String get source_and_target_cannot_be_the_same => '翻訳元と翻訳先の言語が同じです';

  @override
  String get manage_translation_models => '翻訳モデルを管理';

  @override
  String model_download_success(Object language) {
    return '$languageモデルのダウンロードが完了しました';
  }

  @override
  String model_download_error(Object language) {
    return '$languageモデルのダウンロードに失敗しました';
  }

  @override
  String get model_not_downloaded => 'モデルがダウンロードされていません';

  @override
  String get download_model => 'ダウンロード';

  @override
  String get remove_translation_model => '翻訳モデルを削除';

  @override
  String remove_translation_model_confirmation(Object language) {
    return '$languageの翻訳モデルを削除しますか?';
  }

  @override
  String get cancel => 'キャンセル';

  @override
  String get remove => '削除';

  @override
  String get not_installed => 'インストールされていません';

  @override
  String get downloading => 'ダウンロード中';

  @override
  String get installed => 'インストールされています';

  @override
  String get download_failed => 'ダウンロードに失敗しました';

  @override
  String failed_to_remove_model(Object language) {
    return '翻訳モデルを削除するのに失敗しました $language';
  }

  @override
  String failed_to_download_model(Object language) {
    return '翻訳モデルをダウンロードするのに失敗しました $language';
  }

  @override
  String get auto_translate_mode => '自動翻訳';

  @override
  String get manual_translate_mode => '手動翻訳';

  @override
  String get original_text_mode => 'オリジナルテキスト';

  @override
  String get overlay_permission_required => '翻訳モデル';

  @override
  String get overlay_permission_required_content =>
      'このプログラムはスクリーンの翻訳を行うために権限が必要です。';

  @override
  String get grant_permission => '権限を与える';

  @override
  String get language_afrikaans => 'アフリカーンス語';

  @override
  String get language_albanian => 'アルバニア語';

  @override
  String get language_arabic => 'アラビア語';

  @override
  String get language_belarusian => 'ベラルーシ語';

  @override
  String get language_bengali => 'ベンガル語';

  @override
  String get language_bulgarian => 'ブルガリア語';

  @override
  String get language_catalan => 'カタルーニャ語';

  @override
  String get language_chinese => '中国語';

  @override
  String get language_croatian => 'クロアチア語';

  @override
  String get language_czech => 'チェコ語';

  @override
  String get language_danish => 'デンマーク語';

  @override
  String get language_dutch => 'オランダ語';

  @override
  String get language_english => '英語';

  @override
  String get language_esperanto => 'エスペラント語';

  @override
  String get language_estonian => 'エストニア語';

  @override
  String get language_finnish => 'フィンランド語';

  @override
  String get language_french => 'フランス語';

  @override
  String get language_galician => 'ガリシア語';

  @override
  String get language_georgian => 'グルジア語';

  @override
  String get language_german => 'ドイツ語';

  @override
  String get language_greek => 'ギリシャ語';

  @override
  String get language_gujarati => 'グジャラート語';

  @override
  String get language_haitian => 'ハイチ語';

  @override
  String get language_hebrew => 'ヘブライ語';

  @override
  String get language_hindi => 'ヒンディー語';

  @override
  String get language_hungarian => 'ハンガリー語';

  @override
  String get language_icelandic => 'アイスランド語';

  @override
  String get language_indonesian => 'インドネシア語';

  @override
  String get language_irish => 'アイルランド語';

  @override
  String get language_italian => 'イタリア語';

  @override
  String get language_japanese => '日本語';

  @override
  String get language_kannada => 'カンナダ語';

  @override
  String get language_korean => '韓国語';

  @override
  String get language_latvian => 'ラトビア語';

  @override
  String get language_lithuanian => 'リトアニア語';

  @override
  String get language_macedonian => 'マケドニア語';

  @override
  String get language_malay => 'マレー語';

  @override
  String get language_maltese => 'マルタ語';

  @override
  String get language_marathi => 'マラーティー語';

  @override
  String get language_norwegian => 'ノルウェー語';

  @override
  String get language_persian => 'ペルシャ語';

  @override
  String get language_polish => 'ポーランド語';

  @override
  String get language_portuguese => 'ポルトガル語';

  @override
  String get language_romanian => 'ルーマニア語';

  @override
  String get language_russian => 'ロシア語';

  @override
  String get language_slovak => 'スロバキア語';

  @override
  String get language_slovenian => 'スロベニア語';

  @override
  String get language_spanish => 'スペイン語';

  @override
  String get language_swahili => 'スワヒリ語';

  @override
  String get language_swedish => 'スウェーデン語';

  @override
  String get language_tagalog => 'タガログ語';

  @override
  String get language_tamil => 'タミル語';

  @override
  String get language_telugu => 'テルグ語';

  @override
  String get language_thai => 'タイ語';

  @override
  String get language_turkish => 'トルコ語';

  @override
  String get language_ukrainian => 'ウクライナ語';

  @override
  String get language_urdu => 'ウルドゥー語';

  @override
  String get language_vietnamese => 'ベトナム語';

  @override
  String get language_welsh => 'ウェールズ語';

  @override
  String get enjoying_app => 'Screen Translateを楽しんでいますか？';

  @override
  String get review_prompt_message =>
      'あなたのご意見をお聞かせください！Google Playでアプリを評価していただけますか？';

  @override
  String get rate_now => '今すぐ評価';

  @override
  String get not_now => '後で';

  @override
  String get cannot_open_store => 'Google Playストアを開けませんでした';

  @override
  String get api_key_required => 'APIキーが必要です';

  @override
  String get api_key_setup_prompt => 'AI翻訳を使用するには、ChatGLM APIキーを設定してください。';

  @override
  String get go_to_settings => '設定に移動';

  @override
  String get api_key_dialog_title => 'AI翻訳APIの設定';

  @override
  String get api_key_configuration_title => 'ChatGLM AI翻訳';

  @override
  String get api_key_get_key_from =>
      'ChatGLM翻訳を使用するには、ChatGLMの公式サイトから無料のAPIキーを取得する必要があります。';

  @override
  String get api_key_configuration_steps => 'APIキー設定手順';

  @override
  String get api_key_step_1 => '1. ChatGLMの公式サイトにアクセスしてアカウントを作成';

  @override
  String get api_key_step_2 => '2. API管理セクションに移動';

  @override
  String get api_key_step_3 => '3. アプリケーション用の新しいAPIキーを生成';

  @override
  String get api_key_input_label => 'ChatGLM APIキー';

  @override
  String get api_key_input_hint => 'ChatGLM APIキーを入力してください';

  @override
  String get api_key_input_error => '有効なAPIキーを入力してください';

  @override
  String get api_key_save_button => 'APIキーを保存';

  @override
  String get api_key_note => 'APIキーは安全に保存され、翻訳サービスにのみ使用されます。';

  @override
  String get api_key_save_error => '無効なAPIキー。確認して再試行してください。';

  @override
  String get api_key_save_success => 'APIキーが正常に保存されました';

  @override
  String get translation_mode_on_device => 'デバイス内翻訳';

  @override
  String get translation_mode_on_device_description =>
      'デバイスに組み込まれた翻訳モデルを使用します。高速でオフラインでも動作しますが、言語サポートと精度が限定的な場合があります。';

  @override
  String get translation_mode_ai => 'AI翻訳';

  @override
  String get translation_mode_ai_description =>
      'より正確で文脈に応じた翻訳のために、高度なAIモデルを使用します。インターネット接続とAPIキーが必要です。';

  @override
  String get translation_mode_title => '翻訳モード';

  @override
  String get translation_mode_on_device_label => 'デバイス内';

  @override
  String get translation_mode_ai_label => 'AI';

  @override
  String get close => '閉じる';
}
