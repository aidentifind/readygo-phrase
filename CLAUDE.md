# ReadyGo Phrase — 開発引き継ぎ資料(CLAUDE.md)

> リポジトリのルートに配置(Claude Codeが起動時に自動で読み込む)。
> 仕様変更が入るたびに、このファイルを手動で更新すること。

## プロダクト概要

- **サービス名**: ReadyGo Phrase。"ReadyGo" をマスターブランドとし、機能別にサブネームを付ける
  命名戦略(`readygo-speak/CLAUDE.md` 1章)の2つ目のアプリ。句動詞・熟語学習アプリ
- **ターゲット**: [ReadyGo Speak](https://github.com/aidentifind/readygo-speak) と同じ、
  留学・ワーホリ渡航を控えた日本人準備層
- **コアコンセプト**: カードをフリップして目で判定するフラッシュカードUI。
  Speakの「ながら学習(画面を見ない)」とは異なり、**画面を見ることが必須**の設計(意図的な路線分岐)
- **プラットフォーム**: Android・iOS(Speakと同じくAndroid先行、Flutter)
- **バックエンド**: `readygo-speak-api` をReadyGo Speakと共有する(複数アプリ共通化、
  2026-09-24。`Speak::`/`Phrase::`のRailsモジュール名前空間で分離。詳しくは
  `readygo-speak-api/README.md`参照)

## ReadyGo Phrase 学習フロー

作業前に必ず [`docs/HANDOVER.md`](docs/HANDOVER.md) を読むこと。学習フロー(画面構成・
フリップ操作・データ設計)の正はこのファイル。

### 絶対に守ること

- レベル選択画面は**毎回**表示する(前回選択の記憶とスキップは別物。混同しない)。
- 意味の表示は画面表示から【設定値】秒後(デフォルト3秒、`StudySettings.revealSeconds`)。
  カウントダウン中も左右のフリップ操作は常に受け付けること。
- 【決定】マークがついた仕様(`docs/HANDOVER.md`参照)を確認なしに変更しない。
  変更が必要な場合は実装せず理由を提示して確認を取る。

## ブランド・デザインシステム

`readygo-speak/CLAUDE.md` 2章の「Speak A」ブランド(コーラル`#FF6A1F`→マゼンタ`#FF1E88`の
グラデーション、Outfit/Zen Kaku Gothic New)をカラートークン・書体としてそのまま踏襲している
(`lib/theme/`)。**ただし「Speak A」マーク自体(横顔+Aの意匠)はReadyGo Speak専用のロゴであり、
ReadyGo Phrase用のロゴはまだデザインしていない**。現状はアプリ内のブロック画面等で
Material Iconsのプレースホルダー(`Icons.style_rounded`)を使っている。アプリアイコン・
起動画面もFlutterのデフォルトのまま(`flutter create`で生成する分のみ)。

## 技術スタック

- **フロントエンド**: Flutter(readygo-speakと同じ構成方針。状態管理はProvider/Riverpod等を
  使わず素の`StatefulWidget`+`ValueNotifier`、リポジトリは`static instance`シングルトン)
- **バックエンド**: readygo-speak-api(Rails API-only)を共有。エンドポイントは
  `/api/v1/phrase/...`(コンテンツ配信のみ`/api/v1/phrase/entries`が認証不要、
  学習記録系は`Authorization: Bearer`。匿名ユーザー発行は`/api/v1/users`をSpeakと共有)
- **音声**: readygo-speak-apiのAmazon Polly(Neural)パイプラインを共有(`Audio::PhraseGenerator`)。
  S3 + CloudFront(`cdn.readygo-english.space`、Speakと共通のCDN)で配信

## 未確定事項・次のアクション一覧

- [x] **ネイティブプロジェクトの生成**: 2026-09-25、Flutter 3.47.4で`flutter create`を実行し、
      `android/`・`ios/`を生成済み。パッケージ名/Bundle IDは仮値のまま(下記未決事項参照)
- [ ] ReadyGo Phrase専用ロゴのデザイン(readygo-speakの「Speak A」ロゴ確定と同じプロセスが必要)
- [ ] パッケージ名/Bundle ID・ストアURLは`space.readygo_english.phrase`
      (`lib/config/app_config.dart`)で仮置き。Speakの命名規則を踏襲した想定値で、正式決定ではない。
      `flutter create`が自動生成した実際の値(`space.readygoenglish.readygo_phrase` /
      `space.readygo-english.readygoPhrase`)とも異なるため、正式決定時にどちらも揃える必要がある
- [x] 本番投入分の句動詞・熟語コンテンツ。2026-09-25、TOEICレベル別111件を投入済み
      (`readygo-speak-api/db/seed_data/phrase/readygo-phrase-seed-content.json`、旧
      `entries_v1.json`の9件サンプルから置き換え)。追加・更新の作り方は`docs/HANDOVER.md` 3.1章・
      readygo-speakのコンテンツ生成プロンプトテンプレートを参照
- [ ] 広告(AdMob)は未実装・未検討(`docs/HANDOVER.md`に言及が無いため今回はスコープ外とした)
- [ ] readygo-speak-apiのデプロイ(Render)・CORS設定にReadyGo Phraseのドメイン/アプリを反映
- [ ] サイト(`readygo-english.space/phrase/`)は未作成。`AppConfig.siteUrl`は想定パスのみ
- [ ] `docs/HANDOVER.md` §6 未決事項の #3〜#5(フリップ実装方式・例文の可変数・履歴の表示内容)は
      実装時に妥当な側で進めた。TKの確認を推奨
