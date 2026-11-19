// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class L10nEn extends L10n {
  L10nEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'JFT-Basic Prep';

  @override
  String get sectionVocab => 'Script and Vocabulary';

  @override
  String get sectionConv => 'Conversation and Expression';

  @override
  String get sectionListen => 'Listening Comprehension';

  @override
  String get sectionRead => 'Reading Comprehension';

  @override
  String get premiumUnlocked => 'Premium: all questions unlocked';

  @override
  String freeLimit(int n) {
    return 'Free: $n questions per section';
  }

  @override
  String get unlockAll => 'Unlock all questions';

  @override
  String get statMastered => 'Mastered';

  @override
  String get statAnswered => 'Answered';

  @override
  String get statAccuracy => 'Accuracy';

  @override
  String masteredOf(int done, int total) {
    return 'Mastered $done / $total';
  }

  @override
  String bestScore(int pct) {
    return 'Best: $pct%';
  }

  @override
  String get bestNone => 'Best: –';

  @override
  String accuracyValue(int pct) {
    return 'Accuracy: $pct%';
  }

  @override
  String draftsCount(int n) {
    return 'Drafts: $n';
  }

  @override
  String get reviewMistakes => 'Review mistakes';

  @override
  String get noMistakes => 'No mistakes to review.\nKeep practicing!';

  @override
  String get retry => 'Retry';

  @override
  String answerIs(String answer) {
    return 'Answer: $answer';
  }

  @override
  String get close => 'Close';

  @override
  String questionOf(int i, int total) {
    return 'Question $i / $total';
  }

  @override
  String get draftBadge => 'DRAFT (not yet proofread)';

  @override
  String get playAudio => 'Play audio';

  @override
  String get ttsUnavailable =>
      'Japanese voice is not available. Install it in Android Settings > Text-to-speech output (Google Speech Services).';

  @override
  String get correct => 'Correct!';

  @override
  String get incorrect => 'Incorrect';

  @override
  String get script => 'Script';

  @override
  String get next => 'Next';

  @override
  String get finish => 'Finish';

  @override
  String get result => 'Result';

  @override
  String scoreCorrect(int correct, int total) {
    return '$correct / $total correct';
  }

  @override
  String get newBest => 'New best score!';

  @override
  String get noMistakesLeft => 'No mistakes left in this section. Great job!';

  @override
  String remainingToReview(int n) {
    return '$n question(s) still to review.';
  }

  @override
  String freeFinished(int n) {
    return 'You have finished the free questions. Premium unlocks all $n questions in this section.';
  }

  @override
  String get home => 'Home';

  @override
  String get tryAgain => 'Try again';

  @override
  String get seePremium => 'See Premium';

  @override
  String reviewTitle(String section) {
    return 'Review: $section';
  }

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get systemLanguage => 'System default';

  @override
  String get premium => 'Premium';

  @override
  String get premiumActive => 'Active';

  @override
  String get premiumInactive => 'Not subscribed';

  @override
  String get restorePurchases => 'Restore purchases';

  @override
  String get restoreSuccess => 'Premium restored.';

  @override
  String get restoreNone => 'No active subscription found.';

  @override
  String get machineTranslation =>
      'This language includes machine translation.';

  @override
  String get explanationLanguageNote =>
      'Explanations are shown in English until translated.';

  @override
  String get paywallTitle => 'JFT-Basic Prep Premium';

  @override
  String get paywallSubtitle =>
      'Questions written and checked by native Japanese speakers';

  @override
  String get benefitAll => 'All questions in all 4 sections';

  @override
  String get benefitNew => 'New questions added regularly';

  @override
  String get benefitReview => 'Review your mistakes without limits';

  @override
  String get yearly => 'Yearly';

  @override
  String get monthly => 'Monthly';

  @override
  String pricePerYear(String price) {
    return '$price / year';
  }

  @override
  String pricePerMonth(String price) {
    return '$price / month';
  }

  @override
  String get subscribe => 'Subscribe';

  @override
  String get cancelAnytime => 'Auto-renews. Cancel anytime in Google Play.';

  @override
  String get billingUnavailable =>
      'Purchases are not available yet. Please try again later.';

  @override
  String get purchaseSuccess => 'Thank you! Premium is now active.';

  @override
  String get purchaseError => 'Purchase failed. Please try again.';

  @override
  String get alreadyPremium => 'You already have Premium.';

  @override
  String get furigana => 'Show furigana';

  @override
  String get furiganaHint => 'Hiragana readings above kanji';
}
