#!/bin/sh
# Build and publish zivefarmy.cz.
#   ./_scripts/deploy.sh "what changed"
# Edits go into _src/czech-farm-atlas.html; this turns that into index.html
# and pushes. Directories starting with _ are not served by GitHub Pages,
# so the public site stays index.html + CNAME.
set -e
cd "$(dirname "$0")/.."
ruby _scripts/asciify.rb
ruby _scripts/build.rb
if git diff --quiet -- index.html; then
  echo "no change to index.html - nothing to publish"
else
  git add -A
  git commit -m "${1:-Update map}"
  git push
  echo "pushed - live in a minute or two at https://zivefarmy.cz/"
fi
