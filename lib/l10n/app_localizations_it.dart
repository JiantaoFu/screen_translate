// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get app_title => 'Traduzione schermo';

  @override
  String get source_language => 'Da';

  @override
  String get target_language => 'A';

  @override
  String get stop_translation => 'Ferma traduzione';

  @override
  String get translate_screen => 'Traduci schermo';

  @override
  String get source_and_target_cannot_be_the_same =>
      'La lingua di origine e di destinazione non possono essere uguali';

  @override
  String get manage_translation_models => 'Gestisci modelli di traduzione';

  @override
  String model_download_success(Object language) {
    return 'Modello per $language scaricato con successo';
  }

  @override
  String model_download_error(Object language) {
    return 'Errore durante il download del modello per $language';
  }

  @override
  String get model_not_downloaded => 'Modello non scaricato';

  @override
  String get download_model => 'Scarica';

  @override
  String get remove_translation_model => 'Rimuovi modello di traduzione';

  @override
  String remove_translation_model_confirmation(Object language) {
    return 'Sei sicuro di voler rimuovere il modello di traduzione per $language?';
  }

  @override
  String get cancel => 'Annulla';

  @override
  String get remove => 'Rimuovi';

  @override
  String get not_installed => 'Non installato';

  @override
  String get downloading => 'Scaricamento...';

  @override
  String get installed => 'Installato';

  @override
  String get download_failed => 'Scaricamento fallito';

  @override
  String failed_to_remove_model(Object language) {
    return 'Impossibile rimuovere il modello di traduzione per $language';
  }

  @override
  String failed_to_download_model(Object language) {
    return 'Impossibile scaricare il modello di traduzione per $language';
  }

  @override
  String get auto_translate_mode => 'Automatismo di traduzione';

  @override
  String get manual_translate_mode => 'Traduzione manuale';

  @override
  String get original_text_mode => 'Testo originale';

  @override
  String get overlay_permission_required => 'Modalità di traduzione';

  @override
  String get overlay_permission_required_content =>
      'Questo programma ha bisogno di permessi per tradurre sullo schermo.';

  @override
  String get grant_permission => 'Gestisci permessi';

  @override
  String get language_afrikaans => 'Afrikaans';

  @override
  String get language_albanian => 'Albanese';

  @override
  String get language_arabic => 'Arabo';

  @override
  String get language_belarusian => 'Bielorusso';

  @override
  String get language_bengali => 'Bengali';

  @override
  String get language_bulgarian => 'Bulgaro';

  @override
  String get language_catalan => 'Catalano';

  @override
  String get language_chinese => 'Cinese';

  @override
  String get language_croatian => 'Croato';

  @override
  String get language_czech => 'Ceco';

  @override
  String get language_danish => 'Danese';

  @override
  String get language_dutch => 'Olandese';

  @override
  String get language_english => 'Inglese';

  @override
  String get language_esperanto => 'Esperanto';

  @override
  String get language_estonian => 'Estone';

  @override
  String get language_finnish => 'Finlandese';

  @override
  String get language_french => 'Francese';

  @override
  String get language_galician => 'Galiziano';

  @override
  String get language_georgian => 'Georgiano';

  @override
  String get language_german => 'Tedesco';

  @override
  String get language_greek => 'Greco';

  @override
  String get language_gujarati => 'Gujarati';

  @override
  String get language_haitian => 'Haitiano';

  @override
  String get language_hebrew => 'Ebraico';

  @override
  String get language_hindi => 'Hindi';

  @override
  String get language_hungarian => 'Ungherese';

  @override
  String get language_icelandic => 'Islandese';

  @override
  String get language_indonesian => 'Indonesiano';

  @override
  String get language_irish => 'Irlandese';

  @override
  String get language_italian => 'Italiano';

  @override
  String get language_japanese => 'Giapponese';

  @override
  String get language_kannada => 'Kannada';

  @override
  String get language_korean => 'Coreano';

  @override
  String get language_latvian => 'Lettone';

  @override
  String get language_lithuanian => 'Lituano';

  @override
  String get language_macedonian => 'Macedone';

  @override
  String get language_malay => 'Malese';

  @override
  String get language_maltese => 'Maltese';

  @override
  String get language_marathi => 'Marathi';

  @override
  String get language_norwegian => 'Norvegese';

  @override
  String get language_persian => 'Persiano';

  @override
  String get language_polish => 'Polacco';

  @override
  String get language_portuguese => 'Portoghese';

  @override
  String get language_romanian => 'Rumeno';

  @override
  String get language_russian => 'Russo';

  @override
  String get language_slovak => 'Slovacco';

  @override
  String get language_slovenian => 'Sloveno';

  @override
  String get language_spanish => 'Spagnolo';

  @override
  String get language_swahili => 'Swahili';

  @override
  String get language_swedish => 'Svedese';

  @override
  String get language_tagalog => 'Tagalog';

  @override
  String get language_tamil => 'Tamil';

  @override
  String get language_telugu => 'Telugu';

  @override
  String get language_thai => 'Thailandese';

  @override
  String get language_turkish => 'Turco';

  @override
  String get language_ukrainian => 'Ucraino';

  @override
  String get language_urdu => 'Urdu';

  @override
  String get language_vietnamese => 'Vietnamita';

  @override
  String get language_welsh => 'Gallese';

  @override
  String get enjoying_app => 'Ti piace Screen Translate?';

  @override
  String get review_prompt_message =>
      'Vorremmo sentire il tuo parere! Vorresti valutare l\'app su Google Play?';

  @override
  String get rate_now => 'Valuta ora';

  @override
  String get not_now => 'Non ora';

  @override
  String get cannot_open_store => 'Impossibile aprire Google Play Store';

  @override
  String get api_key_required => 'Chiave API richiesta';

  @override
  String get api_key_setup_prompt =>
      'Configura la tua chiave API ChatGLM per utilizzare la traduzione con IA.';

  @override
  String get go_to_settings => 'Vai alle Impostazioni';

  @override
  String get api_key_dialog_title => 'Configurazione API Traduzione IA';

  @override
  String get api_key_configuration_title => 'Traduzione ChatGLM con IA';

  @override
  String get api_key_get_key_from =>
      'Per utilizzare le traduzioni ChatGLM, è necessario ottenere una chiave API gratuita da ';

  @override
  String get api_key_configuration_steps =>
      'Passaggi di Configurazione Chiave API';

  @override
  String get api_key_step_1 => '1. Visita open.bigmodel.cn e crea un account';

  @override
  String get api_key_step_2 => '2. Vai alla sezione Gestione API';

  @override
  String get api_key_step_3 =>
      '3. Genera una nuova chiave API per la tua applicazione';

  @override
  String get api_key_input_label => 'Chiave API ChatGLM';

  @override
  String get api_key_input_hint => 'Inserisci la tua chiave API ChatGLM';

  @override
  String get api_key_input_error => 'Inserisci una chiave API valida';

  @override
  String get api_key_save_button => 'Salva Chiave API';

  @override
  String get api_key_note =>
      'La tua chiave API verrà archiviata in modo sicuro e utilizzata solo per servizi di traduzione.';

  @override
  String get api_key_save_error =>
      'Chiave API non valida. Controlla e riprova.';

  @override
  String get api_key_save_success => 'Chiave API salvata con successo';

  @override
  String get translation_mode_on_device => 'Traduzione sul Dispositivo';

  @override
  String get translation_mode_on_device_description =>
      'Utilizza modelli di traduzione integrati sul tuo dispositivo. Veloce e funziona offline, ma può avere un supporto linguistico e una precisione limitati.';

  @override
  String get translation_mode_ai => 'Traduzione con IA';

  @override
  String get translation_mode_ai_description =>
      'Utilizza modelli di IA avanzati per traduzioni più precise e contestuali. Richiede una connessione Internet e una chiave API.';

  @override
  String get translation_mode_title => 'Modalità di Traduzione';

  @override
  String get translation_mode_on_device_label => 'Sul Dispositivo';

  @override
  String get translation_mode_ai_label => 'IA';

  @override
  String get close => 'Chiudi';
}
