#!/bin/sh
# Build and publish zivefarmy.cz.
#   ./_scripts/deploy.sh "what changed"
#
# Edits go into _src/czech-farm-atlas.html. This turns that into index.html,
# then regenerates the crawlable pages from the very same data so the two can
# never drift apart -- a farm added to the map but missing from /farma/ would
# be invisible to search engines and AI crawlers, and a farm removed from the
# map would linger on a page nobody maintains.
#
# Directories starting with _ are not served by GitHub Pages, so the public
# site is index.html, CNAME, og.png, pages.css, robots.txt, sitemap.xml and
# the generated farmy/ farma/ kraj/ co-koupit/ trees.
set -e
cd "$(dirname "$0")/.."
ruby _scripts/asciify.rb
ruby _scripts/build.rb

# Regenerating needs Chrome, because the farm data is read back out of the
# page's own JavaScript. Better to stop than to publish stale farm pages.
if [ ! -x "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" ]; then
  echo "Google Chrome not found - cannot refresh the farm pages." >&2
  echo "Install Chrome, or deploy by hand if you are certain the farm data did not change." >&2
  exit 1
fi
./_scripts/dump-farms.sh
ruby _scripts/make-pages.rb
ruby _scripts/build.rb   # the homepage counts farms, so rebuild after the dump

# The share picture carries the farm count and a dot per farm, so it is
# generated from the same data. Re-rendering the PNG is only worth it when the
# card itself actually changed.
ruby _scripts/make-og-card.rb
if ! git diff --quiet -- _og/card.html; then
  ./_scripts/make-og.sh
fi

if [ -z "$(git status --porcelain)" ]; then
  echo "nothing changed - nothing to publish"
else
  git add -A
  git status --short | head -20
  n=$(git status --porcelain | wc -l | tr -d ' ')
  [ "$n" -gt 20 ] && echo "  ... and $((n - 20)) more"
  git commit -m "${1:-Update map}"
  git push
  echo "pushed - live in a minute or two at https://zivefarmy.cz/"
fi
