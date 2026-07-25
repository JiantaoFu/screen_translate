// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get app_title => 'Traductor de pantalla';

  @override
  String get source_language => 'Desde';

  @override
  String get target_language => 'A';

  @override
  String get stop_translation => 'Parar la traducción';

  @override
  String get translate_screen => 'Traducir pantalla';

  @override
  String get source_and_target_cannot_be_the_same =>
      'Los idiomas de origen y destino no pueden ser iguales';

  @override
  String get manage_translation_models => 'Administrar modelos de traducción';

  @override
  String model_download_success(Object language) {
    return 'Modelo de $language descargado exitosamente';
  }

  @override
  String model_download_error(Object language) {
    return 'Error al descargar el modelo de $language';
  }

  @override
  String get model_not_downloaded => 'Modelo no descargado';

  @override
  String get download_model => 'Descargar';

  @override
  String get remove_translation_model => 'Eliminar modelo de traducción';

  @override
  String remove_translation_model_confirmation(Object language) {
    return '¿Seguro que quieres eliminar el modelo de traducción para $language?';
  }

  @override
  String get cancel => 'Cancelar';

  @override
  String get remove => 'Eliminar';

  @override
  String get not_installed => 'No instalado';

  @override
  String get downloading => 'Descargando...';

  @override
  String get installed => 'Instalado';

  @override
  String get download_failed => 'Fallo al descargar';

  @override
  String failed_to_remove_model(Object language) {
    return 'Fallo al eliminar el modelo para $language';
  }

  @override
  String failed_to_download_model(Object language) {
    return 'Fallo al descargar el modelo para $language';
  }

  @override
  String get auto_translate_mode => 'Automatismo de traducción';

  @override
  String get manual_translate_mode => 'Traducción manual';

  @override
  String get original_text_mode => 'Módulo de texto original';

  @override
  String get overlay_permission_required => 'Permiso requerido';

  @override
  String get overlay_permission_required_content =>
      'Este programa requiere permisos para traducir en la pantalla.';

  @override
  String get grant_permission => 'Conceder permisos';

  @override
  String get language_afrikaans => 'Afrikaans';

  @override
  String get language_albanian => 'Albanés';

  @override
  String get language_arabic => 'Árabe';

  @override
  String get language_belarusian => 'Bielorruso';

  @override
  String get language_bengali => 'Bengalí';

  @override
  String get language_bulgarian => 'Búlgaro';

  @override
  String get language_catalan => 'Catalán';

  @override
  String get language_chinese => 'Chino';

  @override
  String get language_croatian => 'Croata';

  @override
  String get language_czech => 'Checo';

  @override
  String get language_danish => 'Danés';

  @override
  String get language_dutch => 'Holandés';

  @override
  String get language_english => 'Inglés';

  @override
  String get language_esperanto => 'Esperanto';

  @override
  String get language_estonian => 'Estonio';

  @override
  String get language_finnish => 'Finlandés';

  @override
  String get language_french => 'Francés';

  @override
  String get language_galician => 'Gallego';

  @override
  String get language_georgian => 'Georgiano';

  @override
  String get language_german => 'Alemán';

  @override
  String get language_greek => 'Griego';

  @override
  String get language_gujarati => 'Gujarati';

  @override
  String get language_haitian => 'Haitiano';

  @override
  String get language_hebrew => 'Hebreo';

  @override
  String get language_hindi => 'Hindi';

  @override
  String get language_hungarian => 'Húngaro';

  @override
  String get language_icelandic => 'Islandés';

  @override
  String get language_indonesian => 'Indonesio';

  @override
  String get language_irish => 'Irlandés';

  @override
  String get language_italian => 'Italiano';

  @override
  String get language_japanese => 'Japonés';

  @override
  String get language_kannada => 'Canarés';

  @override
  String get language_korean => 'Coreano';

  @override
  String get language_latvian => 'Letón';

  @override
  String get language_lithuanian => 'Lituano';

  @override
  String get language_macedonian => 'Macedonio';

  @override
  String get language_malay => 'Malayo';

  @override
  String get language_maltese => 'Maltés';

  @override
  String get language_marathi => 'Marathi';

  @override
  String get language_norwegian => 'Noruego';

  @override
  String get language_persian => 'Persa';

  @override
  String get language_polish => 'Polaco';

  @override
  String get language_portuguese => 'Portugués';

  @override
  String get language_romanian => 'Rumano';

  @override
  String get language_russian => 'Ruso';

  @override
  String get language_slovak => 'Eslovaco';

  @override
  String get language_slovenian => 'Esloveno';

  @override
  String get language_spanish => 'Español';

  @override
  String get language_swahili => 'Swahili';

  @override
  String get language_swedish => 'Sueco';

  @override
  String get language_tagalog => 'Tagalo';

  @override
  String get language_tamil => 'Tamil';

  @override
  String get language_telugu => 'Telugu';

  @override
  String get language_thai => 'Tailandés';

  @override
  String get language_turkish => 'Turco';

  @override
  String get language_ukrainian => 'Ucraniano';

  @override
  String get language_urdu => 'Urdu';

  @override
  String get language_vietnamese => 'Vietnamita';

  @override
  String get language_welsh => 'Galés';

  @override
  String get enjoying_app => '¿Disfrutando de Screen Translate?';

  @override
  String get review_prompt_message =>
      '¡Nos encantará conocer su opinión! ¿Le gustaría calificar la aplicación en Google Play?';

  @override
  String get rate_now => 'Calificar ahora';

  @override
  String get not_now => 'Ahora no';

  @override
  String get cannot_open_store => 'No se pudo abrir Google Play Store';

  @override
  String get api_key_required => 'Se requiere clave API';

  @override
  String get api_key_setup_prompt =>
      'Por favor, configure su clave API de ChatGLM para usar traducción por IA.';

  @override
  String get go_to_settings => 'Ir a Configuración';

  @override
  String get api_key_dialog_title => 'Configuración de API de Traducción de IA';

  @override
  String get api_key_configuration_title => 'Traducción de IA ChatGLM';

  @override
  String get api_key_get_key_from =>
      'Para usar traducciones de ChatGLM, necesita obtener una clave API gratuita de ';

  @override
  String get api_key_configuration_steps =>
      'Pasos de Configuración de Clave API';

  @override
  String get api_key_step_1 => '1. Visite open.bigmodel.cn y cree una cuenta';

  @override
  String get api_key_step_2 =>
      '2. Navegue a la sección de Administración de API';

  @override
  String get api_key_step_3 =>
      '3. Genere una nueva clave API para su aplicación';

  @override
  String get api_key_input_label => 'Clave API de ChatGLM';

  @override
  String get api_key_input_hint => 'Ingrese su clave API de ChatGLM';

  @override
  String get api_key_input_error => 'Ingrese una clave API válida';

  @override
  String get api_key_save_button => 'Guardar Clave API';

  @override
  String get api_key_note =>
      'Su clave API se almacenará de forma segura y se utilizará únicamente para servicios de traducción.';

  @override
  String get api_key_save_error =>
      'Clave API no válida. Verifique e inténtelo de nuevo.';

  @override
  String get api_key_save_success => 'Clave API guardada con éxito';

  @override
  String get translation_mode_on_device => 'Traducción en Dispositivo';

  @override
  String get translation_mode_on_device_description =>
      'Utiliza modelos de traducción integrados en su dispositivo. Rápido y funciona sin conexión, pero puede tener soporte de idioma y precisión limitados.';

  @override
  String get translation_mode_ai => 'Traducción con IA';

  @override
  String get translation_mode_ai_description =>
      'Utiliza modelos de IA avanzados para traducciones más precisas y contextuales. Requiere conexión a internet y clave API.';

  @override
  String get translation_mode_title => 'Modo de Traducción';

  @override
  String get translation_mode_on_device_label => 'En Dispositivo';

  @override
  String get translation_mode_ai_label => 'IA';

  @override
  String get close => 'Cerrar';
}
