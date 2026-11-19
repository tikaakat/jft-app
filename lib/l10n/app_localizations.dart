import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_id.dart';
import 'app_localizations_my.dart';
import 'app_localizations_ne.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of L10n
/// returned by `L10n.of(context)`.
///
/// Applications need to include `L10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: L10n.localizationsDelegates,
///   supportedLocales: L10n.supportedLocales,
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
/// be consistent with the languages listed in the L10n.supportedLocales
/// property.
abstract class L10n {
  L10n(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static L10n of(BuildContext context) {
    return Localizations.of<L10n>(context, L10n)!;
  }

  static const LocalizationsDelegate<L10n> delegate = _L10nDelegate();

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
    Locale('en'),
    Locale('id'),
    Locale('my'),
    Locale('ne'),
    Locale('vi'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'JFT-Basic Prep'**
  String get appTitle;

  /// No description provided for @sectionVocab.
  ///
  /// In en, this message translates to:
  /// **'Script and Vocabulary'**
  String get sectionVocab;

  /// No description provided for @sectionConv.
  ///
  /// In en, this message translates to:
  /// **'Conversation and Expression'**
  String get sectionConv;

  /// No description provided for @sectionListen.
  ///
  /// In en, this message translates to:
  /// **'Listening Comprehension'**
  String get sectionListen;

  /// No description provided for @sectionRead.
  ///
  /// In en, this message translates to:
  /// **'Reading Comprehension'**
  String get sectionRead;

  /// No description provided for @premiumUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Premium: all questions unlocked'**
  String get premiumUnlocked;

  /// No description provided for @freeLimit.
  ///
  /// In en, this message translates to:
  /// **'Free: {n} questions per section'**
  String freeLimit(int n);

  /// No description provided for @unlockAll.
  ///
  /// In en, this message translates to:
  /// **'Unlock all questions'**
  String get unlockAll;

  /// No description provided for @statMastered.
  ///
  /// In en, this message translates to:
  /// **'Mastered'**
  String get statMastered;

  /// No description provided for @statAnswered.
  ///
  /// In en, this message translates to:
  /// **'Answered'**
  String get statAnswered;

  /// No description provided for @statAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Accuracy'**
  String get statAccuracy;

  /// No description provided for @masteredOf.
  ///
  /// In en, this message translates to:
  /// **'Mastered {done} / {total}'**
  String masteredOf(int done, int total);

  /// No description provided for @bestScore.
  ///
  /// In en, this message translates to:
  /// **'Best: {pct}%'**
  String bestScore(int pct);

  /// No description provided for @bestNone.
  ///
  /// In en, this message translates to:
  /// **'Best: –'**
  String get bestNone;

  /// No description provided for @accuracyValue.
  ///
  /// In en, this message translates to:
  /// **'Accuracy: {pct}%'**
  String accuracyValue(int pct);

  /// No description provided for @draftsCount.
  ///
  /// In en, this message translates to:
  /// **'Drafts: {n}'**
  String draftsCount(int n);

  /// No description provided for @reviewMistakes.
  ///
  /// In en, this message translates to:
  /// **'Review mistakes'**
  String get reviewMistakes;

  /// No description provided for @noMistakes.
  ///
  /// In en, this message translates to:
  /// **'No mistakes to review.\nKeep practicing!'**
  String get noMistakes;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @answerIs.
  ///
  /// In en, this message translates to:
  /// **'Answer: {answer}'**
  String answerIs(String answer);

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @questionOf.
  ///
  /// In en, this message translates to:
  /// **'Question {i} / {total}'**
  String questionOf(int i, int total);

  /// No description provided for @draftBadge.
  ///
  /// In en, this message translates to:
  /// **'DRAFT (not yet proofread)'**
  String get draftBadge;

  /// No description provided for @playAudio.
  ///
  /// In en, this message translates to:
  /// **'Play audio'**
  String get playAudio;

  /// No description provided for @ttsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Japanese voice is not available. Install it in Android Settings > Text-to-speech output (Google Speech Services).'**
  String get ttsUnavailable;

  /// No description provided for @correct.
  ///
  /// In en, this message translates to:
  /// **'Correct!'**
  String get correct;

  /// No description provided for @incorrect.
  ///
  /// In en, this message translates to:
  /// **'Incorrect'**
  String get incorrect;

  /// No description provided for @script.
  ///
  /// In en, this message translates to:
  /// **'Script'**
  String get script;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @finish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finish;

  /// No description provided for @result.
  ///
  /// In en, this message translates to:
  /// **'Result'**
  String get result;

  /// No description provided for @scoreCorrect.
  ///
  /// In en, this message translates to:
  /// **'{correct} / {total} correct'**
  String scoreCorrect(int correct, int total);

  /// No description provided for @newBest.
  ///
  /// In en, this message translates to:
  /// **'New best score!'**
  String get newBest;

  /// No description provided for @noMistakesLeft.
  ///
  /// In en, this message translates to:
  /// **'No mistakes left in this section. Great job!'**
  String get noMistakesLeft;

  /// No description provided for @remainingToReview.
  ///
  /// In en, this message translates to:
  /// **'{n} question(s) still to review.'**
  String remainingToReview(int n);

  /// No description provided for @freeFinished.
  ///
  /// In en, this message translates to:
  /// **'You have finished the free questions. Premium unlocks all {n} questions in this section.'**
  String freeFinished(int n);

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @seePremium.
  ///
  /// In en, this message translates to:
  /// **'See Premium'**
  String get seePremium;

  /// No description provided for @reviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review: {section}'**
  String reviewTitle(String section);

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @systemLanguage.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get systemLanguage;

  /// No description provided for @premium.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get premium;

  /// No description provided for @premiumActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get premiumActive;

  /// No description provided for @premiumInactive.
  ///
  /// In en, this message translates to:
  /// **'Not subscribed'**
  String get premiumInactive;

  /// No description provided for @restorePurchases.
  ///
  /// In en, this message translates to:
  /// **'Restore purchases'**
  String get restorePurchases;

  /// No description provided for @restoreSuccess.
  ///
  /// In en, this message translates to:
  /// **'Premium restored.'**
  String get restoreSuccess;

  /// No description provided for @restoreNone.
  ///
  /// In en, this message translates to:
  /// **'No active subscription found.'**
  String get restoreNone;

  /// No description provided for @machineTranslation.
  ///
  /// In en, this message translates to:
  /// **'This language includes machine translation.'**
  String get machineTranslation;

  /// No description provided for @explanationLanguageNote.
  ///
  /// In en, this message translates to:
  /// **'Explanations are shown in English until translated.'**
  String get explanationLanguageNote;

  /// No description provided for @paywallTitle.
  ///
  /// In en, this message translates to:
  /// **'JFT-Basic Prep Premium'**
  String get paywallTitle;

  /// No description provided for @paywallSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Questions written and checked by native Japanese speakers'**
  String get paywallSubtitle;

  /// No description provided for @benefitAll.
  ///
  /// In en, this message translates to:
  /// **'All questions in all 4 sections'**
  String get benefitAll;

  /// No description provided for @benefitNew.
  ///
  /// In en, this message translates to:
  /// **'New questions added regularly'**
  String get benefitNew;

  /// No description provided for @benefitReview.
  ///
  /// In en, this message translates to:
  /// **'Review your mistakes without limits'**
  String get benefitReview;

  /// No description provided for @yearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get yearly;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @pricePerYear.
  ///
  /// In en, this message translates to:
  /// **'{price} / year'**
  String pricePerYear(String price);

  /// No description provided for @pricePerMonth.
  ///
  /// In en, this message translates to:
  /// **'{price} / month'**
  String pricePerMonth(String price);

  /// No description provided for @subscribe.
  ///
  /// In en, this message translates to:
  /// **'Subscribe'**
  String get subscribe;

  /// No description provided for @cancelAnytime.
  ///
  /// In en, this message translates to:
  /// **'Auto-renews. Cancel anytime in Google Play.'**
  String get cancelAnytime;

  /// No description provided for @billingUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Purchases are not available yet. Please try again later.'**
  String get billingUnavailable;

  /// No description provided for @purchaseSuccess.
  ///
  /// In en, this message translates to:
  /// **'Thank you! Premium is now active.'**
  String get purchaseSuccess;

  /// No description provided for @purchaseError.
  ///
  /// In en, this message translates to:
  /// **'Purchase failed. Please try again.'**
  String get purchaseError;

  /// No description provided for @alreadyPremium.
  ///
  /// In en, this message translates to:
  /// **'You already have Premium.'**
  String get alreadyPremium;

  /// No description provided for @furigana.
  ///
  /// In en, this message translates to:
  /// **'Show furigana'**
  String get furigana;

  /// No description provided for @furiganaHint.
  ///
  /// In en, this message translates to:
  /// **'Hiragana readings above kanji'**
  String get furiganaHint;
}

class _L10nDelegate extends LocalizationsDelegate<L10n> {
  const _L10nDelegate();

  @override
  Future<L10n> load(Locale locale) {
    return SynchronousFuture<L10n>(lookupL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'id', 'my', 'ne', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_L10nDelegate old) => false;
}

L10n lookupL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return L10nEn();
    case 'id':
      return L10nId();
    case 'my':
      return L10nMy();
    case 'ne':
      return L10nNe();
    case 'vi':
      return L10nVi();
  }

  throw FlutterError(
    'L10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
