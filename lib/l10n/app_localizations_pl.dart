// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get app_title => 'Tłumaczenie ekranu';

  @override
  String get source_language => 'Z';

  @override
  String get target_language => 'Na';

  @override
  String get stop_translation => 'Zatrzymaj tłumaczenie';

  @override
  String get translate_screen => 'Przetłumacz ekran';

  @override
  String get source_and_target_cannot_be_the_same =>
      'Język źródłowy i docelowy nie mogą być takie same';

  @override
  String get manage_translation_models => 'Zarządzaj modelami tłumaczenia';

  @override
  String model_download_success(Object language) {
    return 'Pomyślnie pobrano model dla języka $language';
  }

  @override
  String model_download_error(Object language) {
    return 'Błąd podczas pobierania modelu dla języka $language';
  }

  @override
  String get model_not_downloaded => 'Model nie został pobrany';

  @override
  String get download_model => 'Pobierz';

  @override
  String get remove_translation_model => 'Odejmij model tłumaczenia';

  @override
  String remove_translation_model_confirmation(Object language) {
    return 'Czy na pewno chcesz usunąć model tłumaczenia dla języka $language?';
  }

  @override
  String get cancel => 'Anuluj';

  @override
  String get remove => 'Odejmij';

  @override
  String get not_installed => 'Nie zainstalowano';

  @override
  String get downloading => 'Pobieranie...';

  @override
  String get installed => 'Zainstalowano';

  @override
  String get download_failed => 'Pobieranie nie powiodło się';

  @override
  String failed_to_remove_model(Object language) {
    return 'Usuwanie modelu nie powiodło się dla języka $language';
  }

  @override
  String failed_to_download_model(Object language) {
    return 'Pobieranie modelu nie powiodło się dla języka $language';
  }

  @override
  String get auto_translate_mode => 'Automatyczne tłumaczenie';

  @override
  String get manual_translate_mode => 'Tłumaczenie rejestrowane';

  @override
  String get original_text_mode => 'Tryb tekstu oryginalnego';

  @override
  String get overlay_permission_required => 'Tryb tłumaczenia';

  @override
  String get overlay_permission_required_content =>
      'Program wymaga uprawnienia do tłumaczenia na ekranie.';

  @override
  String get grant_permission => 'Pozwolenie';

  @override
  String get language_afrikaans => 'Afrikaans';

  @override
  String get language_albanian => 'Albański';

  @override
  String get language_arabic => 'Arabski';

  @override
  String get language_belarusian => 'Białoruski';

  @override
  String get language_bengali => 'Bengalski';

  @override
  String get language_bulgarian => 'Bułgarski';

  @override
  String get language_catalan => 'Kataloński';

  @override
  String get language_chinese => 'Chiński';

  @override
  String get language_croatian => 'Chorwacki';

  @override
  String get language_czech => 'Czeski';

  @override
  String get language_danish => 'Duński';

  @override
  String get language_dutch => 'Holenderski';

  @override
  String get language_english => 'Angielski';

  @override
  String get language_esperanto => 'Esperanto';

  @override
  String get language_estonian => 'Estoński';

  @override
  String get language_finnish => 'Fiński';

  @override
  String get language_french => 'Francuski';

  @override
  String get language_galician => 'Galicyjski';

  @override
  String get language_georgian => 'Gruziński';

  @override
  String get language_german => 'Niemiecki';

  @override
  String get language_greek => 'Grecki';

  @override
  String get language_gujarati => 'Gudźarati';

  @override
  String get language_haitian => 'Haitański';

  @override
  String get language_hebrew => 'Hebrajski';

  @override
  String get language_hindi => 'Hindi';

  @override
  String get language_hungarian => 'Węgierski';

  @override
  String get language_icelandic => 'Islandzki';

  @override
  String get language_indonesian => 'Indonezyjski';

  @override
  String get language_irish => 'Irlandzki';

  @override
  String get language_italian => 'Włoski';

  @override
  String get language_japanese => 'Japoński';

  @override
  String get language_kannada => 'Kannada';

  @override
  String get language_korean => 'Koreański';

  @override
  String get language_latvian => 'Łotewski';

  @override
  String get language_lithuanian => 'Litewski';

  @override
  String get language_macedonian => 'Macedoński';

  @override
  String get language_malay => 'Malajski';

  @override
  String get language_maltese => 'Maltański';

  @override
  String get language_marathi => 'Marathi';

  @override
  String get language_norwegian => 'Norweski';

  @override
  String get language_persian => 'Perski';

  @override
  String get language_polish => 'Polski';

  @override
  String get language_portuguese => 'Portugalski';

  @override
  String get language_romanian => 'Rumuński';

  @override
  String get language_russian => 'Rosyjski';

  @override
  String get language_slovak => 'Słowacki';

  @override
  String get language_slovenian => 'Słoweński';

  @override
  String get language_spanish => 'Hiszpański';

  @override
  String get language_swahili => 'Suahili';

  @override
  String get language_swedish => 'Szwedzki';

  @override
  String get language_tagalog => 'Tagalski';

  @override
  String get language_tamil => 'Tamilski';

  @override
  String get language_telugu => 'Telugu';

  @override
  String get language_thai => 'Tajski';

  @override
  String get language_turkish => 'Turecki';

  @override
  String get language_ukrainian => 'Ukraiński';

  @override
  String get language_urdu => 'Urdu';

  @override
  String get language_vietnamese => 'Wietnamski';

  @override
  String get language_welsh => 'Walijski';

  @override
  String get enjoying_app => 'Podoba Ci się Screen Translate?';

  @override
  String get review_prompt_message =>
      'Chętnie usłyszymy Twoją opinię! Czy chciałbyś ocenić aplikację w Google Play?';

  @override
  String get rate_now => 'Oceń teraz';

  @override
  String get not_now => 'Nie teraz';

  @override
  String get cannot_open_store => 'Nie można otworzyć Google Play Store';

  @override
  String get api_key_required => 'Wymagany klucz API';

  @override
  String get api_key_setup_prompt =>
      'Proszę skonfigurować klucz API ChatGLM do korzystania z tłumaczenia AI.';

  @override
  String get go_to_settings => 'Przejdź do Ustawień';

  @override
  String get api_key_dialog_title => 'Konfiguracja API Tłumaczenia AI';

  @override
  String get api_key_configuration_title => 'Tłumaczenie ChatGLM z AI';

  @override
  String get api_key_get_key_from =>
      'Aby korzystać z tłumaczeń ChatGLM, musisz uzyskać darmowy klucz API z ';

  @override
  String get api_key_configuration_steps => 'Kroki konfiguracji klucza API';

  @override
  String get api_key_step_1 => '1. Odwiedź open.bigmodel.cn i utwórz konto';

  @override
  String get api_key_step_2 => '2. Przejdź do sekcji Zarządzania API';

  @override
  String get api_key_step_3 =>
      '3. Wygeneruj nowy klucz API dla swojej aplikacji';

  @override
  String get api_key_input_label => 'Klucz API ChatGLM';

  @override
  String get api_key_input_hint => 'Wprowadź swój klucz API ChatGLM';

  @override
  String get api_key_input_error => 'Proszę wprowadzić prawidłowy klucz API';

  @override
  String get api_key_save_button => 'Zapisz klucz API';

  @override
  String get api_key_note =>
      'Twój klucz API zostanie bezpiecznie przechowany i użyty tylko dla usług tłumaczeniowych.';

  @override
  String get api_key_save_error =>
      'Nieprawidłowy klucz API. Sprawdź i spróbuj ponownie.';

  @override
  String get api_key_save_success => 'Klucz API został pomyślnie zapisany';

  @override
  String get translation_mode_on_device => 'Tłumaczenie na Urządzeniu';

  @override
  String get translation_mode_on_device_description =>
      'Używa wbudowanych modeli tłumaczenia na Twoim urządzeniu. Szybkie i działa offline, ale może mieć ograniczoną obsługę języków i dokładność.';

  @override
  String get translation_mode_ai => 'Tłumaczenie AI';

  @override
  String get translation_mode_ai_description =>
      'Używa zaawansowanych modeli AI do bardziej precyzyjnych i kontekstowych tłumaczeń. Wymaga połączenia internetowego i klucza API.';

  @override
  String get translation_mode_title => 'Tryb Tłumaczenia';

  @override
  String get translation_mode_on_device_label => 'Na Urządzeniu';

  @override
  String get translation_mode_ai_label => 'AI';

  @override
  String get close => 'Zamknij';
}
