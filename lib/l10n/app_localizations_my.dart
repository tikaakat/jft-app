// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Burmese (`my`).
class L10nMy extends L10n {
  L10nMy([String locale = 'my']) : super(locale);

  @override
  String get appTitle => 'JFT-Basic Prep';

  @override
  String get sectionVocab => 'စာလုံးနှင့် ဝေါဟာရ';

  @override
  String get sectionConv => 'စကားပြောနှင့် အသုံးအနှုန်း';

  @override
  String get sectionListen => 'နားထောင်ခြင်း';

  @override
  String get sectionRead => 'စာဖတ်ခြင်း';

  @override
  String get premiumUnlocked => 'Premium: မေးခွန်းအားလုံး ဖွင့်ပြီး';

  @override
  String freeLimit(int n) {
    return 'အခမဲ့: အပိုင်းတစ်ခုလျှင် မေးခွန်း $n ခု';
  }

  @override
  String get unlockAll => 'မေးခွန်းအားလုံး ဖွင့်ရန်';

  @override
  String get statMastered => 'ကျွမ်းကျင်ပြီး';

  @override
  String get statAnswered => 'ဖြေပြီး';

  @override
  String get statAccuracy => 'မှန်ကန်မှု';

  @override
  String masteredOf(int done, int total) {
    return 'ကျွမ်းကျင်ပြီး $done / $total';
  }

  @override
  String bestScore(int pct) {
    return 'အကောင်းဆုံး: $pct%';
  }

  @override
  String get bestNone => 'အကောင်းဆုံး: –';

  @override
  String accuracyValue(int pct) {
    return 'မှန်ကန်မှု: $pct%';
  }

  @override
  String draftsCount(int n) {
    return 'မူကြမ်း: $n';
  }

  @override
  String get reviewMistakes => 'အမှားများ ပြန်လေ့ကျင့်ရန်';

  @override
  String get noMistakes => 'ပြန်လေ့ကျင့်ရန် အမှားမရှိပါ။\nဆက်လေ့ကျင့်ပါ!';

  @override
  String get retry => 'ပြန်ဖြေရန်';

  @override
  String answerIs(String answer) {
    return 'အဖြေ: $answer';
  }

  @override
  String get close => 'ပိတ်ရန်';

  @override
  String questionOf(int i, int total) {
    return 'မေးခွန်း $i / $total';
  }

  @override
  String get draftBadge => 'မူကြမ်း (မစစ်ဆေးရသေး)';

  @override
  String get playAudio => 'အသံဖွင့်ရန်';

  @override
  String get ttsUnavailable =>
      'ဂျပန်အသံ မရနိုင်ပါ။ Android Settings > Text-to-speech output (Google Speech Services) တွင် ထည့်သွင်းပါ။';

  @override
  String get correct => 'မှန်ပါသည်!';

  @override
  String get incorrect => 'မှားပါသည်';

  @override
  String get script => 'စာသား';

  @override
  String get next => 'နောက်တစ်ခု';

  @override
  String get finish => 'ပြီးဆုံး';

  @override
  String get result => 'ရလဒ်';

  @override
  String scoreCorrect(int correct, int total) {
    return '$total ခုတွင် $correct ခု မှန်';
  }

  @override
  String get newBest => 'အမှတ်အကောင်းဆုံး အသစ်!';

  @override
  String get noMistakesLeft => 'ဤအပိုင်းတွင် အမှားမကျန်တော့ပါ။ တော်လိုက်တာ!';

  @override
  String remainingToReview(int n) {
    return 'ပြန်လေ့ကျင့်ရန် မေးခွန်း $n ခု ကျန်သေးသည်။';
  }

  @override
  String freeFinished(int n) {
    return 'အခမဲ့မေးခွန်းများ ပြီးဆုံးပါပြီ။ Premium ဖြင့် ဤအပိုင်းရှိ မေးခွန်း $n ခုလုံး ဖြေနိုင်ပါသည်။';
  }

  @override
  String get home => 'ပင်မ';

  @override
  String get tryAgain => 'ထပ်ဖြေရန်';

  @override
  String get seePremium => 'Premium ကြည့်ရန်';

  @override
  String reviewTitle(String section) {
    return 'ပြန်လေ့ကျင့်: $section';
  }

  @override
  String get settings => 'ဆက်တင်';

  @override
  String get language => 'ဘာသာစကား';

  @override
  String get systemLanguage => 'စနစ်မူလ';

  @override
  String get premium => 'Premium';

  @override
  String get premiumActive => 'အသုံးပြုနေသည်';

  @override
  String get premiumInactive => 'စာရင်းမသွင်းရသေး';

  @override
  String get restorePurchases => 'ဝယ်ယူမှု ပြန်ယူရန်';

  @override
  String get restoreSuccess => 'Premium ပြန်ရပါပြီ။';

  @override
  String get restoreNone => 'အသုံးပြုနေသော စာရင်းသွင်းမှု မတွေ့ပါ။';

  @override
  String get machineTranslation =>
      'ဤဘာသာစကားတွင် စက်ဘာသာပြန်ချက်များ ပါဝင်သည်။';

  @override
  String get explanationLanguageNote =>
      'ဘာသာပြန်မပြီးမချင်း ရှင်းလင်းချက်များကို အင်္ဂလိပ်ဘာသာဖြင့် ပြသပါမည်။';

  @override
  String get paywallTitle => 'JFT-Basic Prep Premium';

  @override
  String get paywallSubtitle =>
      'ဂျပန်မိခင်ဘာသာစကားပြောသူများ ရေးသားစစ်ဆေးထားသော မေးခွန်းများ';

  @override
  String get benefitAll => 'အပိုင်း ၄ ခုလုံးရှိ မေးခွန်းအားလုံး';

  @override
  String get benefitNew => 'မေးခွန်းအသစ်များ ပုံမှန်ထည့်ပေးသည်';

  @override
  String get benefitReview => 'အမှားများကို အကန့်အသတ်မရှိ ပြန်လေ့ကျင့်နိုင်သည်';

  @override
  String get yearly => 'နှစ်စဉ်';

  @override
  String get monthly => 'လစဉ်';

  @override
  String pricePerYear(String price) {
    return '$price / နှစ်';
  }

  @override
  String pricePerMonth(String price) {
    return '$price / လ';
  }

  @override
  String get subscribe => 'စာရင်းသွင်းရန်';

  @override
  String get cancelAnytime =>
      'အလိုအလျောက် သက်တမ်းတိုးသည်။ Google Play တွင် အချိန်မရွေး ပယ်ဖျက်နိုင်သည်။';

  @override
  String get billingUnavailable =>
      'ဝယ်ယူမှု မရနိုင်သေးပါ။ နောက်မှ ထပ်ကြိုးစားပါ။';

  @override
  String get purchaseSuccess =>
      'ကျေးဇူးတင်ပါသည်! Premium စတင်အသုံးပြုနိုင်ပါပြီ။';

  @override
  String get purchaseError => 'ဝယ်ယူမှု မအောင်မြင်ပါ။ ထပ်ကြိုးစားပါ။';

  @override
  String get alreadyPremium => 'သင့်တွင် Premium ရှိပြီးဖြစ်သည်။';

  @override
  String get furigana => 'Furigana ပြရန်';

  @override
  String get furiganaHint => 'ခန်ဂျီအပေါ်တွင် ဟိရဂန အသံထွက်';
}
