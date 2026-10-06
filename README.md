# ReadyGo Phrase

句動詞・熟語・単語学習アプリ。[ReadyGo Speak](https://github.com/aidentifind/readygo-speak) の
スピンオフで、バックエンド([readygo-speak-api](https://github.com/aidentifind/readygo-speak-api))を
共有している。仕様は [`docs/HANDOVER.md`](docs/HANDOVER.md)、開発方針は [`CLAUDE.md`](CLAUDE.md) を参照。

## セットアップ

このリポジトリには `lib/`・`pubspec.yaml`・`test/` などDartのソース一式のみが揃っており、
Flutterのネイティブプロジェクト一式(`android/`・`ios/`ディレクトリ)はまだ生成していない
(作業環境にFlutter SDKが無く `flutter create` が実行できなかったため)。**初回だけ、以下の手順で
ネイティブプロジェクトを生成してから使うこと。**

```bash
# 1. リポジトリのルートで、android/・iosディレクトリだけを生成する
#    (pubspec.yaml・lib/・test/は既にあるので上書きされない。org/project-nameは
#    readygo-speakの命名規則(space.readygo_english.<アプリ名>)に合わせている)
flutter create --org space.readygo-english --project-name readygo_phrase --platforms=android,ios .

# 2. 依存パッケージを取得
flutter pub get

# 3. テストを実行(実ネットワークには依存しない。MockClientで readygo-speak-api を模擬している)
flutter test

# 4. ローカルのreadygo-speak-api(docker compose up、ホスト側ポート3001)に向けて起動
#    Androidエミュレータは 10.0.2.2 でホストマシンに到達する
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3001   # Android実機/エミュレータ
flutter run                                                     # iOSシミュレータ・macOS(localhostで届く)
```

`flutter create` の後、以下は手動での確認・調整が必要(readygo-speakでの実績を踏まえた注意点):

- **Android**: リリースビルドの `AndroidManifest.xml` に `INTERNET` 権限があるか確認する
  (readygo-speakでは debug/profile にしか無く、リリースビルドがAPIに繋がらない不具合があった)。
  `applicationId` は `lib/config/app_config.dart` の想定パッケージ名(`space.readygo_english.phrase`)
  と合わせる
- **iOS**: Bundle ID は `space.readygo-english.phrase`(ハイフン、readygo-speakと同じ命名規則)。
  App Transport Security(ATS)はデバッグ時の `http://localhost:3001` 通信のため、
  ローカル開発中は例外設定が必要になる場合がある
- **アプリアイコン・起動画面**: ReadyGo Phrase専用のロゴはまだデザインしていない
  (`CLAUDE.md`「ブランド・デザインシステム」参照)。`flutter create` が生成する既定のFlutterアイコンの
  ままなので、ロゴ確定後に差し替えること

## ディレクトリ構成

```
lib/
  config/      静的設定(app_config.dart)
  data/        リポジトリ層(API・ローカル永続化)。readygo-speakと同じ
               「static instanceシングルトン + ValueNotifier」の型を踏襲
  models/      データモデル(手書きJSONパース。コード生成ツールは使わない)
  screens/     画面(レベル選択/モード選択/カード/履歴/設定)
  theme/       カラー・テーマ(readygo-speakのSpeak Aブランドトークンを流用)
  widgets/     再利用ウィジェット
  main.dart
test/
  data/        リポジトリ層のユニットテスト(http/testingのMockClientで実ネットワーク不使用)
  widget_test.dart
```

readygo-speakの構成・命名規則に揃えている。詳しい設計判断は各ファイルのコメントと
`docs/HANDOVER.md` を参照。

## バックエンド(readygo-speak-api)

コンテンツ(`GET /api/v1/phrase/entries`)・匿名ユーザー(`POST /api/v1/users`、Speakと共有)・
学習記録(`POST /api/v1/phrase/study_sessions` 等)は `readygo-speak-api` から取得する。
ローカル開発は `readygo-speak-api` 側で `docker compose up` しておくこと
(`readygo-speak-api/README.md` 参照)。

現時点でDBに入っているPhraseのコンテンツは動作確認用のサンプル9件のみ
(`readygo-speak-api/db/seed_data/phrase/entries_v1.json`)。本番投入分の作り方は
`docs/HANDOVER.md` 3.1章を参照。
