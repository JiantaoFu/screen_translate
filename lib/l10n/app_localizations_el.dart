// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Modern Greek (`el`).
class AppLocalizationsEl extends AppLocalizations {
  AppLocalizationsEl([String locale = 'el']) : super(locale);

  @override
  String get app_title => 'Μετάφραση οθόνης';

  @override
  String get source_language => 'Από';

  @override
  String get target_language => 'Προς';

  @override
  String get stop_translation => 'Διακοπή μετάφρασης';

  @override
  String get translate_screen => 'Μετάφραση οθόνης';

  @override
  String get source_and_target_cannot_be_the_same =>
      'Η γλώσσα προέλευσης και προορισμού δεν μπορούν να είναι ίδιες';

  @override
  String get manage_translation_models => 'Διαχείριση μοντέλων μετάφρασης';

  @override
  String model_download_success(Object language) {
    return 'Το μοντέλο για τα $language λήφθηκε με επιτυχία';
  }

  @override
  String model_download_error(Object language) {
    return 'Σφάλμα κατά τη λήψη του μοντέλου για τα $language';
  }

  @override
  String get model_not_downloaded => 'Το μοντέλο δεν έχει ληφθεί';

  @override
  String get download_model => 'Λήψη';

  @override
  String get remove_translation_model => 'Αφαιρισμός μοντέλου μετάφρασης';

  @override
  String remove_translation_model_confirmation(Object language) {
    return 'Θέλετε να αφαιρεθεί το μοντέλο για τα $language;';
  }

  @override
  String get cancel => 'Ακυρωση';

  @override
  String get remove => 'Αφαιριση';

  @override
  String get not_installed => 'Δεν είναι εγκαταστάθηκε';

  @override
  String get downloading => 'Λήψη...';

  @override
  String get installed => 'Εγκαταστάθηκε';

  @override
  String get download_failed => 'Λήψη αποτυχίας';

  @override
  String failed_to_remove_model(Object language) {
    return 'Αποτυχία κατά την αφαιριση του μοντέλου για τα $language';
  }

  @override
  String failed_to_download_model(Object language) {
    return 'Αποτυχία κατά την λήψη του μοντέλου για τα $language';
  }

  @override
  String get auto_translate_mode => 'Μοντέλο μετάφρασης';

  @override
  String get manual_translate_mode => 'Μοντέλο μετάφρασης';

  @override
  String get original_text_mode => 'Μοντέλο κεφαλης κειμενου';

  @override
  String get overlay_permission_required => 'Μοντέλο μετάφρασης';

  @override
  String get overlay_permission_required_content =>
      'Αυτο το προγραμμα χρειαζεται την δικαιοσυνη την καταγραφη του κεφαλαιου κειμενου';

  @override
  String get grant_permission => 'Ταλαντα την δικαιοσυνη';

  @override
  String get language_afrikaans => 'αφρικάανς';

  @override
  String get language_albanian => 'αλβανικά';

  @override
  String get language_arabic => 'αραβικά';

  @override
  String get language_belarusian => 'λευκορωσικά';

  @override
  String get language_bengali => 'μπενγκάλι';

  @override
  String get language_bulgarian => 'βουλγαρικά';

  @override
  String get language_catalan => 'καταλανικά';

  @override
  String get language_chinese => 'κινεζικά';

  @override
  String get language_croatian => 'κροατικά';

  @override
  String get language_czech => 'τσεχικά';

  @override
  String get language_danish => 'δανικά';

  @override
  String get language_dutch => 'ολλανδικά';

  @override
  String get language_english => 'αγγλικά';

  @override
  String get language_esperanto => 'εσπεράντο';

  @override
  String get language_estonian => 'εσθονικά';

  @override
  String get language_finnish => 'φινλανδικά';

  @override
  String get language_french => 'γαλλικά';

  @override
  String get language_galician => 'γαλικιακά';

  @override
  String get language_georgian => 'γεωργιανά';

  @override
  String get language_german => 'γερμανικά';

  @override
  String get language_greek => 'ελληνικά';

  @override
  String get language_gujarati => 'γκουτζαράτι';

  @override
  String get language_haitian => 'αϊτιανά';

  @override
  String get language_hebrew => 'εβραϊκά';

  @override
  String get language_hindi => 'χίντι';

  @override
  String get language_hungarian => 'ουγγρικά';

  @override
  String get language_icelandic => 'ισλανδικά';

  @override
  String get language_indonesian => 'ινδονησιακά';

  @override
  String get language_irish => 'ιρλανδικά';

  @override
  String get language_italian => 'ιταλικά';

  @override
  String get language_japanese => 'ιαπωνικά';

  @override
  String get language_kannada => 'κανάντα';

  @override
  String get language_korean => 'κορεατικά';

  @override
  String get language_latvian => 'λετονικά';

  @override
  String get language_lithuanian => 'λιθουανικά';

  @override
  String get language_macedonian => 'μακεδονικά';

  @override
  String get language_malay => 'μαλαισιανά';

  @override
  String get language_maltese => 'μαλτέζικα';

  @override
  String get language_marathi => 'μαράθι';

  @override
  String get language_norwegian => 'νορβηγικά';

  @override
  String get language_persian => 'περσικά';

  @override
  String get language_polish => 'πολωνικά';

  @override
  String get language_portuguese => 'πορτογαλικά';

  @override
  String get language_romanian => 'ρουμανικά';

  @override
  String get language_russian => 'ρωσικά';

  @override
  String get language_slovak => 'σλοβακικά';

  @override
  String get language_slovenian => 'σλοβενικά';

  @override
  String get language_spanish => 'ισπανικά';

  @override
  String get language_swahili => 'σουαχίλι';

  @override
  String get language_swedish => 'σουηδικά';

  @override
  String get language_tagalog => 'ταγκαλόγκ';

  @override
  String get language_tamil => 'ταμίλ';

  @override
  String get language_telugu => 'τελούγκου';

  @override
  String get language_thai => 'ταϊλανδικά';

  @override
  String get language_turkish => 'τουρκικά';

  @override
  String get language_ukrainian => 'ουκρανικά';

  @override
  String get language_urdu => 'ούρντου';

  @override
  String get language_vietnamese => 'βιετναμικά';

  @override
  String get language_welsh => 'ουαλικά';

  @override
  String get enjoying_app => 'Σας αρέσει το Screen Translate;';

  @override
  String get review_prompt_message =>
      'Θα θέλαμε να ακούσουμε τη γνώμη σας! Θα θέλατε να αξιολογήσετε την εφαρμογή στο Google Play;';

  @override
  String get rate_now => 'Αξιολόγηση τώρα';

  @override
  String get not_now => 'Όχι τώρα';

  @override
  String get cannot_open_store =>
      'Δεν ήταν δυνατό το άνοιγμα του Google Play Store';

  @override
  String get api_key_required => 'Απαιτείται Κλειδί API';

  @override
  String get api_key_setup_prompt =>
      'Ρυθμίστε το κλειδί API του ChatGLM για μετάφραση με AI.';

  @override
  String get go_to_settings => 'Μετάβαση στις Ρυθμίσεις';

  @override
  String get api_key_dialog_title => 'Διαμόρφωση API Μετάφρασης AI';

  @override
  String get api_key_configuration_title => 'Μετάφραση ChatGLM με AI';

  @override
  String get api_key_get_key_from =>
      'Για να χρησιμοποιήσετε μεταφράσεις ChatGLM, πρέπει να αποκτήσετε ένα δωρεάν κλειδί API από ';

  @override
  String get api_key_configuration_steps => 'Βήματα Διαμόρφωσης Κλειδιού API';

  @override
  String get api_key_step_1 =>
      '1. Επισκεφθείτε το open.bigmodel.cn και δημιουργήστε ένα λογαριασμό';

  @override
  String get api_key_step_2 => '2. Μεταβείτε στην ενότητα Διαχείρισης API';

  @override
  String get api_key_step_3 =>
      '3. Δημιουργήστε ένα νέο κλειδί API για την εφαρμογή σας';

  @override
  String get api_key_input_label => 'Κλειδί API ChatGLM';

  @override
  String get api_key_input_hint => 'Εισάγετε το κλειδί API του ChatGLM';

  @override
  String get api_key_input_error => 'Παρακαλώ εισάγετε ένα έγκυρο κλειδί API';

  @override
  String get api_key_save_button => 'Αποθήκευση Κλειδιού API';

  @override
  String get api_key_note =>
      'Το κλειδί API σας θα αποθηκευτεί με ασφάλεια και θα χρησιμοποιηθεί μόνο για υπηρεσίες μετάφρασης.';

  @override
  String get api_key_save_error =>
      'Μη έγκυρο Κλειδί API. Ελέγξτε και προσπαθήστε ξανά.';

  @override
  String get api_key_save_success => 'Το Κλειδί API Αποθηκεύτηκε Επιτυχώς';

  @override
  String get translation_mode_on_device => 'Μετάφραση στη Συσκευή';

  @override
  String get translation_mode_on_device_description =>
      'Χρησιμοποιεί ενσωματωμένα μοντέλα μετάφρασης στη συσκευή σας. Γρήγορο και λειτουργεί χωρίς σύνδεση, αλλά μπορεί να έχει περιορισμένη υποστήριξη γλωσσών και ακρίβεια.';

  @override
  String get translation_mode_ai => 'Μετάφραση με ΤΝ';

  @override
  String get translation_mode_ai_description =>
      'Χρησιμοποιεί προηγμένα μοντέλα τεχνητής νοημοσύνης για πιο ακριβείς και συναφείς μεταφράσεις. Απαιτεί σύνδεση στο διαδίκτυο και κλειδί API.';

  @override
  String get translation_mode_title => 'Λειτουργία Μετάφρασης';

  @override
  String get translation_mode_on_device_label => 'Στη Συσκευή';

  @override
  String get translation_mode_ai_label => 'ΤΝ';

  @override
  String get close => 'Κλείσιμο';
}
