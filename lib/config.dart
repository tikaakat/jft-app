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
