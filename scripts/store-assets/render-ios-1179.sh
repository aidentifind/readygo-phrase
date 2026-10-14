#!/bin/bash
# App Store掲載画像(1179×2556、Dynamic Island mediumクラス、Apple必須サイズ)を書き出す
# (docs/APP_STORE_ASSETS.md)。render-ios.sh の1179版。
set -euo pipefail

cd "$(dirname "$0")"
CHROME="${CHROME:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}"
OUT=out
mkdir -p "$OUT/framed-ios-1179" "$OUT/raw-ios-1179"

shoot() { # <html?query> <幅> <高さ> <出力>
  timeout 20 "$CHROME" --headless=new --disable-gpu --hide-scrollbars --force-device-scale-factor=1 \
    --allow-file-access-from-files --virtual-time-budget=10000 \
    --window-size="$2,$3" --screenshot="$PWD/$4" "file://$PWD/$1" 2>/dev/null
  echo "$4"
}

names=(home mode card-phrasal card-word home-highlighted history)
for i in 1 2 3 4 5 6; do
  n="${names[$((i - 1))]}"
  [ -f "raw-ios-1179/$i-$n.png" ] || { echo "skip $i (raw-ios-1179/$i-$n.png がない)"; continue; }
  name="screenshot-$i-$n.png"
  shoot "screenshot-ios-1179.html?shot=$i&mode=framed" 1179 2556 "$OUT/framed-ios-1179/$name"
  shoot "screenshot-ios-1179.html?shot=$i&mode=raw" 1179 2556 "$OUT/raw-ios-1179/$name"
done
