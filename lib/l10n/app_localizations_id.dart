// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class L10nId extends L10n {
  L10nId([String locale = 'id']) : super(locale);

  @override
  String get appTitle => 'JFT-Basic Prep';

  @override
  String get sectionVocab => 'Huruf dan Kosakata';

  @override
  String get sectionConv => 'Percakapan dan Ungkapan';

  @override
  String get sectionListen => 'Pemahaman Mendengar';

  @override
  String get sectionRead => 'Pemahaman Membaca';

  @override
  String get premiumUnlocked => 'Premium: semua soal terbuka';

  @override
  String freeLimit(int n) {
    return 'Gratis: $n soal per bagian';
  }

  @override
  String get unlockAll => 'Buka semua soal';

  @override
  String get statMastered => 'Dikuasai';

  @override
  String get statAnswered => 'Dijawab';

  @override
  String get statAccuracy => 'Akurasi';

  @override
  String masteredOf(int done, int total) {
    return 'Dikuasai $done / $total';
  }

  @override
  String bestScore(int pct) {
    return 'Terbaik: $pct%';
  }

  @override
  String get bestNone => 'Terbaik: –';

  @override
  String accuracyValue(int pct) {
    return 'Akurasi: $pct%';
  }

  @override
  String draftsCount(int n) {
    return 'Draf: $n';
  }

  @override
  String get reviewMistakes => 'Ulangi kesalahan';

  @override
  String get noMistakes =>
      'Tidak ada kesalahan untuk diulang.\nTerus berlatih!';

  @override
  String get retry => 'Coba lagi';

  @override
  String answerIs(String answer) {
    return 'Jawaban: $answer';
  }

  @override
  String get close => 'Tutup';

  @override
  String questionOf(int i, int total) {
    return 'Soal $i / $total';
  }

  @override
  String get draftBadge => 'DRAF (belum diperiksa)';

  @override
  String get playAudio => 'Putar audio';

  @override
  String get ttsUnavailable =>
      'Suara bahasa Jepang tidak tersedia. Pasang di Pengaturan Android > Output text-to-speech (Google Speech Services).';

  @override
  String get correct => 'Benar!';

  @override
  String get incorrect => 'Salah';

  @override
  String get script => 'Naskah';

  @override
  String get next => 'Berikutnya';

  @override
  String get finish => 'Selesai';

  @override
  String get result => 'Hasil';

  @override
  String scoreCorrect(int correct, int total) {
    return '$correct / $total benar';
  }

  @override
  String get newBest => 'Skor terbaik baru!';

  @override
  String get noMistakesLeft => 'Tidak ada kesalahan lagi di bagian ini. Hebat!';

  @override
  String remainingToReview(int n) {
    return 'Masih ada $n soal untuk diulang.';
  }

  @override
  String freeFinished(int n) {
    return 'Kamu sudah menyelesaikan soal gratis. Premium membuka semua $n soal di bagian ini.';
  }

  @override
  String get home => 'Beranda';

  @override
  String get tryAgain => 'Coba lagi';

  @override
  String get seePremium => 'Lihat Premium';

  @override
  String reviewTitle(String section) {
    return 'Ulangi: $section';
  }

  @override
  String get settings => 'Pengaturan';

  @override
  String get language => 'Bahasa';

  @override
  String get systemLanguage => 'Bawaan sistem';

  @override
  String get premium => 'Premium';

  @override
  String get premiumActive => 'Aktif';

  @override
  String get premiumInactive => 'Belum berlangganan';

  @override
  String get restorePurchases => 'Pulihkan pembelian';

  @override
  String get restoreSuccess => 'Premium berhasil dipulihkan.';

  @override
  String get restoreNone => 'Tidak ditemukan langganan aktif.';

  @override
  String get machineTranslation => 'Bahasa ini mengandung terjemahan mesin.';

  @override
  String get explanationLanguageNote =>
      'Penjelasan ditampilkan dalam bahasa Inggris sampai diterjemahkan.';

  @override
  String get paywallTitle => 'JFT-Basic Prep Premium';

  @override
  String get paywallSubtitle =>
      'Soal ditulis dan diperiksa oleh penutur asli bahasa Jepang';

  @override
  String get benefitAll => 'Semua soal di 4 bagian';

  @override
  String get benefitNew => 'Soal baru ditambahkan secara berkala';

  @override
  String get benefitReview => 'Ulangi kesalahan tanpa batas';

  @override
  String get yearly => 'Tahunan';

  @override
  String get monthly => 'Bulanan';

  @override
  String pricePerYear(String price) {
    return '$price / tahun';
  }

  @override
  String pricePerMonth(String price) {
    return '$price / bulan';
  }

  @override
  String get subscribe => 'Berlangganan';

  @override
  String get cancelAnytime =>
      'Diperpanjang otomatis. Batalkan kapan saja di Google Play.';

  @override
  String get billingUnavailable =>
      'Pembelian belum tersedia. Silakan coba lagi nanti.';

  @override
  String get purchaseSuccess => 'Terima kasih! Premium sudah aktif.';

  @override
  String get purchaseError => 'Pembelian gagal. Silakan coba lagi.';

  @override
  String get alreadyPremium => 'Kamu sudah memiliki Premium.';

  @override
  String get furigana => 'Tampilkan furigana';

  @override
  String get furiganaHint => 'Cara baca hiragana di atas kanji';
}
