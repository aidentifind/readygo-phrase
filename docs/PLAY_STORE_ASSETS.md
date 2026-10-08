# Play ストア掲載画像

`readygo-speak/docs/PLAY_STORE_ASSETS.md`と同じ方式(方式A: 生スクショ。見出し+電話フレームの
「方式B」はここでは作っていない)。Google Playは最低2枚・最大8枚、長辺が短辺の2倍までという
制約がある。1080×1920(端末の実際の比率そのまま)で用意した。

## 書き出し済みの画像(`scripts/store-assets/raw/`)

| # | ファイル | 画面 | 見出し案 |
|---|---|---|---|
| 1 | `1-home.png` | レベル選択(起動直後) | TOEICレベルを選んで、めくるだけ。 |
| 2 | `2-mode.png` | モード選択(学習/復習) | 学習と復習、ワンタップで切り替え。 |
| 3 | `3-card-phrasal.png` | カード・句動詞(cut down on、意味+例文3件) | 知ってる単語なのに、意味が出てこない。 |
| 4 | `4-card-word.png` | カード・単語(announcement) | 句動詞・熟語だけじゃない、単語も。 |
| 5 | `5-home-syncing.png` | レベル選択(「通信中」表示付き) | 通信中もひと目でわかる |
| 6 | `6-history.png` | 履歴(レベル別の内訳+最近の学習) | わからなかった分だけ、ちゃんと復習。 |

アプリアイコン(512×512)は`assets/branding/play-store-icon-512.png`をそのまま使う。
タブレット用スクリーンショット・プロモーション動画はv1では用意しない。
フィーチャーグラフィック(1024×500)は`scripts/store-assets/feature-graphic.html`から
ヘッドレスChromeで書き出し済み(`out/feature-graphic-1024x500.png`、Speakの`render.sh`と同じ
コマンドで作成。書き出しスクリプト自体はPhrase側はまだ1枚だけなので`render.sh`化していない)。

## 撮影手順(2026-10-09実施)

1. `docker compose exec web bin/rails runner`で`phrase.ads_enabled`を一時的に`false`にする
   (テスト広告が写り込まないように。撮影後に`true`へ戻す)
2. Androidエミュレータ(`Pixel_9` AVD)を起動し、画面サイズをPlayの縦横比制約に収まるよう
   `adb shell wm size 1080x2120`に変更(Pixel 9の実機比率9:20.2は長辺が短辺の2倍を超えるため
   そのままでは使えない。撮影後は`adb shell wm size reset`で戻す)
3. `flutter run -d <emulator> --dart-define=API_BASE_URL=http://10.0.2.2:3001`でインストール・起動
4. `adb exec-out screencap -p`で各画面を撮影。ステータスバー137px・ナビゲーションバー63pxを
   Pythonで切り落として1080×1920にする(`adb shell dumpsys window | grep InsetsSource`で
   高さを確認できる。Speak側と同じ値だった)
5. 履歴画面(#6)は空だと棒グラフが出ないため、レベル中を何回か「覚えている」「わからない」で
   学習してから撮った

## 未決・要対応

- 方式B(見出し+電話フレーム)にするかどうかは未決(Speakは方式Bを採用済み。Phraseもヘッドレス
  Chromeでの書き出しスクリプトを作れば同じ見た目にできるが、v1では未着手)
- iOS(App Store Connect)向けの6.9インチクラス書き出しは未着手
  (`readygo-speak/docs/APP_STORE_ASSETS.md`参照、同じ要領でできるはず)
- 4枚目(ロック中の通知相当)は該当機能が無いため対象外(Phraseはバックグラウンド再生をしない設計)
