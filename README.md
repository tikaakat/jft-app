# JFT-Basic Prep (Android)

JFT-Basic 対策アプリ。Flutter／Android のみ。

## 状態（Phase 1.5）
- 4 分野（文字と語彙／会話と表現／聴解／読解）、各 30 問、計 120 問。**全問が未校正の下書き（`"reviewed": false`）**。
- 聴解は `flutter_tts` で台本を読み上げる。男性と女性は声の高さで区別する。
- 選択肢は出題時にシャッフルする（`Question.shuffled`）。正解位置の均等性はテストで確認済み。
- ベストスコア（%）、習得済みの問題、間違えた問題（Phase 1.5 の復習用）を `shared_preferences` に保存する。
- 無料枠は各分野 `kFreeLimitPerCategory`（= 3）問。終了時に Premium の案内を出す（課金は Phase 2）。
- **復習（Phase 1.5）**：ホーム右上のボタン（間違えた数をバッジで表示）から開く。最後の解答が不正解だった問題を分野ごとに一覧で表示し、タップすると正解と解説を出す。「Retry」で間違えた問題だけを出題し、正解した問題は一覧から外れる。復習ではベストスコアを更新しない。
- **進捗表示（Phase 1.5）**：ホーム上部に全体の習得数、回答数、正答率を表示する。分野カードにも正答率を出す。
- イベント（`quiz_start` / `quiz_complete` / `review_start` / `review_complete` / `paywall_view`）は `lib/services/analytics.dart` でコンソールに出すだけ。Firebase はここに接続する。

## 問題の校正フロー（ルール：全問ネイティブ校正）
1. `assets/questions.json` を校正し、OK の問題を `"reviewed": true` にする。
2. **リリースビルドは `reviewed: true` の問題しか表示しない。** デバッグビルドでは下書きも表示し、画面に「DRAFT」と出る。
3. `flutter test` で形式チェック（ID の重複、4 択、解説あり、聴解には台本、読解には本文、各分野 30 問以上）と未校正件数の表示を行う。

問題の形式：
```json
{"id":"l001","category":"listen","level":"A2","text":"男の人は 何を 買いますか。",
 "script":[{"speaker":"F","text":"いらっしゃいませ。"},{"speaker":"M","text":"…"}],
 "passage":"（読解のみ）",
 "choices":["…","…","…","…"],"answer":2,
 "explanation":{"en":"…"},"reviewed":false}
```
- `speaker` は `M`（男性）、`F`（女性）、`N`（ナレーション）のいずれか。
- `explanation` は言語コードのマップ。旧形式の文字列も読める。
- ファイル全体は `{"version":1,"questions":[...]}`。素の配列でも読める。リモート配信へは `QuestionSource` の実装を差し替えるだけで移行できる。

## 開発
```bash
flutter pub get
flutter test
flutter run                                   # Pixel を USB 接続して起動
flutter run --dart-define=UNLOCK_ALL=true     # Premium 扱い（全問を出題）
```
リリースビルド：
```bash
flutter build appbundle
# 下書きも含めたテスト用 APK
flutter build apk --release --dart-define=INCLUDE_DRAFTS=true --dart-define=UNLOCK_ALL=true
```

### リリース署名
`android/key.properties` を作成する（git 管理外）。無い場合はデバッグ鍵で署名されるため、Play にはアップロードできない。
```
storePassword=...
keyPassword=...
keyAlias=upload
storeFile=/absolute/path/upload-keystore.jks
```
鍵の作成：`keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload`

### 要確認
- Application ID は仮に `com.nihongoprep.jft_prep` にしている。Play への初回アップロード後は変更できないので、確定してから出すこと（`android/app/build.gradle.kts`）。
- Flutter 3.47 以降が必要（`material_ui` パッケージを使うため）。

## 構成
```
lib/
  config.dart                 kFreeLimitPerCategory などの定数
  models/question.dart        Section（分野）、Question、シャッフル
  data/question_source.dart   QuestionSource（差し替え可能）、QuestionBank（下書きの除外）
  data/progress_store.dart    スコアと進捗の保存
  logic/session.dart          出題セットの組み立て（無料と Premium）
  services/tts_service.dart   TTS（聴解）
  services/analytics.dart     計測
  screens/                    ホーム、クイズ（復習モードを含む）、復習一覧
```
