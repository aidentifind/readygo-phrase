# ReadyGo Phrase ブランドアセット

シリーズ頭文字ロゴ(Phrase = P)。カラー: グラデーション `#FF6A1F` → `#FF1E88`(135°)/
Ink `#16141F` / 前傾 -5°。ロゴ確定日: 2026-09-26。元データは`readygo-phrase-icon-assets.zip`
(TKからの支給、このフォルダにはそのうちアプリアイコン生成後に残す価値がある素材のみを置く)。

## ファイル一覧

| ファイル | 用途 |
|---|---|
| `mark-ink-1024.png` / `mark-ink.svg` | 単色マーク(Ink)、背景透過。スプラッシュ・資料等に |
| `mark-white-1024.png` / `mark-white.svg` | 単色マーク(白)、背景透過 |
| `icon-rounded-1024.png` / `icon-rounded.svg` | 角丸アイコン。Web・資料用 |
| `icon-fullbleed.svg` | フルブリード(角丸なし)。ストアアイコンの元SVG |
| `play-store-icon-512.png` | Google Play用 512×512(生成済み、フルブリード。角丸はストア側で付与) |
| `app-store-icon-1024.png` | App Store用 1024×1024(生成済み、透過なし) |
| `adaptive/ic_launcher_background.svg` | Androidアダプティブアイコン背景レイヤーの元SVG |
| `adaptive/ic_launcher_foreground.svg` | Androidアダプティブアイコン前景レイヤーの元SVG(66dpセーフゾーン内) |
| `adaptive/ic_launcher_monochrome.svg` | Android 13+ テーマアイコン用モノクロレイヤーの元SVG |

ランチャーアイコン生成用のラスター素材(`icon-1024.png`・`adaptive-{background,foreground,monochrome}.png`)は
`../icon/`に置いてあり、`flutter_launcher_icons.yaml`(プロジェクト直下)が参照する。

## 運用ルール

- マーク周囲に十分な余白を確保すること
- グラデーションの角度(135°、左上が`#FF6A1F`)と色順は変更しないこと
- 前傾角-5°は固定
- 単色版はInk(`#16141F`)または白(`#FFFFFF`)のみ。中間グレー不可

## アプリへの適用(2026-09-26)

`dart run flutter_launcher_icons`で以下に反映済み:

| 使う場所 | 配置先 |
|---|---|
| Androidランチャーアイコン(8+、アダプティブ+モノクロ) | `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml` + `drawable-*/ic_launcher_{background,foreground,monochrome}.png` |
| Androidランチャーアイコン(7以前) | `android/app/src/main/res/mipmap-*/ic_launcher.png` |
| iOSのアプリアイコン | `ios/Runner/Assets.xcassets/AppIcon.appiconset/*.png`(20〜1024px) |

ロゴを変える場合は`../icon/`のPNGを差し替えてから`dart run flutter_launcher_icons`を再実行する。

## 未対応

- 起動画面(スプラッシュ)は未着手。Flutterのデフォルトのまま(`CLAUDE.md`参照)
- アプリ内のプレースホルダー(`Icons.style_rounded`)をこのマークに差し替えるかは未検討
