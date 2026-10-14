# App Store掲載画像

App Store Connect にアップロードするスクリーンショットの作り方。**方式B(見出し+電話フレーム)を
採用**(2026-10-14、TK指示により`readygo-speak`と同じ方式に変更。Android版
[docs/PLAY_STORE_ASSETS.md](PLAY_STORE_ASSETS.md)は方式Aのまま)。

## サイズ

Appleは2026-10-03時点で「6.9インチクラス」(iPhone 16 Pro Max相当、1320×2868)のスクリーンショットが
あれば、それより小さいiPhoneの表示にはApp Store Connect側で自動的に使い回される
(6.5インチクラス等を個別に用意する必要はない)。iPhone 16 Pro Maxのシミュレータはこのサイズと
ちょうど一致するため、追加の拡大縮小なしでそのまま使える。

## 書き出し済みの画像

元スクショ(`scripts/store-assets/raw-ios/`、2026-10-13撮影):

| # | ファイル | 画面 | 見出し(方式Bのコピー) |
|---|---|---|---|
| 1 | `1-home.png` | レベル選択(起動直後) | TOEICレベルを選んで、めくるだけ。 |
| 2 | `2-mode.png` | モード選択(学習/復習) | 学習と復習、ワンタップで切り替え。 |
| 3 | `3-card-phrasal.png` | カード・句動詞(call off、意味+例文3件) | 知ってる単語なのに、意味が出てこない。 |
| 4 | `4-card-word.png` | カード・単語(achieve) | 句動詞・熟語だけじゃない、単語も。 |
| 5 | `5-home-highlighted.png` | レベル選択(前回選択=レベル中がハイライト表示) | 前回のレベルを、ハイライト表示。 |
| 6 | `6-history.png` | 履歴(レベル別の内訳+最近の学習2件) | わからなかった分だけ、ちゃんと復習。 |

App Store Connectにアップロードする完成画像(`scripts/store-assets/out/framed-ios/`、方式B・
見出し+電話フレーム付き、1320×2868)は`scripts/store-assets/render-ios.sh`で生成
(`screenshot-ios.html`をヘッドレスChromeで開いて書き出す、`readygo-speak`の`render.sh`と同じ方式)。
生スクショのみの方式A版も`scripts/store-assets/out/raw-ios/`に同時出力している(未使用)。

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

## 未決・要対応

- アプリアイコン以外のブランド素材(起動画面等)は`CLAUDE.md`の「ブランド・デザインシステム」章の
  とおり未着手のまま
