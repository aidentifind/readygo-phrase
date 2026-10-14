#!/bin/bash
# App Store掲載画像を書き出す(docs/APP_STORE_ASSETS.md)。
# ヘッドレスChromeで screenshot-ios.html を開いてスクリーンショットを撮るだけ(readygo-speakの
# render.sh と同じ方式)。書体はGoogle Fontsから読むため、ネットワークに繋がっている必要がある。
set -euo pipefail

cd "$(dirname "$0")"
CHROME="${CHROME:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}"
OUT=out
mkdir -p "$OUT/framed-ios" "$OUT/raw-ios"

shoot() { # <html?query> <幅> <高さ> <出力>
  timeout 20 "$CHROME" --headless=new --disable-gpu --hide-scrollbars --force-device-scale-factor=1 \
    --allow-file-access-from-files --virtual-time-budget=10000 \
    --window-size="$2,$3" --screenshot="$PWD/$4" "file://$PWD/$1" 2>/dev/null
  echo "$4"
}

names=(home mode card-phrasal card-word home-highlighted history)
for i in 1 2 3 4 5 6; do
  n="${names[$((i - 1))]}"
  [ -f "raw-ios/$i-$n.png" ] || { echo "skip $i (raw-ios/$i-$n.png がない)"; continue; }
  name="screenshot-$i-$n.png"
  shoot "screenshot-ios.html?shot=$i&mode=framed" 1320 2868 "$OUT/framed-ios/$name"
  shoot "screenshot-ios.html?shot=$i&mode=raw" 1320 2868 "$OUT/raw-ios/$name"
done
