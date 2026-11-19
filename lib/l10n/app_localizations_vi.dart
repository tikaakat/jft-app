// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class L10nVi extends L10n {
  L10nVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'JFT-Basic Prep';

  @override
  String get sectionVocab => 'Chữ viết và Từ vựng';

  @override
  String get sectionConv => 'Hội thoại và Diễn đạt';

  @override
  String get sectionListen => 'Nghe hiểu';

  @override
  String get sectionRead => 'Đọc hiểu';

  @override
  String get premiumUnlocked => 'Premium: đã mở khóa tất cả câu hỏi';

  @override
  String freeLimit(int n) {
    return 'Miễn phí: $n câu mỗi phần';
  }

  @override
  String get unlockAll => 'Mở khóa tất cả câu hỏi';

  @override
  String get statMastered => 'Đã thuộc';

  @override
  String get statAnswered => 'Đã trả lời';

  @override
  String get statAccuracy => 'Độ chính xác';

  @override
  String masteredOf(int done, int total) {
    return 'Đã thuộc $done / $total';
  }

  @override
  String bestScore(int pct) {
    return 'Cao nhất: $pct%';
  }

  @override
  String get bestNone => 'Cao nhất: –';

  @override
  String accuracyValue(int pct) {
    return 'Độ chính xác: $pct%';
  }

  @override
  String draftsCount(int n) {
    return 'Bản nháp: $n';
  }

  @override
  String get reviewMistakes => 'Ôn lại câu sai';

  @override
  String get noMistakes => 'Không có câu sai để ôn.\nHãy tiếp tục luyện tập!';

  @override
  String get retry => 'Làm lại';

  @override
  String answerIs(String answer) {
    return 'Đáp án: $answer';
  }

  @override
  String get close => 'Đóng';

  @override
  String questionOf(int i, int total) {
    return 'Câu $i / $total';
  }

  @override
  String get draftBadge => 'BẢN NHÁP (chưa hiệu đính)';

  @override
  String get playAudio => 'Phát âm thanh';

  @override
  String get ttsUnavailable =>
      'Không có giọng đọc tiếng Nhật. Hãy cài đặt trong Cài đặt Android > Đầu ra chuyển văn bản thành giọng nói (Google Speech Services).';

  @override
  String get correct => 'Đúng rồi!';

  @override
  String get incorrect => 'Sai';

  @override
  String get script => 'Lời thoại';

  @override
  String get next => 'Tiếp';

  @override
  String get finish => 'Kết thúc';

  @override
  String get result => 'Kết quả';

  @override
  String scoreCorrect(int correct, int total) {
    return 'Đúng $correct / $total';
  }

  @override
  String get newBest => 'Điểm cao mới!';

  @override
  String get noMistakesLeft => 'Phần này không còn câu sai. Tuyệt vời!';

  @override
  String remainingToReview(int n) {
    return 'Còn $n câu cần ôn.';
  }

  @override
  String freeFinished(int n) {
    return 'Bạn đã làm hết câu miễn phí. Premium mở khóa toàn bộ $n câu của phần này.';
  }

  @override
  String get home => 'Trang chủ';

  @override
  String get tryAgain => 'Thử lại';

  @override
  String get seePremium => 'Xem Premium';

  @override
  String reviewTitle(String section) {
    return 'Ôn tập: $section';
  }

  @override
  String get settings => 'Cài đặt';

  @override
  String get language => 'Ngôn ngữ';

  @override
  String get systemLanguage => 'Mặc định hệ thống';

  @override
  String get premium => 'Premium';

  @override
  String get premiumActive => 'Đang hoạt động';

  @override
  String get premiumInactive => 'Chưa đăng ký';

  @override
  String get restorePurchases => 'Khôi phục giao dịch';

  @override
  String get restoreSuccess => 'Đã khôi phục Premium.';

  @override
  String get restoreNone => 'Không tìm thấy gói đăng ký đang hoạt động.';

  @override
  String get machineTranslation => 'Ngôn ngữ này có bao gồm bản dịch máy.';

  @override
  String get explanationLanguageNote =>
      'Phần giải thích sẽ hiển thị bằng tiếng Anh cho đến khi được dịch.';

  @override
  String get paywallTitle => 'JFT-Basic Prep Premium';

  @override
  String get paywallSubtitle =>
      'Câu hỏi do người Nhật bản ngữ soạn và kiểm tra';

  @override
  String get benefitAll => 'Tất cả câu hỏi của cả 4 phần';

  @override
  String get benefitNew => 'Thường xuyên bổ sung câu hỏi mới';

  @override
  String get benefitReview => 'Ôn lại câu sai không giới hạn';

  @override
  String get yearly => 'Hằng năm';

  @override
  String get monthly => 'Hằng tháng';

  @override
  String pricePerYear(String price) {
    return '$price / năm';
  }

  @override
  String pricePerMonth(String price) {
    return '$price / tháng';
  }

  @override
  String get subscribe => 'Đăng ký';

  @override
  String get cancelAnytime =>
      'Tự động gia hạn. Hủy bất cứ lúc nào trên Google Play.';

  @override
  String get billingUnavailable => 'Chưa thể mua. Vui lòng thử lại sau.';

  @override
  String get purchaseSuccess => 'Cảm ơn bạn! Premium đã được kích hoạt.';

  @override
  String get purchaseError => 'Mua không thành công. Vui lòng thử lại.';

  @override
  String get alreadyPremium => 'Bạn đã có Premium.';

  @override
  String get furigana => 'Hiện furigana';

  @override
  String get furiganaHint => 'Cách đọc hiragana phía trên chữ Hán';
}
