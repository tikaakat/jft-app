/// Central app configuration.
library;

/// Free questions per category for non-premium users.
/// Kept as a single constant so it can later be driven by an A/B test
/// (e.g. Firebase Remote Config) without touching UI code.
const int kFreeLimitPerCategory = 3;

/// Number of questions drawn for one premium quiz session.
const int kQuestionsPerSession = 10;

/// `flutter run --dart-define=UNLOCK_ALL=true` treats the user as premium.
/// Used for closed testing before billing (Phase 2) exists.
const bool kUnlockAll = bool.fromEnvironment('UNLOCK_ALL');

/// Questions with `"reviewed": false` are drafts that have not been
/// proofread by a native speaker. They are shown in debug builds only,
/// unless `--dart-define=INCLUDE_DRAFTS=true` is passed.
const bool kIncludeDraftsDefine = bool.fromEnvironment('INCLUDE_DRAFTS');

/// RevenueCat public Android SDK key ("goog_..."). Pass it at build time:
/// `flutter build appbundle --dart-define=RC_API_KEY=goog_xxx`.
/// When empty, billing is disabled and the paywall says "not available yet".
const String kRevenueCatApiKey = String.fromEnvironment('RC_API_KEY');

/// RevenueCat entitlement that unlocks all content.
const String kEntitlementId = 'premium';
