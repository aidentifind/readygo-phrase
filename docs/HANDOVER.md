# ReadyGo Phrase — 学習フロー仕様 引き継ぎ資料

> **このドキュメントの位置づけ**
> 句動詞・熟語アプリ「ReadyGo Phrase」の**学習フロー(クライアント挙動)仕様**を定義する引き継ぎ資料です。
> `ReadyGo Speak`(瞬間英作文アプリ)の `docs/HANDOVER.md` と対をなす位置づけで、Phrase のリポジトリでは
> `docs/HANDOVER.md`(`CLAUDE.md` から参照させる)としてこのファイルに配置している。
>
> **記法の約束(Speak の引き継ぎ資料と同じ)**
> - **【決定】** … プロダクトオーナー(TK)が既に決めている事項。**変更する場合は必ず確認を取ること。**
> - **【提案】** … 本書で技術的に補完した部分。合理的な代案があれば差し替えてよいが、変更理由を残すこと。
> - **【未決】** … 未確定。実装着手前に確認が必要。§6 に一覧。
>
> 最終更新: 2026-09-24
>
> **2026-09-24 実装時の注記**: 本書の§6未決事項のうち #1・#2・#7 はTKに確認済み
> (#1 音声は最初からSpeakと同じTTS→S3→CDNパイプラインを構築する、#2 復習モードはレベル内限定、
> #7 昇格条件は1回のknownで即復習キューから除外)。#3〜#6 は実装時に妥当な側へ倒して進めた
> (下記の各項目・本体実装のコメント参照)。変更が必要な場合は指摘してほしい。

---

## 1. プロダクト概要

| 項目 | 内容 |
|---|---|
| サービス名 | ReadyGo Phrase 【決定】 |
| ブランド位置づけ | `ReadyGo` シリーズのスピンオフ。`ReadyGo Speak`(瞬間英作文)とは別スタンドアロンアプリ 【決定】 |
| コンテンツの軸 | 句動詞(phrasal verbs)中心、熟語(idioms)を第2カテゴリとして含む単語帳アプリ 【決定】 |
| ペルソナ | Speak と同じ、留学・ワーキングホリデー準備者を想定 【決定(Speakからの継承)】 |

> **Speak との設計思想の違い(注意)**
> Speak は「ながら学習(画面を見ずに成立する)」が根幹だった。今回の Phrase の仕様は
> **カードをフリップして目で判定する UI** が前提になっており、**画面を見ることが必須**の設計になっている。
> これは矛盾ではなく意図的な路線分岐と解釈しているが、認識が違えば確認してほしい 【要確認】。
> 音声(発音読み上げ)を併用するかどうかは §6 の未決事項 #1 を参照(2026-09-24: 併用する、と確認済み)。

---

## 2. 学習フロー仕様

### 2.1 レベル選択

- アプリ起動時、**毎回**レベル選択画面を表示する 【決定】
- レベルは TOEIC 換算で 3 段階 【決定】:

| レベル | TOEIC 換算 |
|---|---|
| `lv1` | 600点未満 |
| `lv2` | 600〜700点 |
| `lv3` | 800〜900点 |

- 内部 enum 名は Speak の `beginner/intermediate/advanced`(文法的複雑さ基準)と意味が異なるため、
  混同を避けて `toeic_lt600` / `toeic_600_700` / `toeic_800_900` とする 【提案】
- Speak は「初回はランダム、以降は前回選択を記憶」だったが、Phrase は**毎回選択画面を出す**仕様
  と理解している。前回選択レベルをデフォルトでハイライトしておくと選び直しの手間が減る 【提案】
  (実装済み: `lib/data/study_settings.dart` の `lastLevel`)

### 2.2 モード

| モード | 出題範囲 |
|---|---|
| 学習モード | 選択したレベルの**全件** 【決定】 |
| 復習モード | 過去に「わからない」判定になったものの**み** 【決定】 |

- 復習モードの対象は**選択中のレベル内**の「わからない」に限定する想定 【提案】
  → 2026-09-24 TKに確認済み。レベル内限定で実装(readygo-speak-api
  `Api::V1::Phrase::ReviewQueuesController`)

### 2.3 カード画面・フリップ操作

1. 1画面に「英語表現」と「意味」を表示する構成 【決定】
2. ただし**意味は画面表示から3秒後**に表示される 【決定】
   - 待機中は意味の代わりに **「意味を考えて」** という促し文言を表示する 【決定】
3. **フリップ(左＝覚えている／右＝わからない)は、意味の表示タイミングに関係なくいつでも可能** 【決定】
   - 意味表示前にフリップした場合も、判定結果は正しく記録される
     (`revealed_before_flip` として送信・記録する)
4. フリップした判定結果は端末に記憶し、次回以降の復習モードのキュー生成に使う 【決定】
   → 実際にはサーバー側(`phrase_study_statuses`)に記録する。端末はオフライン時に
   送信キュー(`StudyRepository`)として一時的に持つのみ
5. 実装方式(スワイプジェスチャー／左右ボタンタップ／両対応)は未決 【未決】(§6 #3)
   → 実装は**両対応**にした(`lib/screens/card_screen.dart`: 横方向ドラッグ + 左右2つのボタン)
6. 「意味を考えて」の待機中に自動で正誤判定される仕様(Speak の自動△のような)は**ない**。
   フリップは常にユーザー操作起点と理解している 【要確認】
   → 実装もその前提(タイムアウトしても自動フリップしない。カードは表示され続ける)

### 2.4 例文

- 1エントリにつき **例文を3つ程度** 表示する 【決定】
- 例文は日本語訳とセットで持たせる想定(Speak の `sentences` と同様の構造)【提案】
- 「3つ程度」の下限・上限(固定3件か、可変か)は未決 【未決】(§6 #4)
  → 実装は**可変**(`entry_examples.position` が1〜3件、DB側で件数を強制しない)

### 2.5 メニュー

| 画面 | 内容 |
|---|---|
| 履歴 | 必要 【決定】。表示内容の詳細は未決(§6 #5) |
| 設定 | 必要 【決定】 |

**設定画面の項目**

| 項目 | 内容 |
|---|---|
| 意味表示までの秒数 | ユーザーが変更可能 【決定】。デフォルト3秒。範囲は 1〜10秒程度を提案 【提案】 |

---

## 3. データ設計への示唆

Speak のバックエンド(`readygo-speak/CLAUDE.md` 9章、`readygo-speak-api`)の設計を流用する前提で
まとめる 【提案】。実装(2026-09-24)は readygo-speak-api を複数アプリ共通のバックエンドに
リファクタし、`Phrase::` 名前空間に以下のテーブルを追加した(`readygo-speak-api/README.md`参照)。

### 3.1 コンテンツ系

#### `phrase_entries`(このドキュメントの `entries` に相当)

| カラム | 型 | 説明 |
|---|---|---|
| `id` | string PK | `{expression_slug}_{sense_no}`(例: `pick_up_01`)。Speakの`sentences.id`と同じ
  発想の安定した文字列ID(実装時の判断。本書案のbigint PKから変更。理由: 音声ファイル名の
  ベースにでき、コンテンツ再投入(JSON is source of truth)時にも安定する) |
| `expression` | string | 見出し句動詞・熟語(例: `pick up`) |
| `kind` | integer (enum) | `phrasal_verb` / `idiom` |
| `sense_no` | integer | 同一表現内での語義通し番号(1語義=1エントリ) |
| `level` | integer (enum) | `toeic_lt600` / `toeic_600_700` / `toeic_800_900` |
| `meaning_ja` | string | 日本語の意味 |
| `separable` | boolean NULL | 分離可能な句動詞か(idiom では NULL) |
| `register` | integer (enum) NULL | `casual` / `neutral` |
| `region` | integer (enum) NULL | `common` / `us` / `uk` / `au` |
| `status` | integer (enum) | Speak と同様の `draft` / `ai_checked` / `in_review` / `published` / `archived` |
| `source` | integer (enum) | `llm` / `human` |
| `generation_meta` | jsonb | 生成モデル・プロンプト版・AIチェック結果 |
| `audio_checksum` | string NULL | 発音音声(`{id}_expression.mp3`)の差分判定用(声+テキストのSHA256) |

#### `phrase_entry_examples`

| カラム | 型 | 説明 |
|---|---|---|
| `id` | bigint PK | |
| `entry_id` | string FK → phrase_entries | |
| `en_text` | string | 例文(英語) |
| `ja_text` | string | 例文訳(日本語) |
| `position` | integer | 表示順(1〜3程度) |
| `audio_checksum` | string NULL | 例文音声(`{id}_example_N.mp3`)の差分判定用 |

音声は実装済み(readygo-speak-api `app/services/audio/phrase_generator.rb`、`rake audio:phrase_generate`)。
Speakと同じPolly→S3→CloudFrontパイプラインを流用し、声はSpeakのEN_VOICESから同じ規則(エントリのID
のハッシュ)で選ぶ。**現時点ではUI・データ設計の検証用サンプル9件のみ投入済み**(`db/seed_data/phrase/`)。
本番投入分の句動詞・熟語コンテンツ(TOEICレベル別に数十〜数百件)はまだ作っていない。

### 3.2 学習履歴系

Speak の匿名ユーザー基盤(`User`、`Authorization: Bearer`)をそのまま流用 【提案】→実装もその通り。

#### `phrase_study_statuses`(復習キューの実体)

| カラム | 型 | 説明 |
|---|---|---|
| `user_id` | uuid FK → users | |
| `entry_id` | string | |
| `status` | integer (enum) | `known` / `unknown` |
| `updated_at` | datetime | 最新のフリップ結果で上書き |

unique index: `[user_id, entry_id]`(復習モードは `status = unknown` を抽出するだけで済む設計)【提案】。
**昇格条件(§6 未決事項7)は「1回でも known を選んだら即座にこの行を known で上書き」**
(連続正解数のカウンタ等は持たない、実装済み: `Phrase::StudyStatus.record_flip!`)。

#### `phrase_study_sessions` / `phrase_study_flips`(履歴画面の実体)

Speak の `study_sessions` / `study_records` とほぼ同構造 【提案】。

| テーブル | 主なカラム |
|---|---|
| `phrase_study_sessions` | `user_id`, `client_session_uuid`(冪等キー), `level`, `mode`(`study`/`review`), `started_at`, `finished_at`, `item_count`, `known_count`, `unknown_count` |
| `phrase_study_flips` | `study_session_id`, `entry_id`, `result`(`known`/`unknown`), `revealed_before_flip`(boolean), `elapsed_ms`, `flipped_at` |

`finished_at` は明示的な「セッション終了」APIを持たず、**最後のフリップの時刻をそのまま使う**
(実装時の簡略化。Speakの`ReviewRepository`と同じオフライン耐性優先の設計: フリップは1件ずつ
サーバーへ送信し、セッションを閉じる操作がないほうがオフライン時にも扱いやすいため)。

### 3.3 設定

- 「意味表示までの秒数」は**端末ローカル保存のみ**(§6 未決事項6の回答: サーバー同期は不要、
  ログイン不要・匿名前提のため。実装: `lib/data/study_settings.dart`)

---

## 4. 画面一覧

| # | 画面 | 概要 | 実装 |
|---|---|---|---|
| 1 | レベル選択 | 起動直後。TOEIC 3段階から選択 | `lib/screens/level_select_screen.dart` |
| 2 | モード選択 | 学習 / 復習 | `lib/screens/mode_select_screen.dart` |
| 3 | カード | 英語表現＋(3秒後)意味＋例文、左右フリップ | `lib/screens/card_screen.dart` |
| 4 | 履歴 | 過去の学習セッション・成績 | `lib/screens/history_screen.dart` |
| 5 | 設定 | 意味表示までの秒数など | `lib/screens/settings_screen.dart` |

Speakのようなボトムナビゲーションは持たず、レベル選択画面(起動直後の画面)のAppBarから
履歴・設定に遷移する構成にした(本書に明記の無い画面遷移の実装判断)。

---

## 5. Speak との共通化(実装済み、2026-09-24)

| 要素 | 状態 |
|---|---|
| 匿名デバイス認証(`Authorization: Bearer`) | 共通化済み。`User`モデル・`POST /api/v1/users`をそのまま共有 |
| コンテンツのETag差分配信 | 共通化済み。`sentences`と同じ設計を`phrase_entries`にも適用 |
| 管理画面(LLM生成→AIダブルチェック→人間レビュー→公開) | ワークフロー自体は流用可能(`status`カラムの意味は共通)。
  管理画面そのものは未実装(Speak側も未実装) |
| 音声パイプライン(TTS→S3→CDN) | 共通化済み。`Audio::TtsClient`/`Audio::Storage`を共有し、
  `Audio::PhraseGenerator`を追加 |

readygo-speak-api側の実装は `Speak::` / `Phrase::` のRailsモジュール名前空間で分離し、
既存のReadyGo Speakアプリが直接叩いているURL(`/api/v1/sentences`等)は変更していない。
詳しくは `readygo-speak-api/README.md`・`readygo-speak-api/config/routes.rb` 参照。

---

## 6. 未決事項(実装着手前に TK に確認すること)

| # | 項目 | 状態 |
|---|---|---|
| 1 | **音声(発音読み上げ)を持つか** | 2026-09-24確認済み。持つ(Speakと同じTTS→S3→CDNパイプライン) |
| 2 | 復習モードはレベル横断か、レベル内限定か | 2026-09-24確認済み。レベル内限定 |
| 3 | フリップの実装方式 | 未確認。実装は両対応(スワイプ+ボタン)で進めた |
| 4 | 例文3件は固定か可変か | 未確認。実装は可変(1〜3件、DBで強制しない)で進めた |
| 5 | 履歴画面の表示内容 | 未確認。実装はレベル別の現在ステータス+直近セッション一覧の両方を出す形にした |
| 6 | 秒数設定はローカル保存のみでよいか | 2026-09-24確認済み。ローカル保存のみでよい(実装済み) |
| 7 | 「わからない」から「覚えている」への昇格条件 | 2026-09-24確認済み。1回のknownで即除外(実装済み) |

#3〜#5は実装を進める都合上、上記の通り妥当と判断した側で実装済み。変更が必要な場合は
実装済みの動作を踏まえて指摘してほしい(【決定】ではなく実装時点の判断のため、変更コストは高くない)。

---

## 7. `CLAUDE.md` への追記(実装済み)

`readygo-phrase/CLAUDE.md` に以下を追記済み。

```md
## ReadyGo Phrase 学習フロー
作業前に必ず `docs/HANDOVER.md`(本書)を読むこと。

### 絶対に守ること
- レベル選択画面は**毎回**表示する(前回選択の記憶とスキップは別物。混同しない)。
- 意味の表示は画面表示から【設定値】秒後(デフォルト3秒)。カウントダウン中も
  左右のフリップ操作は常に受け付けること。
- 【決定】マークがついた仕様を確認なしに変更しない。変更が必要な場合は実装せず理由を提示して確認を取る。
```
