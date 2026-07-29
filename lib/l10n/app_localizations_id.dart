// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get app_title => 'Terjemahan layar';

  @override
  String get source_language => 'Dari';

  @override
  String get target_language => 'Ke';

  @override
  String get stop_translation => 'Hentikan terjemahan';

  @override
  String get translate_screen => 'Terjemahkan layar';

  @override
  String get source_and_target_cannot_be_the_same =>
      'Bahasa sumber dan target tidak boleh sama';

  @override
  String get manage_translation_models => 'Kelola model terjemahan';

  @override
  String model_download_success(Object language) {
    return 'Model untuk $language berhasil diunduh';
  }

  @override
  String model_download_error(Object language) {
    return 'Terjadi kesalahan saat mengunduh model untuk $language';
  }

  @override
  String get model_not_downloaded => 'Model belum diunduh';

  @override
  String get download_model => 'Unduh';

  @override
  String get remove_translation_model => 'Hapus model terjemahan';

  @override
  String remove_translation_model_confirmation(Object language) {
    return 'Apakah Anda yakin ingin menghapus model terjemahan untuk $language?';
  }

  @override
  String get cancel => 'Batal';

  @override
  String get remove => 'Hapus';

  @override
  String get not_installed => 'Tidak terinstall';

  @override
  String get downloading => 'Mengunduh';

  @override
  String get installed => 'Terinstall';

  @override
  String get download_failed => 'Gagal mengunduh';

  @override
  String failed_to_remove_model(Object language) {
    return 'Gagal menghapus model terjemahan untuk $language';
  }

  @override
  String failed_to_download_model(Object language) {
    return 'Gagal mengunduh model terjemahan untuk $language';
  }

  @override
  String get auto_translate_mode => 'Automatisasi Terjemahan';

  @override
  String get manual_translate_mode => 'Terjemahan Manual';

  @override
  String get original_text_mode => 'Mode Text Asli';

  @override
  String get overlay_permission_required => 'Mode Terjemahan';

  @override
  String get overlay_permission_required_content =>
      'Program ini meminta izin untuk terjemahan di layar.';

  @override
  String get grant_permission => 'Berikan izin';

  @override
  String get language_afrikaans => 'Bahasa Afrikaans';

  @override
  String get language_albanian => 'Bahasa Albania';

  @override
  String get language_arabic => 'Bahasa Arab';

  @override
  String get language_belarusian => 'Bahasa Belarus';

  @override
  String get language_bengali => 'Bahasa Bengali';

  @override
  String get language_bulgarian => 'Bahasa Bulgaria';

  @override
  String get language_catalan => 'Bahasa Katalan';

  @override
  String get language_chinese => 'Bahasa Mandarin';

  @override
  String get language_croatian => 'Bahasa Kroasia';

  @override
  String get language_czech => 'Bahasa Ceko';

  @override
  String get language_danish => 'Bahasa Denmark';

  @override
  String get language_dutch => 'Bahasa Belanda';

  @override
  String get language_english => 'Bahasa Inggris';

  @override
  String get language_esperanto => 'Bahasa Esperanto';

  @override
  String get language_estonian => 'Bahasa Estonia';

  @override
  String get language_finnish => 'Bahasa Finlandia';

  @override
  String get language_french => 'Bahasa Prancis';

  @override
  String get language_galician => 'Bahasa Galisia';

  @override
  String get language_georgian => 'Bahasa Georgia';

  @override
  String get language_german => 'Bahasa Jerman';

  @override
  String get language_greek => 'Bahasa Yunani';

  @override
  String get language_gujarati => 'Bahasa Gujarati';

  @override
  String get language_haitian => 'Bahasa Haiti';

  @override
  String get language_hebrew => 'Bahasa Ibrani';

  @override
  String get language_hindi => 'Bahasa Hindi';

  @override
  String get language_hungarian => 'Bahasa Hungaria';

  @override
  String get language_icelandic => 'Bahasa Islandia';

  @override
  String get language_indonesian => 'Bahasa Indonesia';

  @override
  String get language_irish => 'Bahasa Irlandia';

  @override
  String get language_italian => 'Bahasa Italia';

  @override
  String get language_japanese => 'Bahasa Jepang';

  @override
  String get language_kannada => 'Bahasa Kannada';

  @override
  String get language_korean => 'Bahasa Korea';

  @override
  String get language_latvian => 'Bahasa Latvia';

  @override
  String get language_lithuanian => 'Bahasa Lituania';

  @override
  String get language_macedonian => 'Bahasa Makedonia';

  @override
  String get language_malay => 'Bahasa Melayu';

  @override
  String get language_maltese => 'Bahasa Malta';

  @override
  String get language_marathi => 'Bahasa Marathi';

  @override
  String get language_norwegian => 'Bahasa Norwegia';

  @override
  String get language_persian => 'Bahasa Persia';

  @override
  String get language_polish => 'Bahasa Polandia';

  @override
  String get language_portuguese => 'Bahasa Portugis';

  @override
  String get language_romanian => 'Bahasa Rumania';

  @override
  String get language_russian => 'Bahasa Rusia';

  @override
  String get language_slovak => 'Bahasa Slovakia';

  @override
  String get language_slovenian => 'Bahasa Slovenia';

  @override
  String get language_spanish => 'Bahasa Spanyol';

  @override
  String get language_swahili => 'Bahasa Swahili';

  @override
  String get language_swedish => 'Bahasa Swedia';

  @override
  String get language_tagalog => 'Bahasa Tagalog';

  @override
  String get language_tamil => 'Bahasa Tamil';

  @override
  String get language_telugu => 'Bahasa Telugu';

  @override
  String get language_thai => 'Bahasa Thai';

  @override
  String get language_turkish => 'Bahasa Turki';

  @override
  String get language_ukrainian => 'Bahasa Ukraina';

  @override
  String get language_urdu => 'Bahasa Urdu';

  @override
  String get language_vietnamese => 'Bahasa Vietnam';

  @override
  String get language_welsh => 'Bahasa Wales';

  @override
  String get enjoying_app => 'Menyukai Screen Translate?';

  @override
  String get review_prompt_message =>
      'Kami ingin mendengar pendapat Anda! Apakah Anda ingin menilai aplikasi di Google Play?';

  @override
  String get rate_now => 'Nilai Sekarang';

  @override
  String get not_now => 'Tidak Sekarang';

  @override
  String get cannot_open_store => 'Tidak dapat membuka Google Play Store';

  @override
  String get api_key_required => 'Kunci API Diperlukan';

  @override
  String get api_key_setup_prompt =>
      'Atur kunci API ChatGLM Anda untuk terjemahan AI.';

  @override
  String get go_to_settings => 'Pergi ke Pengaturan';

  @override
  String get api_key_dialog_title => 'Konfigurasi API Terjemahan AI';

  @override
  String get api_key_configuration_title => 'Terjemahan ChatGLM dengan AI';

  @override
  String get api_key_get_key_from =>
      'Untuk menggunakan terjemahan ChatGLM, Anda perlu mendapatkan kunci API gratis dari ';

  @override
  String get api_key_configuration_steps => 'Langkah Konfigurasi Kunci API';

  @override
  String get api_key_step_1 => '1. Kunjungi open.bigmodel.cn dan buat akun';

  @override
  String get api_key_step_2 => '2. Navigasi ke bagian Manajemen API';

  @override
  String get api_key_step_3 => '3. Hasilkan kunci API baru untuk aplikasi Anda';

  @override
  String get api_key_input_label => 'Kunci API ChatGLM';

  @override
  String get api_key_input_hint => 'Masukkan kunci API ChatGLM Anda';

  @override
  String get api_key_input_error => 'Silakan masukkan kunci API yang valid';

  @override
  String get api_key_save_button => 'Simpan Kunci API';

  @override
  String get api_key_note =>
      'Kunci API Anda akan disimpan dengan aman dan hanya digunakan untuk layanan terjemahan.';

  @override
  String get api_key_save_error =>
      'Kunci API tidak valid. Periksa dan coba lagi.';

  @override
  String get api_key_save_success => 'Kunci API Berhasil Disimpan';

  @override
  String get translation_mode_on_device => 'Terjemahan di Perangkat';

  @override
  String get translation_mode_on_device_description =>
      'Menggunakan model terjemahan bawaan di perangkat Anda. Cepat dan bekerja offline, tetapi mungkin memiliki dukungan bahasa dan akurasi yang terbatas.';

  @override
  String get translation_mode_ai => 'Terjemahan AI';

  @override
  String get translation_mode_ai_description =>
      'Menggunakan model AI canggih untuk terjemahan yang lebih akurat dan kontekstual. Memerlukan koneksi internet dan kunci API.';

  @override
  String get translation_mode_title => 'Mode Terjemahan';

  @override
  String get translation_mode_on_device_label => 'Di Perangkat';

  @override
  String get translation_mode_ai_label => 'AI';

  @override
  String get close => 'Tutup';

  @override
  String get translation_settings_title => 'Pengaturan Terjemahan';

  @override
  String get translation_quality_section => 'KUALITAS TERJEMAHAN';

  @override
  String get mode_quick_title => 'Cepat';

  @override
  String get mode_quick_subtitle =>
      'Instan · Selalu tersedia · Tidak perlu pengaturan';

  @override
  String get mode_ai_enhanced_title => 'Ditingkatkan AI';

  @override
  String get mode_ai_enhanced_subtitle =>
      'Kualitas lebih baik · Berfungsi offline · Unduh paket bahasa';

  @override
  String get mode_cloud_ai_title => 'AI Cloud';

  @override
  String get mode_cloud_ai_subtitle =>
      'Kualitas terbaik · Membutuhkan internet · Perlu kunci API';

  @override
  String language_packs_header(String size) {
    return 'Paket Bahasa  ·  ~$size masing-masing';
  }

  @override
  String pack_downloading_progress(String percent) {
    return 'Mengunduh… $percent%';
  }

  @override
  String get pack_ready_to_use => 'Siap digunakan';

  @override
  String get pack_failed_tap_retry => 'Gagal — ketuk untuk mencoba lagi';

  @override
  String get pack_ready_badge => 'Siap';

  @override
  String get retry => 'Coba lagi';

  @override
  String pack_is_ready_snackbar(String name) {
    return '$name sudah siap!';
  }

  @override
  String get download_failed_connection =>
      'Unduhan gagal. Periksa koneksi Anda.';

  @override
  String get remove_language_pack_title => 'Hapus paket bahasa?';

  @override
  String remove_ai_pack_confirm(String name) {
    return 'Hapus paket AI offline untuk $name?';
  }

  @override
  String remove_quick_pack_confirm(String name) {
    return 'Hapus paket terjemahan cepat offline untuk $name?';
  }

  @override
  String get failed_to_remove_pack => 'Gagal menghapus paket bahasa.';

  @override
  String get connect_ai_account_title => 'Hubungkan akun AI Anda';

  @override
  String get connect_ai_account_prefix => 'Dapatkan kunci API gratis dari ';

  @override
  String get connect_ai_account_suffix => ' dan tempel di bawah ini.';

  @override
  String get api_key_hint_short => 'Tempel kunci API Anda di sini';

  @override
  String get save_and_verify => 'Simpan & Verifikasi';

  @override
  String get cloud_ai_connected => 'Terhubung! AI Cloud siap.';

  @override
  String get advanced_section_label => 'Lanjutan';

  @override
  String get text_merge_sensitivity_title => 'Sensitivitas penggabungan teks';

  @override
  String get text_merge_sensitivity_description =>
      'Mengontrol cara blok teks yang berdekatan dikelompokkan. Kurangi jika akurasi terjemahan menurun.';

  @override
  String get merge_precise => 'Presisi';

  @override
  String get merge_aggressive => 'Agresif';

  @override
  String get select_language_pair_hint => 'Pilih pasangan bahasa';

  @override
  String get download_ai_model_title => 'Unduh model AI lokal?';

  @override
  String get download_ai_model_description =>
      'Paket ini biasanya berukuran 100–500 MB. File diunduh di latar belakang; pasangan ini akan siap digunakan setelah selesai.';

  @override
  String error_prefix(String error) {
    return 'Kesalahan: $error';
  }

  @override
  String get translate_image_button => 'Terjemahkan Gambar';

  @override
  String get choose_translation_text =>
      'Pilih cara Anda ingin menerjemahkan teks';

  @override
  String get download_language_pack_title => 'Unduh Paket Bahasa';

  @override
  String get download_language_pack_content =>
      'Untuk menggunakan mode Ditingkatkan AI, unduh paket bahasa terlebih dahulu.\n\nBuka Pengaturan untuk mengunduhnya.';

  @override
  String get cloud_ai_api_key_required_content =>
      'AI Cloud memerlukan kunci API. Siapkan di Pengaturan.';

  @override
  String get mode_ai_short_label => 'AI';

  @override
  String get mode_cloud_short_label => 'Cloud';

  @override
  String get image_translation_title => 'Terjemahan Gambar';

  @override
  String get send_feedback => 'Kirim Masukan';

  @override
  String get send_feedback_subtitle => 'Laporkan bug atau sarankan fitur';

  @override
  String get ai_pair_unsupported_title => 'Bahasa Belum Didukung';

  @override
  String get ai_pair_unsupported_content =>
      'Mode AI belum memiliki model untuk pasangan bahasa ini. Beri tahu kami jika Anda menginginkannya — ini membantu kami memutuskan apa yang akan dikembangkan selanjutnya.';

  @override
  String get request_language_pair => 'Minta Bahasa Ini';

  @override
  String get language_request_sent =>
      'Terima kasih! Permintaan Anda telah kami catat.';
}
