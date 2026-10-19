# App Store掲載画像

App Store Connect にアップロードするスクリーンショットの作り方。**方式B(見出し+電話フレーム)を
採用**(2026-10-14、TK指示により`readygo-speak`と同じ方式に変更。Android版
[docs/PLAY_STORE_ASSETS.md](PLAY_STORE_ASSETS.md)は方式Aのまま)。

## サイズ

> **2026-10-14更新: 必須サイズが変わっていた。** 2026-10-03時点の情報(「6.9インチクラス」
> 1320×2868があれば他は自動生成)は古くなっており、App Store Connectへのアップロード時に
> `File dimensions are invalid` エラーになった(`readygo-speak`でも同じ問題が発生、
> 2026-10-14の提出で判明)。**現在の必須サイズは「Dynamic Island搭載・mediumディスプレイ」=
> 1179×2556**(公式: [Screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/))。
> 旧サイズ(1320×2868、6.9インチ/Dynamic Island large)は**オプション**扱いになっている。
> iPhone 16 / iPhone 14 Proのシミュレータがちょうど1179×2556になる。
> **App Store Connectには`scripts/store-assets/out/framed-ios-1179/`をアップロードすること**
> (1320×2868版の`out/framed-ios/`は任意、入れても入れなくてもよい)。
> iPadには対応していないため、iPad用スクリーンショットは不要

## 書き出し済みの画像

元スクショ(2026-10-13撮影の1320×2868版は`scripts/store-assets/raw-ios/`、2026-10-14撮影の
1179×2556版=必須サイズは`scripts/store-assets/raw-ios-1179/`。画面・見出しコピーはどちらも共通):

| # | ファイル | 画面 | 見出し(方式Bのコピー) |
|---|---|---|---|
| 1 | `1-home.png` | レベル選択(起動直後) | TOEICレベルを選んで、めくるだけ。 |
| 2 | `2-mode.png` | モード選択(学習/復習) | 学習と復習、ワンタップで切り替え。 |
| 3 | `3-card-phrasal.png` | カード・句動詞(1320版: call off、1179版: help out。意味+例文3件) | 知ってる単語なのに、意味が出てこない。 |
| 4 | `4-card-word.png` | カード・単語(1320版: achieve、1179版: currency) | 句動詞・熟語だけじゃない、単語も。 |
| 5 | `5-home-highlighted.png` | レベル選択(前回選択レベルがハイライト表示) | 前回のレベルを、ハイライト表示。 |
| 6 | `6-history.png` | 履歴(レベル別の内訳+最近の学習) | わからなかった分だけ、ちゃんと復習。 |

**App Store Connectにアップロードするのは`scripts/store-assets/out/framed-ios-1179/`
(1179×2556、必須)。** `out/framed-ios/`(1320×2868、オプション)も作成済みで、入れても入れなくてもよい。
いずれも方式B(見出し+電話フレーム付き)。生成は`render-ios-1179.sh`・`render-ios.sh`
(`screenshot-ios-1179.html`・`screenshot-ios.html`をヘッドレスChromeで開いて書き出す、
`readygo-speak`の`render.sh`と同じ方式)。生スクショのみの方式A版も`out/raw-ios-1179/`・
`out/raw-ios/`に同時出力している(未使用)。

**ヘッドレスChromeがまれに無反応になりタイムアウトすることがある**(1回の`render-ios-1179.sh`実行中に
発生済み)。`timeout`コマンド+バックグラウンド実行で強制終了し、失敗した分だけ再実行すれば問題ない。
なお、このマシンのデフォルトシェルはzshで、**zshの配列は1-indexed**(bashは0-indexed)。
`render-ios*.sh`は`#!/bin/bash`シェバンで書いてあるので`./render-ios-1179.sh`のように実行すれば
問題ないが、同じロジックをzshの対話シェルに直接貼り付けて実行すると出力ファイル名が1つずつずれる
(実際に一度やってしまい、`screenshot-4-card-phrasal.png`等の誤った名前のファイルができたため削除した)。

Play Store版([docs/PLAY_STORE_ASSETS.md](PLAY_STORE_ASSETS.md))の#5は起動直後の「通信中」表示を
狙ったものだったが、ローカルAPIが速すぎて撮影手段(起動直後にスクリーンショット)では再現できなかった
ため、代わりに「前回選択レベルがハイライトされた状態」を採用した【提案】。機能説明上はこちらの方が
伝わりやすい(「選び直しの手間が減る」仕様、`docs/HANDOVER.md` 2.1章)。

アプリアイコンは`assets/branding/`のPhraseロゴ(Pマーク)がそのままビルドに反映されている。
タブレット用スクリーンショット・プロモーション動画はv1では用意しない。

## 撮影手順(2026-10-13実施)

1. `readygo-speak-api`をローカルでdocker compose起動(`docker compose up -d`)。
   起動直後は`tmp/pids/server.pid`が前回コンテナのPIDを指したまま残っていて
   `A server is already running`で起動に失敗することがある。その場合はこのファイルの中身を
   明らかに無効な値(`999999`など)に書き換えてから`docker compose up -d web`をやり直すとよい
2. `docker compose exec web bin/rails app_config:set APP=phrase KEY=ads_enabled VALUE=false`で
   テスト広告が写り込まないようにする(撮影後`VALUE=true`で戻す)
3. iPhone 16 Pro Maxシミュレータ(UDID確認は`xcrun simctl list devices`)を起動
4. `flutter build ios --simulator --debug --dart-define=API_BASE_URL=http://localhost:3001`でビルド
   (iOSシミュレータは`localhost`で直接ホストのAPIに届くため、Androidエミュレータのような
   `10.0.2.2`読み替えは不要)
5. `xcrun simctl install`→`xcrun simctl launch`でインストール・起動
6. ステータスバーをApple標準の見た目に揃える
   (`xcrun simctl status_bar <UDID> override --time "9:41" --dataNetwork wifi --wifiMode active --wifiBars 3 --cellularMode active --cellularBars 4 --batteryState charged --batteryLevel 100`。
   撮り終わったら`xcrun simctl status_bar <UDID> clear`で戻す)
7. アプリ内の操作は`mcp__Claude_Code_iOS_Simulator__control`(タップ・スクリーンショット)。
   `inspect`アクションがこのアプリでは使えなかった(Flutter側のアクセシビリティツリーの出方による
   可能性がある)ため、ボタン位置は`screenshot`で得たプレビュー画像の表示倍率(`displayed ×1.43 = 原寸`)
   をもとに原寸ピクセル→デバイスポイント(原寸÷3、iPhone 16 Pro Maxは3倍スケール)へ変換して特定した
8. 各画面を`xcrun simctl io <UDID> screenshot`で`scripts/store-assets/raw-ios/`に直接1320×2868で保存
   (iOSのスクショはステータスバー・ホームインジケータ込みでそのまま使えるので、Androidのような
   バー切り落とし加工は不要)
9. `scripts/store-assets/render-ios.sh`を実行し、`screenshot-ios.html`(Android版`screenshot.html`の
   iOS移植版。キャンバス1320×2868、電話フレームの比率をiPhoneの実際の縦横比に合わせてある)を
   ヘッドレスChromeで開いて`out/framed-ios/`・`out/raw-ios/`に書き出す。見出しコピーは上表参照

履歴画面(#6)は真っさらな新規匿名ユーザーだと棒グラフがほぼ見えないため、レベル中のカードを
10件ほど「覚えている」「わからない」で学習してから撮影した。

## 1179×2556版の撮影(2026-10-14実施)

手順は1320×2868版と同じ(上記1〜8)。異なる点のみ記載:

- iPhone 16シミュレータ(UDID確認は`xcrun simctl list devices`)を使う。コーディネート空間は
  393×852pt(3倍スケール、1179÷3=393・2556÷3=852)。1320×2868版で測ったタップ座標(pt単位)に
  ×0.892を掛ければ流用できる(393/440≈0.893・852/956≈0.891、ほぼ一様倍率)
- **句動詞・熟語の出現は完全にランダム**(`lib/screens/card_screen.dart`の`queue = List.of(entries)..shuffle()`。
  サーバー側はID順=アルファベット順で返すが、クライアント側で毎回シャッフルしている)。
  レベル中・低とも単語(word)の構成比が8割前後(`Phrase::Entry.where(level: ...).group(:kind).count`
  で確認可能)のため、句動詞/熟語カードに当たるまで10〜20回前後「覚えている」をタップし続ける
  覚悟が必要。今回はレベル低で14回目にようやく句動詞(help out)に当たった
- 履歴画面はレベル低・中の両方で学習してから撮影(両レベルのグラフが見えるように)

## App Privacy(データ収集申告)の裏付け(2026-10-14追記)

`docs/APP_STORE_LISTING.md`の「App Privacy」章は、ビルド(`flutter build ipa --release`)に実際に
含まれるSDKの`PrivacyInfo.xcprivacy`マニフェストを読んで検証済み
(`build/ios/archive/Runner.xcarchive/Products/Applications/Runner.app/Frameworks/
GoogleMobileAds.framework/PrivacyInfo.xcprivacy`・`UserMessagingPlatform.framework/同`、
`plutil -convert xml1 -o - <path>`で中身を確認できる)。推測で埋めず、ここを根拠にすること
(`readygo-speak`の提出時のノウハウ、2026-10-14)。

## 未決・要対応

- アプリアイコン以外のブランド素材(起動画面等)は`CLAUDE.md`の「ブランド・デザインシステム」章の
  とおり未着手のまま
