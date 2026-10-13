# App Store Connect 掲載情報(ドラフト)

App Store Connect の「App情報」「App Storeでの表示」にそのまま貼り付けられる文言ドラフト。
[docs/PLAY_STORE_LISTING.md](PLAY_STORE_LISTING.md)(Google Play向け)の文言・事実整理をAppleの
項目・文字数制限に合わせて書き直したもの。文言の中身(アプリの価値・使い方の説明)は共通。

## App名(30字以内)

```
ReadyGo Phrase：句動詞・熟語
```
(15字。Playと違い「・単語」まで入れると字数超過気味になるため削った。カテゴリ軸の訴求は
サブタイトルと説明文側に任せる)

## サブタイトル(30字以内)

```
TOEICレベル別フラッシュカード
```
(17字)

## プロモーション用テキスト(170字以内、アプリ更新なしでいつでも差し替え可能)

```
知ってる単語なのに聞き取れない。句動詞・熟語・単語をめくって覚える、TOEICレベル別の
フラッシュカードアプリ。レベルは毎回選べて、わからなかった分だけ自動で復習できます。
```

## キーワード(100字以内、カンマ区切り・スペースなし)

```
英語,句動詞,熟語,英単語,TOEIC,フラッシュカード,英会話,留学,ワーホリ,英語学習
```

## 説明(4000字以内)

Play版([docs/PLAY_STORE_LISTING.md](PLAY_STORE_LISTING.md)の「詳しい説明」)と同一文言を使う
(Appleの説明欄に文字数・改行上の制約上の問題はない)。

## カテゴリ

- プライマリ: 教育
- セカンダリ: (任意。設定しないか、リファレンスのみ)

## 年齢制限(Age Rating)

App Store Connectの質問票で決まる。本アプリは暴力・成人向け要素・賭博要素を一切含まない
学習アプリのため、**4+**になる想定(Playの「全ユーザー対象」相当)。質問票は実際にApp Store Connect
上で回答すること。

## 著作権表示

```
© 2026 aidentifind
```

## App Privacy(プライバシーに関する「栄養成分表示」)

Play Console「データセーフティ」と同じ事実整理([docs/PLAY_STORE_LISTING.md](PLAY_STORE_LISTING.md)
の表)をAppleの「データの種類」分類に当てはめたもの。実装(`readygo-speak-api`・`lib/`)を根拠にしている。
最終的な申告内容はTK確認のうえApp Store Connect上で入力する。

| Appleのデータ種別 | 該当データ | 利用者との紐付け | 用途 | 第三者への共有 |
|---|---|---|---|---|
| 識別子(Identifiers) | `POST /api/v1/users`で発行される匿名トークン(メール・氏名等は一切紐づかない) | 利用者に紐付けない(匿名) | App機能(学習履歴の同期・復習キュー生成) | 第三者と共有しない |
| 使用状況データ(Usage Data) | レベル・モード・フリップ結果(覚えている/わからない)・所要時間 | 利用者に紐付けない(匿名) | App機能(復習モードの出題・履歴画面の表示) | 第三者と共有しない |
| 識別子(広告ID/IDFA) | AdMob(`google_mobile_ads`)がバナー広告配信のため取得。ATT許諾次第 | 利用者に紐付く(広告計測) | サードパーティ広告 | Google(AdMob)と共有 |

- **個人を特定する情報(氏名・メール・電話番号・住所等)は収集しない**(アカウント登録・ログイン
  機能自体が無い)
- 位置情報・連絡先・写真等のデバイス権限は要求しない
- トラッキングの許可を求める(`NSUserTrackingUsageDescription`、ATT)。拒否されても広告は
  (パーソナライズなしで)表示される
- 「Appにリンクされていますか」は識別子・使用状況データは**いいえ**(匿名のため)、広告IDは
  ATT同意状況により**トラッキングに使用される可能性あり**として申告する

## 連絡先・URL

| 項目 | 値 |
|---|---|
| デベロッパー名 | aidentifind |
| サポートURL | https://readygo-english.space/phrase/ |
| マーケティングURL | https://readygo-english.space/phrase/ |
| プライバシーポリシーURL | https://aidentifind.jp/privacy-policy.html |
| 連絡先メールアドレス | (運営者に確認。Play版と同じ未確認事項) |

## 輸出コンプライアンス(Export Compliance)

暗号化はHTTPS通信(標準のTLS)のみで、アプリ独自の暗号化は実装していない。Appleの質問票では
「標準の暗号化のみ使用」を選択する想定。

## 未決・要確認

- 開発者連絡先メールアドレスはApp Store Connect登録情報と合わせる必要あり(Play版と同じ未確認事項、
  [docs/PLAY_STORE_LISTING.md](PLAY_STORE_LISTING.md)参照)
- プライバシーポリシーの文面とサーバー送信の実装が食い違っている件(`CLAUDE.md`
  「未確定事項・次のアクション一覧」参照)は、App Store Connectに同じURLを登録する前に
  運営者側で解消しておくことが望ましい
