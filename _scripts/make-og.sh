#!/bin/sh
# Rebuild the social preview picture (og.png) from _og/card.html.
#   ./_scripts/make-og.sh
# The card is rendered by headless Chrome at 2x and downsampled, so the text
# stays crisp. Czechia and the 91 pins in the card are the real map geometry,
# lifted from _src/czech-farm-atlas.html by _scripts/make-og-card.sh.
#
# Scrapers (Facebook, Slack, WhatsApp) cache a preview image by URL for a long
# time. If the picture changes meaningfully, publish it under a NEW name and
# point og:image at that, rather than overwriting this one.
set -e
cd "$(dirname "$0")/.."
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
[ -x "$CHROME" ] || { echo "Google Chrome not found at $CHROME"; exit 1; }
tmp=$(mktemp -d)
"$CHROME" --headless=new --disable-gpu --hide-scrollbars --no-sandbox \
  --force-device-scale-factor=2 --window-size=1200,630 \
  --screenshot="$tmp/card@2x.png" "file://$PWD/_og/card.html" 2>/dev/null
cp "$tmp/card@2x.png" og.png
sips --resampleHeightWidth 630 1200 og.png >/dev/null
rm -rf "$tmp"
sips -g pixelWidth -g pixelHeight og.png | tail -2
ls -l og.png | awk '{printf "og.png %.0f KB\n", $5/1024}'
