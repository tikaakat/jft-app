# JFT-Basic Prep (Android)

JFT-Basic 対策アプリ。Flutter／Android のみ。

## 状態（Phase 2：コード実装済み、課金の設定待ち）
- 4 分野（文字と語彙／会話と表現／聴解／読解）、各 30 問、計 120 問。**全問が未校正の下書き（`"reviewed": false`）**。
- 聴解は `flutter_tts` で台本を読み上げる。男性と女性は声の高さで区別する。
- 選択肢は出題時にシャッフルする（`Question.shuffled`）。正解位置の均等性はテストで確認済み。
- ベストスコア（%）、習得済みの問題、間違えた問題（Phase 1.5 の復習用）を `shared_preferences` に保存する。
- 無料枠は各分野 `kFreeLimitPerCategory`（= 3）問。終了時に Premium の案内を出す（課金は Phase 2）。
- **復習（Phase 1.5）**：ホーム右上のボタン（間違えた数をバッジで表示）から開く。最後の解答が不正解だった問題を分野ごとに一覧で表示し、タップすると正解と解説を出す。「Retry」で間違えた問題だけを出題し、正解した問題は一覧から外れる。復習ではベストスコアを更新しない。
- **進捗表示（Phase 1.5）**：ホーム上部に全体の習得数、回答数、正答率を表示する。分野カードにも正答率を出す。
- **課金（Phase 2）**：RevenueCat（`purchases_flutter`）を使う。Entitlement は `premium`。ペイウォールでは年額と月額を表示し、価格は Google Play の国別価格をそのまま出す。購入の復元にも対応する。API キーが無いと課金は無効になり、ペイウォールには「準備中」と表示する。Premium 状態は端末に保存するので、オフラインでも有効なまま。
- **設定画面（Phase 2）**：UI 言語、ふりがなの ON/OFF、Premium の状態、購入の復元。
- **UI 多言語（Phase 2）**：英語、インドネシア語、ネパール語、ミャンマー語、ベトナム語。英語以外は LLM による下訳で、設定画面に「機械翻訳を含む」と表示する。ネイティブ確認が済んだ言語は `kNativeCheckedLanguages`（`lib/app_services.dart`）に追加する。解説はまだ英語のみで、`explanation` に言語コード（`id`/`ne`/`my`/`vi`）を足せばその言語で表示される。
- **ふりがな（Phase 2）**：問題データに `{漢字|かんじ}` と書く。ON にすると漢字の上に読みを表示し、OFF では漢字だけを表示する。TTS には漢字のまま渡す（ひらがなだけだと単語の区切りやアクセントが不自然になるため）。漢字の読みと書き方の問題は `"noFurigana": true` にして、答えが見えないようにしている。既存の問題には `tool/furigana_draft.py` で**ふりがなの下書きを自動で付けてある**。校正のときに読みも確認すること。
- イベント（`quiz_start` / `quiz_complete` / `review_start` / `review_complete` / `paywall_view` / `purchase`）は `lib/services/analytics.dart` でコンソールに出すだけ。Firebase はここに接続する。

役割分担とタスク一覧は [`docs/TODO.md`](docs/TODO.md) にある。

## 問題の校正フロー（ルール：全問ネイティブ校正）
**スプレッドシートで校正する（推奨）**
```bash
python3 tool/review_sheet.py export assets/questions.json review.csv   # 書き出し
# Google スプレッドシートや Excel で修正し、ok 列に 1 を入れて CSV で保存
python3 tool/review_sheet.py import assets/questions.json review.csv   # 取り込み
```
取り込むと、修正を反映し、`ok` を付けた問題を `reviewed: true` にし、`comment` 列の内容を一覧で出す。

**ふりがなの下書き**：`python3 tool/furigana_draft.py assets/questions.json`（`pip install sudachipy sudachidict_core` が必要）。まだマークアップの無い文だけに付ける。

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

### 課金の設定（RevenueCat）
1. Play Console でサブスク商品を 2 つ作る（年額と月額）。国別価格もここで設定する。
2. RevenueCat でプロジェクトを作り、Google Play アプリを登録する（サービスアカウントの JSON が必要）。
3. Entitlement `premium` を作り、2 つの商品を紐付ける。Offering（current）には Package の Annual と Monthly を追加する。
4. Android 用の公開 SDK キー（`goog_...`）を渡してビルドする。
```bash
flutter build appbundle --dart-define=RC_API_KEY=goog_xxxxxxxx
```
課金のテストは、Play Console の内部テストトラックにアップロードし、ライセンステスターのアカウントで行う。

### UI 文言の編集
`lib/l10n/app_*.arb` を編集して `flutter gen-l10n` を実行する（ビルド時にも自動で生成される）。`test/l10n_test.dart` で全言語のキーとプレースホルダーが揃っているかを検査する。

### リリース署名
`android/key.properties` を作成する（git 管理外）。無い場合はデバッグ鍵で署名されるため、Play にはアップロードできない。
```
storePassword=...
keyPassword=...
keyAlias=upload
storeFile=/absolute/path/upload-keystore.jks
```
鍵の作成：`keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload`

### アイコンとストア用画像
`python3 tool/make_icons.py` で `android/app/src/main/res/mipmap-*` と `store/` に書き出す（Pillow と日本語フォントが必要）。ストア掲載文、プライバシーポリシー、データセーフティの回答案も `store/` にある。

### 要確認
- Application ID は仮に `com.nihongoprep.jft_prep` にしている。Play への初回アップロード後は変更できないので、確定してから出すこと（`android/app/build.gradle.kts`）。
- Flutter 3.47 以降が必要（`material_ui` パッケージを使うため）。

## 構成
```
lib/
  config.dart                 kFreeLimitPerCategory、RC_API_KEY などの定数
  app_services.dart           サービスの束ね、UI 言語、ふりがなの設定
  l10n/                       UI 文言（ARB と生成コード）
  models/question.dart        Section（分野）、Question、シャッフル
  data/question_source.dart   QuestionSource（差し替え可能）、QuestionBank（下書きの除外）
  data/progress_store.dart    スコアと進捗の保存
  logic/session.dart          出題セットの組み立て（無料と Premium）
  logic/ruby.dart             ふりがな記法の解析
  services/tts_service.dart   TTS（聴解）
  services/purchase_service.dart  課金（RevenueCat）
  services/analytics.dart     計測
  screens/                    ホーム、クイズ（復習モードを含む）、復習一覧、ペイウォール、設定
```
