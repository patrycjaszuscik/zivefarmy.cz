#!/bin/sh
# Dump the map's own FARMS array to _og/farms.json.
#   ./_scripts/dump-farms.sh
# FARMS lives inside the page's IIFE, so it cannot be read from outside. A
# throwaway copy of index.html gets a one-line hook injected that serialises
# the array into the DOM; headless Chrome runs it and we read the result back.
# The real source is never touched and the data is never re-typed by hand.
set -e
cd "$(dirname "$0")/.."
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
[ -x "$CHROME" ] || { echo "Google Chrome not found"; exit 1; }
[ -f index.html ] || { echo "run _scripts/build.rb first"; exit 1; }
tmp=$(mktemp -d)
ruby -e '
src = File.read("index.html", encoding: "UTF-8")
needle = "FARMS = FARMS.concat(MORE_FARMS);"
abort("MISS: concat line not found - did the source change?") unless src.include?(needle)
hook = needle + %q{ try{var __d=document.createElement("pre");__d.id="__dump";__d.textContent=JSON.stringify(FARMS);document.documentElement.appendChild(__d);}catch(e){document.title="DUMPFAIL";}}
File.write(ARGV[0] + "/probe.html", src.sub(needle, hook))
' "$tmp"
"$CHROME" --headless=new --disable-gpu --no-sandbox --virtual-time-budget=8000 \
  --dump-dom "file://$tmp/probe.html" > "$tmp/dom.html" 2>/dev/null
ruby _scripts/extract-farms.rb "$tmp/dom.html" _og/farms.json
rm -rf "$tmp"
