# ReadyGo Phrase — 開発引き継ぎ資料(CLAUDE.md)

> リポジトリのルートに配置(Claude Codeが起動時に自動で読み込む)。
> 仕様変更が入るたびに、このファイルを手動で更新すること。

## プロダクト概要

- **サービス名**: ReadyGo Phrase。"ReadyGo" をマスターブランドとし、機能別にサブネームを付ける
  命名戦略(`readygo-speak/CLAUDE.md` 1章)の2つ目のアプリ。句動詞・熟語・単語学習アプリ
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
(`lib/theme/`)。**「Speak A」マーク自体(横顔+Aの意匠)はReadyGo Speak専用のロゴ**で、
ReadyGo Phrase用にはシリーズ頭文字ロゴ(P、前傾-5°)を2026-09-26に確定した
(`assets/branding/README.md`参照)。アプリアイコン(Android・iOS)は`flutter_launcher_icons`で
このロゴに差し替え済み。アプリ内のブロック画面等はまだMaterial Iconsのプレースホルダー
(`Icons.style_rounded`)のままで、このマークに差し替えるかは未検討。起動画面もFlutterの
デフォルトのまま。

## 収益モデル

`readygo-speak/CLAUDE.md` 8章と同じ方針・実装(バナー広告のみ、インタースティシャルは避ける)。

### AdMob実装(2026-09-26)

- **配置**: レベル選択・モード選択・履歴・設定は画面下部、カード画面(学習・復習)は**上部**
  (AppBarの下)。カード画面の下部は「覚えている/わからない」ボタンがあり、近くに置くと
  誤タップ誘発でAdMobポリシー違反になりやすいため。Speakのようなボトムナビゲーション+
  共通シェルを持たないため、Speakは1箇所だった下部バナーをPhraseでは画面ごとに置いている。
  形式はアンカー型アダプティブバナー
- **ID**: アプリID Android `ca-app-pub-5922624949407858~6753931360`(AndroidManifest.xml)・
  iOS `ca-app-pub-5922624949407858~1792500295`(Info.plistの`GADApplicationIdentifier`)。
  広告ユニットは上部(カード画面) Android `.../1804857011`・iOS `.../5568842204`、
  下部(その他画面) Android `.../3105581966`・iOS `.../8087369347`(`lib/config/ad_config.dart`)。
  **リリースビルド以外は常にGoogleのテスト用ID**(開発中に本番広告を表示・タップすると
  無効なトラフィックでアカウント停止の対象になるため)
- **同意(UMP)・SKAdNetwork・トラッキング許可**: readygo-speakと全く同じ実装
  (`lib/ads/ads_service.dart`・`lib/ads/banner_ad_slot.dart`はreadygo-speakからほぼそのまま移植)。
  iOSシミュレータでUMP同意フォーム→ATCダイアログ→テスト広告表示まで動作確認済み
- **リモート制御**: `phrase.ads_enabled`(サーバーのapp_config)は元々用意されていたため、
  バックエンド側の変更は不要だった
- **未対応**: AdMob管理画面の「プライバシーとメッセージ」でGDPRメッセージを作成・公開
  (作らないとEEA・英国でフォームが出ず、広告も出ない)、`app-ads.txt`の設置、
  Play Consoleの「広告を含む」申告とデータセーフティ(広告ID)。いずれもSpeak側でも
  未対応のまま残っている項目(readygo-speak/CLAUDE.md 8章参照)

## ブランチ運用(develop / main、2026-10-06導入)

readygo-speak・readygo-speak-apiと同じ考え方(詳細は[docs/RELEASE_FLOW.md](docs/RELEASE_FLOW.md)):
普段の開発は`develop`、ストア提出に向けたリリース作業のときだけ`main`を進める。

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
- [x] ReadyGo Phrase専用ロゴのデザイン。2026-09-26確定、アプリアイコンに反映済み
      (`assets/branding/README.md`参照)。アプリ内プレースホルダー・起動画面への適用は未着手
- [ ] パッケージ名/Bundle ID・ストアURLは`space.readygo_english.phrase`
      (`lib/config/app_config.dart`)で仮置き。Speakの命名規則を踏襲した想定値で、正式決定ではない。
      `flutter create`が自動生成した実際の値(`space.readygoenglish.readygo_phrase` /
      `space.readygo-english.readygoPhrase`)とも異なるため、正式決定時にどちらも揃える必要がある
- [x] 本番投入分の句動詞・熟語コンテンツ。2026-09-25、TOEICレベル別111件を投入済み
      (`readygo-speak-api/db/seed_data/phrase/readygo-phrase-seed-content.json`、旧
      `entries_v1.json`の9件サンプルから置き換え)。追加・更新の作り方は`docs/HANDOVER.md` 3.1章・
      readygo-speakのコンテンツ生成プロンプトテンプレートを参照
- [x] 広告(AdMob)。2026-09-26、バナー広告をreadygo-speakと同じ仕様で実装・本番ID設定済み
      (「収益モデル」章参照)。GDPRメッセージ・app-ads.txt・Play Consoleの広告申告は未対応
- [x] readygo-speak-apiのデプロイ(Render)。確認済み: 本番(`api.readygo-english.space`)が稼働中で、
      `/api/v1/phrase/entries`が111件を正しく返す(2026-10-06確認)。CORSは`readygo-english.space`
      オリジンを本番許可済みで、アプリ本体(Android/iOS)はそもそもCORS対象外のため追加対応は不要。
      2026-10-04、`develop`/`main`ブランチ+Render dev/prod環境分離を導入(詳細は
      `readygo-speak-api/docs/RELEASE_FLOW.md`)。例文等を変更したら`develop`にpushし、
      `api-dev.readygo-english.space`で確認してから`main`へPRする運用に変わった
- [x] サイト(`readygo-english.space/phrase/`)を作成・デプロイ済み(2026-09-26作成、2026-10-06時点で
      実際に公開されていることを確認。`readygo-speak-api/site/phrase/index.html`、デザイン・コード構成は
      ReadyGo Speakの`site/speak/index.html`を踏襲、ロゴは本アプリの「P」マークを使用)。
      アプリ未公開のため、CTAは引き続き「Android版 近日公開」の非活性表示(代わりにReadyGo Speakの
      Google Playページへ誘導)。**アプリを公開したら、CTAをストアリンクに差し替えてから再デプロイすること**
- [ ] プライバシーポリシーの文面確認(2026-10-06発見): `AppConfig.privacyPolicyUrl`に設定した
      aidentifind共通ポリシーは「学習履歴は端末内のみ保存」としているが、Phraseの実装(§2.2)は
      フリップ結果を`phrase_study_statuses`としてサーバーに送信している。readygo-speak側でも
      同じ矛盾が見つかっており(readygo-speak/CLAUDE.md参照)、運営者によるポリシー文面の修正が必要
- [ ] Android本番署名(アップロード鍵)の設定。Gradle側の雛形(`android/app/build.gradle.kts`が
      `android/key.properties`の有無で自動的にdebug/release鍵を切り替える仕組み)と手順書
      (`android/RELEASE_SIGNING.md`)は2026-10-06に準備済み。実際のアップロード鍵の作成・
      `android/key.properties`の作成はTK本人が行う必要がある
- [ ] `develop`ブランチの初回セットアップ(2026-10-06、`docs/RELEASE_FLOW.md`参照)。ローカルには
      作成済みだが、push・GitHubのDefault branch変更・`main`のブランチ保護はまだ
- [ ] `docs/HANDOVER.md` §6 未決事項の #3〜#5(フリップ実装方式・例文の可変数・履歴の表示内容)は
      実装時に妥当な側で進めた。TKの確認を推奨
