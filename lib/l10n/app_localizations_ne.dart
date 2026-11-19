// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Nepali (`ne`).
class L10nNe extends L10n {
  L10nNe([String locale = 'ne']) : super(locale);

  @override
  String get appTitle => 'JFT-Basic Prep';

  @override
  String get sectionVocab => 'लिपि र शब्दावली';

  @override
  String get sectionConv => 'कुराकानी र अभिव्यक्ति';

  @override
  String get sectionListen => 'सुनाइ बोध';

  @override
  String get sectionRead => 'पठन बोध';

  @override
  String get premiumUnlocked => 'प्रिमियम: सबै प्रश्नहरू खुला';

  @override
  String freeLimit(int n) {
    return 'निःशुल्क: प्रत्येक खण्डमा $n प्रश्न';
  }

  @override
  String get unlockAll => 'सबै प्रश्नहरू खोल्नुहोस्';

  @override
  String get statMastered => 'सिकिसकेको';

  @override
  String get statAnswered => 'उत्तर दिएको';

  @override
  String get statAccuracy => 'शुद्धता';

  @override
  String masteredOf(int done, int total) {
    return 'सिकिसकेको $done / $total';
  }

  @override
  String bestScore(int pct) {
    return 'उत्कृष्ट: $pct%';
  }

  @override
  String get bestNone => 'उत्कृष्ट: –';

  @override
  String accuracyValue(int pct) {
    return 'शुद्धता: $pct%';
  }

  @override
  String draftsCount(int n) {
    return 'मस्यौदा: $n';
  }

  @override
  String get reviewMistakes => 'गल्तीहरू दोहोर्याउनुहोस्';

  @override
  String get noMistakes =>
      'दोहोर्याउनुपर्ने गल्ती छैन।\nअभ्यास जारी राख्नुहोस्!';

  @override
  String get retry => 'फेरि प्रयास';

  @override
  String answerIs(String answer) {
    return 'उत्तर: $answer';
  }

  @override
  String get close => 'बन्द गर्नुहोस्';

  @override
  String questionOf(int i, int total) {
    return 'प्रश्न $i / $total';
  }

  @override
  String get draftBadge => 'मस्यौदा (अझै जाँच नगरिएको)';

  @override
  String get playAudio => 'अडियो बजाउनुहोस्';

  @override
  String get ttsUnavailable =>
      'जापानी आवाज उपलब्ध छैन। Android सेटिङ > Text-to-speech output (Google Speech Services) मा इन्स्टल गर्नुहोस्।';

  @override
  String get correct => 'सही!';

  @override
  String get incorrect => 'गलत';

  @override
  String get script => 'स्क्रिप्ट';

  @override
  String get next => 'अर्को';

  @override
  String get finish => 'समाप्त';

  @override
  String get result => 'नतिजा';

  @override
  String scoreCorrect(int correct, int total) {
    return '$total मध्ये $correct सही';
  }

  @override
  String get newBest => 'नयाँ उत्कृष्ट अंक!';

  @override
  String get noMistakesLeft => 'यो खण्डमा अब कुनै गल्ती छैन। धेरै राम्रो!';

  @override
  String remainingToReview(int n) {
    return 'अझै $n प्रश्न दोहोर्याउन बाँकी।';
  }

  @override
  String freeFinished(int n) {
    return 'तपाईंले निःशुल्क प्रश्नहरू सक्नुभयो। प्रिमियमले यो खण्डका सबै $n प्रश्न खोल्छ।';
  }

  @override
  String get home => 'गृह';

  @override
  String get tryAgain => 'फेरि प्रयास गर्नुहोस्';

  @override
  String get seePremium => 'प्रिमियम हेर्नुहोस्';

  @override
  String reviewTitle(String section) {
    return 'दोहोर्याउनुहोस्: $section';
  }

  @override
  String get settings => 'सेटिङ';

  @override
  String get language => 'भाषा';

  @override
  String get systemLanguage => 'प्रणाली पूर्वनिर्धारित';

  @override
  String get premium => 'प्रिमियम';

  @override
  String get premiumActive => 'सक्रिय';

  @override
  String get premiumInactive => 'सदस्यता छैन';

  @override
  String get restorePurchases => 'खरिद पुनर्स्थापना';

  @override
  String get restoreSuccess => 'प्रिमियम पुनर्स्थापित भयो।';

  @override
  String get restoreNone => 'सक्रिय सदस्यता भेटिएन।';

  @override
  String get machineTranslation => 'यो भाषामा मेसिन अनुवाद समावेश छ।';

  @override
  String get explanationLanguageNote =>
      'अनुवाद नभएसम्म व्याख्या अंग्रेजीमा देखाइन्छ।';

  @override
  String get paywallTitle => 'JFT-Basic Prep Premium';

  @override
  String get paywallSubtitle => 'जापानी मातृभाषीले लेखेका र जाँचेका प्रश्नहरू';

  @override
  String get benefitAll => '४ वटै खण्डका सबै प्रश्नहरू';

  @override
  String get benefitNew => 'नियमित रूपमा नयाँ प्रश्नहरू थपिन्छन्';

  @override
  String get benefitReview => 'आफ्ना गल्तीहरू असीमित दोहोर्याउनुहोस्';

  @override
  String get yearly => 'वार्षिक';

  @override
  String get monthly => 'मासिक';

  @override
  String pricePerYear(String price) {
    return '$price / वर्ष';
  }

  @override
  String pricePerMonth(String price) {
    return '$price / महिना';
  }

  @override
  String get subscribe => 'सदस्यता लिनुहोस्';

  @override
  String get cancelAnytime =>
      'स्वतः नवीकरण हुन्छ। Google Play मा जुनसुकै बेला रद्द गर्न सकिन्छ।';

  @override
  String get billingUnavailable =>
      'खरिद अहिले उपलब्ध छैन। कृपया पछि प्रयास गर्नुहोस्।';

  @override
  String get purchaseSuccess => 'धन्यवाद! प्रिमियम सक्रिय भयो।';

  @override
  String get purchaseError => 'खरिद असफल भयो। कृपया फेरि प्रयास गर्नुहोस्।';

  @override
  String get alreadyPremium => 'तपाईंसँग पहिले नै प्रिमियम छ।';

  @override
  String get furigana => 'फुरिगाना देखाउनुहोस्';

  @override
  String get furiganaHint => 'कान्जीमाथि हिरागाना उच्चारण';
}
