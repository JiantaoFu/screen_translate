// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get app_title => 'Traduction d\'écran';

  @override
  String get source_language => 'De';

  @override
  String get target_language => 'Vers';

  @override
  String get stop_translation => 'Arrêter la traduction';

  @override
  String get translate_screen => 'Traduire l\'écran';

  @override
  String get source_and_target_cannot_be_the_same =>
      'Les langues source et cible ne peuvent pas être identiques';

  @override
  String get manage_translation_models => 'Gérer les modèles de traduction';

  @override
  String model_download_success(Object language) {
    return 'Modèle $language téléchargé avec succès';
  }

  @override
  String model_download_error(Object language) {
    return 'Échec du téléchargement du modèle $language';
  }

  @override
  String get model_not_downloaded => 'Modèle non téléchargé';

  @override
  String get download_model => 'Télécharger';

  @override
  String get remove_translation_model => 'Supprimer le modèle de traduction';

  @override
  String remove_translation_model_confirmation(Object language) {
    return 'Voulez-vous vraiment supprimer le modèle de traduction pour $language?';
  }

  @override
  String get cancel => 'Annuler';

  @override
  String get remove => 'Supprimer';

  @override
  String get not_installed => 'Non-instalé';

  @override
  String get downloading => 'Téléchargement...';

  @override
  String get installed => 'Instalé';

  @override
  String get download_failed => 'Echec du téléchargement';

  @override
  String failed_to_remove_model(Object language) {
    return 'Échec lors de la suppression du modèle pour $language';
  }

  @override
  String failed_to_download_model(Object language) {
    return 'Échec du téléchargement du modèle pour $language';
  }

  @override
  String get auto_translate_mode => 'Automatisme de traduction';

  @override
  String get manual_translate_mode => 'Traduction manuelle';

  @override
  String get original_text_mode => 'Mode du texte original';

  @override
  String get overlay_permission_required => 'Permission requise';

  @override
  String get overlay_permission_required_content =>
      'Ce programme requiert des permissions pour traduire à l\'écran.';

  @override
  String get grant_permission => 'Accorder les permissions';

  @override
  String get language_afrikaans => 'Afrikaans';

  @override
  String get language_albanian => 'Albanais';

  @override
  String get language_arabic => 'Arabe';

  @override
  String get language_belarusian => 'Biélorusse';

  @override
  String get language_bengali => 'Bengali';

  @override
  String get language_bulgarian => 'Bulgare';

  @override
  String get language_catalan => 'Catalan';

  @override
  String get language_chinese => 'Chinois';

  @override
  String get language_croatian => 'Croate';

  @override
  String get language_czech => 'Tchèque';

  @override
  String get language_danish => 'Danois';

  @override
  String get language_dutch => 'Néerlandais';

  @override
  String get language_english => 'Anglais';

  @override
  String get language_esperanto => 'Espéranto';

  @override
  String get language_estonian => 'Estonien';

  @override
  String get language_finnish => 'Finnois';

  @override
  String get language_french => 'Français';

  @override
  String get language_galician => 'Galicien';

  @override
  String get language_georgian => 'Géorgien';

  @override
  String get language_german => 'Allemand';

  @override
  String get language_greek => 'Grec';

  @override
  String get language_gujarati => 'Gujarati';

  @override
  String get language_haitian => 'Haïtien';

  @override
  String get language_hebrew => 'Hébreu';

  @override
  String get language_hindi => 'Hindi';

  @override
  String get language_hungarian => 'Hongrois';

  @override
  String get language_icelandic => 'Islandais';

  @override
  String get language_indonesian => 'Indonésien';

  @override
  String get language_irish => 'Irlandais';

  @override
  String get language_italian => 'Italien';

  @override
  String get language_japanese => 'Japonais';

  @override
  String get language_kannada => 'Kannada';

  @override
  String get language_korean => 'Coréen';

  @override
  String get language_latvian => 'Letton';

  @override
  String get language_lithuanian => 'Lituanien';

  @override
  String get language_macedonian => 'Macédonien';

  @override
  String get language_malay => 'Malais';

  @override
  String get language_maltese => 'Maltais';

  @override
  String get language_marathi => 'Marathi';

  @override
  String get language_norwegian => 'Norvégien';

  @override
  String get language_persian => 'Persan';

  @override
  String get language_polish => 'Polonais';

  @override
  String get language_portuguese => 'Portugais';

  @override
  String get language_romanian => 'Roumain';

  @override
  String get language_russian => 'Russe';

  @override
  String get language_slovak => 'Slovaque';

  @override
  String get language_slovenian => 'Slovène';

  @override
  String get language_spanish => 'Espagnol';

  @override
  String get language_swahili => 'Swahili';

  @override
  String get language_swedish => 'Suédois';

  @override
  String get language_tagalog => 'Tagalog';

  @override
  String get language_tamil => 'Tamoul';

  @override
  String get language_telugu => 'Telugu';

  @override
  String get language_thai => 'Thaï';

  @override
  String get language_turkish => 'Turc';

  @override
  String get language_ukrainian => 'Ukrainien';

  @override
  String get language_urdu => 'Ourdou';

  @override
  String get language_vietnamese => 'Vietnamien';

  @override
  String get language_welsh => 'Gallois';

  @override
  String get enjoying_app => 'Aimez-vous Screen Translate ?';

  @override
  String get review_prompt_message =>
      'Nous aimerions avoir votre avis ! Souhaitez-vous noter l\'application sur Google Play ?';

  @override
  String get rate_now => 'Noter maintenant';

  @override
  String get not_now => 'Pas maintenant';

  @override
  String get cannot_open_store => 'Impossible d\'ouvrir Google Play Store';

  @override
  String get api_key_required => 'Clé API requise';

  @override
  String get api_key_setup_prompt =>
      'Veuillez configurer votre clé API ChatGLM pour utiliser la traduction par IA.';

  @override
  String get go_to_settings => 'Aller aux paramètres';

  @override
  String get api_key_dialog_title =>
      'Configuration de l\'API de Traduction par IA';

  @override
  String get api_key_configuration_title => 'Traduction ChatGLM par IA';

  @override
  String get api_key_get_key_from =>
      'Pour utiliser les traductions ChatGLM, vous devez obtenir une clé API gratuite depuis ';

  @override
  String get api_key_configuration_steps =>
      'Étapes de Configuration de la Clé API';

  @override
  String get api_key_step_1 => '1. Visitez open.bigmodel.cn et créez un compte';

  @override
  String get api_key_step_2 => '2. Accédez à la section de Gestion des API';

  @override
  String get api_key_step_3 =>
      '3. Générez une nouvelle clé API pour votre application';

  @override
  String get api_key_input_label => 'Clé API ChatGLM';

  @override
  String get api_key_input_hint => 'Entrez votre clé API ChatGLM';

  @override
  String get api_key_input_error => 'Veuillez entrer une clé API valide';

  @override
  String get api_key_save_button => 'Enregistrer la Clé API';

  @override
  String get api_key_note =>
      'Votre clé API sera stockée en toute sécurité et utilisée uniquement pour les services de traduction.';

  @override
  String get api_key_save_error => 'Clé API invalide. Vérifiez et réessayez.';

  @override
  String get api_key_save_success => 'Clé API enregistrée avec succès';

  @override
  String get translation_mode_on_device => 'Traduction sur Appareil';

  @override
  String get translation_mode_on_device_description =>
      'Utilise des modèles de traduction intégrés sur votre appareil. Rapide et fonctionne hors ligne, mais peut avoir un support linguistique et une précision limités.';

  @override
  String get translation_mode_ai => 'Traduction par IA';

  @override
  String get translation_mode_ai_description =>
      'Utilise des modèles d\'IA avancés pour des traductions plus précises et contextuelles. Nécessite une connexion Internet et une clé API.';

  @override
  String get translation_mode_title => 'Mode de Traduction';

  @override
  String get translation_mode_on_device_label => 'Sur Appareil';

  @override
  String get translation_mode_ai_label => 'IA';

  @override
  String get close => 'Fermer';
}
