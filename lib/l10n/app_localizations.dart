import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_bg.dart';
import 'app_localizations_bn.dart';
import 'app_localizations_cs.dart';
import 'app_localizations_da.dart';
import 'app_localizations_de.dart';
import 'app_localizations_el.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_et.dart';
import 'app_localizations_fa.dart';
import 'app_localizations_fi.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_he.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_hr.dart';
import 'app_localizations_hu.dart';
import 'app_localizations_id.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_lt.dart';
import 'app_localizations_nl.dart';
import 'app_localizations_no.dart';
import 'app_localizations_pl.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ro.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_sk.dart';
import 'app_localizations_sl.dart';
import 'app_localizations_sv.dart';
import 'app_localizations_th.dart';
import 'app_localizations_tr.dart';
import 'app_localizations_vi.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('bg'),
    Locale('bn'),
    Locale('cs'),
    Locale('da'),
    Locale('de'),
    Locale('el'),
    Locale('en'),
    Locale('es'),
    Locale('et'),
    Locale('fa'),
    Locale('fi'),
    Locale('fr'),
    Locale('he'),
    Locale('hi'),
    Locale('hr'),
    Locale('hu'),
    Locale('id'),
    Locale('it'),
    Locale('ja'),
    Locale('ko'),
    Locale('lt'),
    Locale('nl'),
    Locale('no'),
    Locale('pl'),
    Locale('pt'),
    Locale('ro'),
    Locale('ru'),
    Locale('sk'),
    Locale('sl'),
    Locale('sv'),
    Locale('th'),
    Locale('tr'),
    Locale('vi'),
    Locale('zh')
  ];

  /// No description provided for @app_title.
  ///
  /// In en, this message translates to:
  /// **'Screen Translate'**
  String get app_title;

  /// No description provided for @source_language.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get source_language;

  /// No description provided for @target_language.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get target_language;

  /// No description provided for @stop_translation.
  ///
  /// In en, this message translates to:
  /// **'Stop Translation'**
  String get stop_translation;

  /// No description provided for @translate_screen.
  ///
  /// In en, this message translates to:
  /// **'Translate Screen'**
  String get translate_screen;

  /// No description provided for @source_and_target_cannot_be_the_same.
  ///
  /// In en, this message translates to:
  /// **'Source and target languages cannot be the same'**
  String get source_and_target_cannot_be_the_same;

  /// No description provided for @manage_translation_models.
  ///
  /// In en, this message translates to:
  /// **'Manage Translation Models'**
  String get manage_translation_models;

  /// No description provided for @model_download_success.
  ///
  /// In en, this message translates to:
  /// **'{language} model downloaded successfully'**
  String model_download_success(Object language);

  /// No description provided for @model_download_error.
  ///
  /// In en, this message translates to:
  /// **'Failed to download {language} model'**
  String model_download_error(Object language);

  /// No description provided for @model_not_downloaded.
  ///
  /// In en, this message translates to:
  /// **'Model not downloaded'**
  String get model_not_downloaded;

  /// No description provided for @download_model.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download_model;

  /// No description provided for @remove_translation_model.
  ///
  /// In en, this message translates to:
  /// **'Remove Translation Model'**
  String get remove_translation_model;

  /// No description provided for @remove_translation_model_confirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove the {language} translation model?'**
  String remove_translation_model_confirmation(Object language);

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @not_installed.
  ///
  /// In en, this message translates to:
  /// **'Not Installed'**
  String get not_installed;

  /// No description provided for @downloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading...'**
  String get downloading;

  /// No description provided for @installed.
  ///
  /// In en, this message translates to:
  /// **'Installed'**
  String get installed;

  /// No description provided for @download_failed.
  ///
  /// In en, this message translates to:
  /// **'Download Failed'**
  String get download_failed;

  /// No description provided for @failed_to_remove_model.
  ///
  /// In en, this message translates to:
  /// **'Failed to remove {language} model'**
  String failed_to_remove_model(Object language);

  /// No description provided for @failed_to_download_model.
  ///
  /// In en, this message translates to:
  /// **'Failed to download {language} model'**
  String failed_to_download_model(Object language);

  /// No description provided for @auto_translate_mode.
  ///
  /// In en, this message translates to:
  /// **'Auto Translate Mode'**
  String get auto_translate_mode;

  /// No description provided for @manual_translate_mode.
  ///
  /// In en, this message translates to:
  /// **'Manual Translate Mode'**
  String get manual_translate_mode;

  /// No description provided for @original_text_mode.
  ///
  /// In en, this message translates to:
  /// **'Original Text Mode'**
  String get original_text_mode;

  /// No description provided for @overlay_permission_required.
  ///
  /// In en, this message translates to:
  /// **'Overlay Permission Required'**
  String get overlay_permission_required;

  /// No description provided for @overlay_permission_required_content.
  ///
  /// In en, this message translates to:
  /// **'This app needs permission to draw over other apps.'**
  String get overlay_permission_required_content;

  /// No description provided for @grant_permission.
  ///
  /// In en, this message translates to:
  /// **'Grant Permission'**
  String get grant_permission;

  /// No description provided for @language_afrikaans.
  ///
  /// In en, this message translates to:
  /// **'Afrikaans'**
  String get language_afrikaans;

  /// No description provided for @language_albanian.
  ///
  /// In en, this message translates to:
  /// **'Albanian'**
  String get language_albanian;

  /// No description provided for @language_arabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get language_arabic;

  /// No description provided for @language_belarusian.
  ///
  /// In en, this message translates to:
  /// **'Belarusian'**
  String get language_belarusian;

  /// No description provided for @language_bengali.
  ///
  /// In en, this message translates to:
  /// **'Bengali'**
  String get language_bengali;

  /// No description provided for @language_bulgarian.
  ///
  /// In en, this message translates to:
  /// **'Bulgarian'**
  String get language_bulgarian;

  /// No description provided for @language_catalan.
  ///
  /// In en, this message translates to:
  /// **'Catalan'**
  String get language_catalan;

  /// No description provided for @language_chinese.
  ///
  /// In en, this message translates to:
  /// **'Chinese'**
  String get language_chinese;

  /// No description provided for @language_croatian.
  ///
  /// In en, this message translates to:
  /// **'Croatian'**
  String get language_croatian;

  /// No description provided for @language_czech.
  ///
  /// In en, this message translates to:
  /// **'Czech'**
  String get language_czech;

  /// No description provided for @language_danish.
  ///
  /// In en, this message translates to:
  /// **'Danish'**
  String get language_danish;

  /// No description provided for @language_dutch.
  ///
  /// In en, this message translates to:
  /// **'Dutch'**
  String get language_dutch;

  /// No description provided for @language_english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get language_english;

  /// No description provided for @language_esperanto.
  ///
  /// In en, this message translates to:
  /// **'Esperanto'**
  String get language_esperanto;

  /// No description provided for @language_estonian.
  ///
  /// In en, this message translates to:
  /// **'Estonian'**
  String get language_estonian;

  /// No description provided for @language_finnish.
  ///
  /// In en, this message translates to:
  /// **'Finnish'**
  String get language_finnish;

  /// No description provided for @language_french.
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get language_french;

  /// No description provided for @language_galician.
  ///
  /// In en, this message translates to:
  /// **'Galician'**
  String get language_galician;

  /// No description provided for @language_georgian.
  ///
  /// In en, this message translates to:
  /// **'Georgian'**
  String get language_georgian;

  /// No description provided for @language_german.
  ///
  /// In en, this message translates to:
  /// **'German'**
  String get language_german;

  /// No description provided for @language_greek.
  ///
  /// In en, this message translates to:
  /// **'Greek'**
  String get language_greek;

  /// No description provided for @language_gujarati.
  ///
  /// In en, this message translates to:
  /// **'Gujarati'**
  String get language_gujarati;

  /// No description provided for @language_haitian.
  ///
  /// In en, this message translates to:
  /// **'Haitian'**
  String get language_haitian;

  /// No description provided for @language_hebrew.
  ///
  /// In en, this message translates to:
  /// **'Hebrew'**
  String get language_hebrew;

  /// No description provided for @language_hindi.
  ///
  /// In en, this message translates to:
  /// **'Hindi'**
  String get language_hindi;

  /// No description provided for @language_hungarian.
  ///
  /// In en, this message translates to:
  /// **'Hungarian'**
  String get language_hungarian;

  /// No description provided for @language_icelandic.
  ///
  /// In en, this message translates to:
  /// **'Icelandic'**
  String get language_icelandic;

  /// No description provided for @language_indonesian.
  ///
  /// In en, this message translates to:
  /// **'Indonesian'**
  String get language_indonesian;

  /// No description provided for @language_irish.
  ///
  /// In en, this message translates to:
  /// **'Irish'**
  String get language_irish;

  /// No description provided for @language_italian.
  ///
  /// In en, this message translates to:
  /// **'Italian'**
  String get language_italian;

  /// No description provided for @language_japanese.
  ///
  /// In en, this message translates to:
  /// **'Japanese'**
  String get language_japanese;

  /// No description provided for @language_kannada.
  ///
  /// In en, this message translates to:
  /// **'Kannada'**
  String get language_kannada;

  /// No description provided for @language_korean.
  ///
  /// In en, this message translates to:
  /// **'Korean'**
  String get language_korean;

  /// No description provided for @language_latvian.
  ///
  /// In en, this message translates to:
  /// **'Latvian'**
  String get language_latvian;

  /// No description provided for @language_lithuanian.
  ///
  /// In en, this message translates to:
  /// **'Lithuanian'**
  String get language_lithuanian;

  /// No description provided for @language_macedonian.
  ///
  /// In en, this message translates to:
  /// **'Macedonian'**
  String get language_macedonian;

  /// No description provided for @language_malay.
  ///
  /// In en, this message translates to:
  /// **'Malay'**
  String get language_malay;

  /// No description provided for @language_maltese.
  ///
  /// In en, this message translates to:
  /// **'Maltese'**
  String get language_maltese;

  /// No description provided for @language_marathi.
  ///
  /// In en, this message translates to:
  /// **'Marathi'**
  String get language_marathi;

  /// No description provided for @language_norwegian.
  ///
  /// In en, this message translates to:
  /// **'Norwegian'**
  String get language_norwegian;

  /// No description provided for @language_persian.
  ///
  /// In en, this message translates to:
  /// **'Persian'**
  String get language_persian;

  /// No description provided for @language_polish.
  ///
  /// In en, this message translates to:
  /// **'Polish'**
  String get language_polish;

  /// No description provided for @language_portuguese.
  ///
  /// In en, this message translates to:
  /// **'Portuguese'**
  String get language_portuguese;

  /// No description provided for @language_romanian.
  ///
  /// In en, this message translates to:
  /// **'Romanian'**
  String get language_romanian;

  /// No description provided for @language_russian.
  ///
  /// In en, this message translates to:
  /// **'Russian'**
  String get language_russian;

  /// No description provided for @language_slovak.
  ///
  /// In en, this message translates to:
  /// **'Slovak'**
  String get language_slovak;

  /// No description provided for @language_slovenian.
  ///
  /// In en, this message translates to:
  /// **'Slovenian'**
  String get language_slovenian;

  /// No description provided for @language_spanish.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get language_spanish;

  /// No description provided for @language_swahili.
  ///
  /// In en, this message translates to:
  /// **'Swahili'**
  String get language_swahili;

  /// No description provided for @language_swedish.
  ///
  /// In en, this message translates to:
  /// **'Swedish'**
  String get language_swedish;

  /// No description provided for @language_tagalog.
  ///
  /// In en, this message translates to:
  /// **'Tagalog'**
  String get language_tagalog;

  /// No description provided for @language_tamil.
  ///
  /// In en, this message translates to:
  /// **'Tamil'**
  String get language_tamil;

  /// No description provided for @language_telugu.
  ///
  /// In en, this message translates to:
  /// **'Telugu'**
  String get language_telugu;

  /// No description provided for @language_thai.
  ///
  /// In en, this message translates to:
  /// **'Thai'**
  String get language_thai;

  /// No description provided for @language_turkish.
  ///
  /// In en, this message translates to:
  /// **'Turkish'**
  String get language_turkish;

  /// No description provided for @language_ukrainian.
  ///
  /// In en, this message translates to:
  /// **'Ukrainian'**
  String get language_ukrainian;

  /// No description provided for @language_urdu.
  ///
  /// In en, this message translates to:
  /// **'Urdu'**
  String get language_urdu;

  /// No description provided for @language_vietnamese.
  ///
  /// In en, this message translates to:
  /// **'Vietnamese'**
  String get language_vietnamese;

  /// No description provided for @language_welsh.
  ///
  /// In en, this message translates to:
  /// **'Welsh'**
  String get language_welsh;

  /// No description provided for @enjoying_app.
  ///
  /// In en, this message translates to:
  /// **'Enjoying Screen Translate?'**
  String get enjoying_app;

  /// No description provided for @review_prompt_message.
  ///
  /// In en, this message translates to:
  /// **'We\'d love to hear your feedback! Would you like to rate the app on Google Play?'**
  String get review_prompt_message;

  /// No description provided for @rate_now.
  ///
  /// In en, this message translates to:
  /// **'Rate Now'**
  String get rate_now;

  /// No description provided for @not_now.
  ///
  /// In en, this message translates to:
  /// **'Not Now'**
  String get not_now;

  /// No description provided for @cannot_open_store.
  ///
  /// In en, this message translates to:
  /// **'Could not open Google Play Store'**
  String get cannot_open_store;

  /// No description provided for @api_key_required.
  ///
  /// In en, this message translates to:
  /// **'API Key Required'**
  String get api_key_required;

  /// No description provided for @api_key_setup_prompt.
  ///
  /// In en, this message translates to:
  /// **'Please set up your ChatGLM API key to use AI translation.'**
  String get api_key_setup_prompt;

  /// No description provided for @go_to_settings.
  ///
  /// In en, this message translates to:
  /// **'Go to Settings'**
  String get go_to_settings;

  /// No description provided for @api_key_dialog_title.
  ///
  /// In en, this message translates to:
  /// **'AI Translation API Configuration'**
  String get api_key_dialog_title;

  /// No description provided for @api_key_configuration_title.
  ///
  /// In en, this message translates to:
  /// **'ChatGLM AI Translation'**
  String get api_key_configuration_title;

  /// No description provided for @api_key_get_key_from.
  ///
  /// In en, this message translates to:
  /// **'To use ChatGLM for translations, you need to obtain an free API key from '**
  String get api_key_get_key_from;

  /// No description provided for @api_key_configuration_steps.
  ///
  /// In en, this message translates to:
  /// **'API Key Configuration Steps'**
  String get api_key_configuration_steps;

  /// No description provided for @api_key_step_1.
  ///
  /// In en, this message translates to:
  /// **'1. Visit open.bigmodel.cn and create an account'**
  String get api_key_step_1;

  /// No description provided for @api_key_step_2.
  ///
  /// In en, this message translates to:
  /// **'2. Navigate to API Management section'**
  String get api_key_step_2;

  /// No description provided for @api_key_step_3.
  ///
  /// In en, this message translates to:
  /// **'3. Generate a new API key for your application'**
  String get api_key_step_3;

  /// No description provided for @api_key_input_label.
  ///
  /// In en, this message translates to:
  /// **'ChatGLM API Key'**
  String get api_key_input_label;

  /// No description provided for @api_key_input_hint.
  ///
  /// In en, this message translates to:
  /// **'Enter your ChatGLM API key'**
  String get api_key_input_hint;

  /// No description provided for @api_key_input_error.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid API key'**
  String get api_key_input_error;

  /// No description provided for @api_key_save_button.
  ///
  /// In en, this message translates to:
  /// **'Save API Key'**
  String get api_key_save_button;

  /// No description provided for @api_key_note.
  ///
  /// In en, this message translates to:
  /// **'Your API key will be securely stored and used only for translation services.'**
  String get api_key_note;

  /// No description provided for @api_key_save_error.
  ///
  /// In en, this message translates to:
  /// **'Invalid API Key. Please check and try again.'**
  String get api_key_save_error;

  /// No description provided for @api_key_save_success.
  ///
  /// In en, this message translates to:
  /// **'API Key Saved Successfully'**
  String get api_key_save_success;

  /// No description provided for @translation_mode_on_device.
  ///
  /// In en, this message translates to:
  /// **'On-Device Translation'**
  String get translation_mode_on_device;

  /// No description provided for @translation_mode_on_device_description.
  ///
  /// In en, this message translates to:
  /// **'Uses built-in translation models on your device. Fast and works offline, but may have limited language support and accuracy.'**
  String get translation_mode_on_device_description;

  /// No description provided for @translation_mode_ai.
  ///
  /// In en, this message translates to:
  /// **'AI-Powered Translation'**
  String get translation_mode_ai;

  /// No description provided for @translation_mode_ai_description.
  ///
  /// In en, this message translates to:
  /// **'Uses advanced AI models for more accurate and contextual translations. Requires an internet connection and API key.'**
  String get translation_mode_ai_description;

  /// No description provided for @translation_mode_title.
  ///
  /// In en, this message translates to:
  /// **'Translation Mode'**
  String get translation_mode_title;

  /// No description provided for @translation_mode_on_device_label.
  ///
  /// In en, this message translates to:
  /// **'On-Device'**
  String get translation_mode_on_device_label;

  /// No description provided for @translation_mode_ai_label.
  ///
  /// In en, this message translates to:
  /// **'AI'**
  String get translation_mode_ai_label;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
        'ar',
        'bg',
        'bn',
        'cs',
        'da',
        'de',
        'el',
        'en',
        'es',
        'et',
        'fa',
        'fi',
        'fr',
        'he',
        'hi',
        'hr',
        'hu',
        'id',
        'it',
        'ja',
        'ko',
        'lt',
        'nl',
        'no',
        'pl',
        'pt',
        'ro',
        'ru',
        'sk',
        'sl',
        'sv',
        'th',
        'tr',
        'vi',
        'zh'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'bg':
      return AppLocalizationsBg();
    case 'bn':
      return AppLocalizationsBn();
    case 'cs':
      return AppLocalizationsCs();
    case 'da':
      return AppLocalizationsDa();
    case 'de':
      return AppLocalizationsDe();
    case 'el':
      return AppLocalizationsEl();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'et':
      return AppLocalizationsEt();
    case 'fa':
      return AppLocalizationsFa();
    case 'fi':
      return AppLocalizationsFi();
    case 'fr':
      return AppLocalizationsFr();
    case 'he':
      return AppLocalizationsHe();
    case 'hi':
      return AppLocalizationsHi();
    case 'hr':
      return AppLocalizationsHr();
    case 'hu':
      return AppLocalizationsHu();
    case 'id':
      return AppLocalizationsId();
    case 'it':
      return AppLocalizationsIt();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'lt':
      return AppLocalizationsLt();
    case 'nl':
      return AppLocalizationsNl();
    case 'no':
      return AppLocalizationsNo();
    case 'pl':
      return AppLocalizationsPl();
    case 'pt':
      return AppLocalizationsPt();
    case 'ro':
      return AppLocalizationsRo();
    case 'ru':
      return AppLocalizationsRu();
    case 'sk':
      return AppLocalizationsSk();
    case 'sl':
      return AppLocalizationsSl();
    case 'sv':
      return AppLocalizationsSv();
    case 'th':
      return AppLocalizationsTh();
    case 'tr':
      return AppLocalizationsTr();
    case 'vi':
      return AppLocalizationsVi();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
