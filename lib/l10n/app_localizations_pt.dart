// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get app_title => 'Tradução de tela';

  @override
  String get source_language => 'De';

  @override
  String get target_language => 'Para';

  @override
  String get stop_translation => 'Parar tradução';

  @override
  String get translate_screen => 'Traduzir tela';

  @override
  String get source_and_target_cannot_be_the_same =>
      'Os idiomas de origem e destino não podem ser iguais';

  @override
  String get manage_translation_models => 'Gerenciar modelos de tradução';

  @override
  String model_download_success(Object language) {
    return 'Modelo para $language baixado com sucesso';
  }

  @override
  String model_download_error(Object language) {
    return 'Erro ao baixar modelo para $language';
  }

  @override
  String get model_not_downloaded => 'Modelo não baixado';

  @override
  String get download_model => 'Baixar';

  @override
  String get remove_translation_model => 'Remover modelo de tradução';

  @override
  String remove_translation_model_confirmation(Object language) {
    return 'Tem certeza de que deseja remover o modelo de tradução para $language?';
  }

  @override
  String get cancel => 'Cancelar';

  @override
  String get remove => 'Remover';

  @override
  String get not_installed => 'Não instalado';

  @override
  String get downloading => 'Baixando...';

  @override
  String get installed => 'Instalado';

  @override
  String get download_failed => 'Fallo ao baixar';

  @override
  String failed_to_remove_model(Object language) {
    return 'Fallo ao remover o modelo para $language';
  }

  @override
  String failed_to_download_model(Object language) {
    return 'Fallo ao baixar o modelo para $language';
  }

  @override
  String get auto_translate_mode => 'Tradução automática';

  @override
  String get manual_translate_mode => 'Tradução manual';

  @override
  String get original_text_mode => 'Módulo de texto original';

  @override
  String get overlay_permission_required => 'Módulo de tradução';

  @override
  String get overlay_permission_required_content =>
      'Este programa requiere permisos para traducir en la pantalla.';

  @override
  String get grant_permission => 'Permitir permisos';

  @override
  String get language_afrikaans => 'Africâner';

  @override
  String get language_albanian => 'Albanês';

  @override
  String get language_arabic => 'Árabe';

  @override
  String get language_belarusian => 'Bielorrusso';

  @override
  String get language_bengali => 'Bengali';

  @override
  String get language_bulgarian => 'Búlgaro';

  @override
  String get language_catalan => 'Catalão';

  @override
  String get language_chinese => 'Chinês';

  @override
  String get language_croatian => 'Croata';

  @override
  String get language_czech => 'Tcheco';

  @override
  String get language_danish => 'Dinamarquês';

  @override
  String get language_dutch => 'Holandês';

  @override
  String get language_english => 'Inglês';

  @override
  String get language_esperanto => 'Esperanto';

  @override
  String get language_estonian => 'Estoniano';

  @override
  String get language_finnish => 'Finlandês';

  @override
  String get language_french => 'Francês';

  @override
  String get language_galician => 'Galego';

  @override
  String get language_georgian => 'Georgiano';

  @override
  String get language_german => 'Alemão';

  @override
  String get language_greek => 'Grego';

  @override
  String get language_gujarati => 'Gujarati';

  @override
  String get language_haitian => 'Haitiano';

  @override
  String get language_hebrew => 'Hebraico';

  @override
  String get language_hindi => 'Hindi';

  @override
  String get language_hungarian => 'Húngaro';

  @override
  String get language_icelandic => 'Islandês';

  @override
  String get language_indonesian => 'Indonésio';

  @override
  String get language_irish => 'Irlandês';

  @override
  String get language_italian => 'Italiano';

  @override
  String get language_japanese => 'Japonês';

  @override
  String get language_kannada => 'Canarês';

  @override
  String get language_korean => 'Coreano';

  @override
  String get language_latvian => 'Letão';

  @override
  String get language_lithuanian => 'Lituano';

  @override
  String get language_macedonian => 'Macedônio';

  @override
  String get language_malay => 'Malaio';

  @override
  String get language_maltese => 'Maltês';

  @override
  String get language_marathi => 'Marati';

  @override
  String get language_norwegian => 'Norueguês';

  @override
  String get language_persian => 'Persa';

  @override
  String get language_polish => 'Polonês';

  @override
  String get language_portuguese => 'Português';

  @override
  String get language_romanian => 'Romeno';

  @override
  String get language_russian => 'Russo';

  @override
  String get language_slovak => 'Eslovaco';

  @override
  String get language_slovenian => 'Esloveno';

  @override
  String get language_spanish => 'Espanhol';

  @override
  String get language_swahili => 'Suaíli';

  @override
  String get language_swedish => 'Sueco';

  @override
  String get language_tagalog => 'Tagalo';

  @override
  String get language_tamil => 'Tâmil';

  @override
  String get language_telugu => 'Telugu';

  @override
  String get language_thai => 'Tailandês';

  @override
  String get language_turkish => 'Turco';

  @override
  String get language_ukrainian => 'Ucraniano';

  @override
  String get language_urdu => 'Urdu';

  @override
  String get language_vietnamese => 'Vietnamita';

  @override
  String get language_welsh => 'Galês';

  @override
  String get enjoying_app => 'Está gostando do Screen Translate?';

  @override
  String get review_prompt_message =>
      'Adoraríamos ouvir sua opinião! Gostaria de avaliar o aplicativo no Google Play?';

  @override
  String get rate_now => 'Avaliar agora';

  @override
  String get not_now => 'Agora não';

  @override
  String get cannot_open_store => 'Não foi possível abrir a Google Play Store';

  @override
  String get api_key_required => 'Chave API necessária';

  @override
  String get api_key_setup_prompt =>
      'Por favor, configure sua chave API do ChatGLM para usar tradução por IA.';

  @override
  String get go_to_settings => 'Ir para Configurações';

  @override
  String get api_key_dialog_title => 'Configuração de API de Tradução por IA';

  @override
  String get api_key_configuration_title => 'Tradução ChatGLM por IA';

  @override
  String get api_key_get_key_from =>
      'Para usar traduções ChatGLM, você precisa obter uma chave API gratuita de ';

  @override
  String get api_key_configuration_steps =>
      'Etapas de Configuração da Chave API';

  @override
  String get api_key_step_1 => '1. Visite open.bigmodel.cn e crie uma conta';

  @override
  String get api_key_step_2 => '2. Navegue até a seção de Gerenciamento de API';

  @override
  String get api_key_step_3 => '3. Gere uma nova chave API para seu aplicativo';

  @override
  String get api_key_input_label => 'Chave API ChatGLM';

  @override
  String get api_key_input_hint => 'Insira sua chave API ChatGLM';

  @override
  String get api_key_input_error => 'Por favor, insira uma chave API válida';

  @override
  String get api_key_save_button => 'Salvar Chave API';

  @override
  String get api_key_note =>
      'Sua chave API será armazenada com segurança e usada apenas para serviços de tradução.';

  @override
  String get api_key_save_error =>
      'Chave API inválida. Verifique e tente novamente.';

  @override
  String get api_key_save_success => 'Chave API salva com sucesso';

  @override
  String get translation_mode_on_device => 'Tradução no Dispositivo';

  @override
  String get translation_mode_on_device_description =>
      'Usa modelos de tradução integrados no seu dispositivo. Rápido e funciona offline, mas pode ter suporte de idioma e precisão limitados.';

  @override
  String get translation_mode_ai => 'Tradução por IA';

  @override
  String get translation_mode_ai_description =>
      'Usa modelos de IA avançados para traduções mais precisas e contextuais. Requer conexão à internet e chave de API.';

  @override
  String get translation_mode_title => 'Modo de Tradução';

  @override
  String get translation_mode_on_device_label => 'No Dispositivo';

  @override
  String get translation_mode_ai_label => 'IA';

  @override
  String get close => 'Fechar';
}
