#!/bin/sh
# Build and publish zivefarmy.cz.
#   ./_scripts/deploy.sh "what changed"
# Edits go into _src/czech-farm-atlas.html; this turns that into index.html
# and pushes. Directories starting with _ are not served by GitHub Pages,
# so the public site stays index.html + CNAME + the few root assets
# (og.png, robots.txt, sitemap.xml).
set -e
cd "$(dirname "$0")/.."
ruby _scripts/asciify.rb
ruby _scripts/build.rb
# Anything in the working tree counts, not just index.html: assets like
# og.png change without the page changing, and used to be left behind.
if [ -z "$(git status --porcelain)" ]; then
  echo "nothing changed - nothing to publish"
else
  git add -A
  git status --short
  git commit -m "${1:-Update map}"
  git push
  echo "pushed - live in a minute or two at https://zivefarmy.cz/"
fi
