# encoding: utf-8
# Wraps the artifact fragment in a real document and writes index.html at the repo root.
root = File.expand_path("..", __dir__)
frag = File.read(File.join(root, "_src", "czech-farm-atlas.html"), encoding: "UTF-8")
# Entities, not bare ASCII: this string is what Google prints under the
# result, and stripping the diacritics made it read as broken Czech.
desc = "Mapa bio a regenerativn&#237;ch farem v &#268;esku &#8212; kde nakoupit maso, ml&#233;ko, vejce a zeleninu p&#345;&#237;mo od farm&#225;&#345;e."
title = "&#381;iv&#233; farmy"
# The picture shown when the link is shared. Scrapers cache it by URL for a
# long time, so a genuinely different picture gets a new filename rather than
# overwriting this one. Rebuild with _scripts/make-og.sh.
og_image = "https://zivefarmy.cz/og.png"
og_alt = "Mapa &#268;eska s vyzna&#269;en&#253;mi bio a regenerativn&#237;mi farmami"
head = <<~HTML
  <!doctype html>
  <html lang="cs">
  <head>
  <meta charset="utf-8">
  <title>#{title}</title>
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <meta name="description" content="#{desc}">
  <link rel="canonical" href="https://zivefarmy.cz/">
  <meta property="og:type" content="website">
  <meta property="og:url" content="https://zivefarmy.cz/">
  <meta property="og:site_name" content="#{title}">
  <meta property="og:title" content="#{title}">
  <meta property="og:description" content="#{desc}">
  <meta property="og:locale" content="cs_CZ">
  <meta property="og:image" content="#{og_image}">
  <meta property="og:image:secure_url" content="#{og_image}">
  <meta property="og:image:type" content="image/png">
  <meta property="og:image:width" content="1200">
  <meta property="og:image:height" content="630">
  <meta property="og:image:alt" content="#{og_alt}">
  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:title" content="#{title}">
  <meta name="twitter:description" content="#{desc}">
  <meta name="twitter:image" content="#{og_image}">
  <meta name="twitter:image:alt" content="#{og_alt}">
  <link rel="icon" href="data:image/svg+xml,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'><text y='.9em' font-size='90'>&#127806;</text></svg>">
  </head>
  <body>
HTML
# The fragment opens with its own charset meta and <title>; both belong in the
# head this script writes, so they are lifted out rather than left in the body.
body = frag.sub(/\A<meta charset="utf-8">\s*/, "").sub(/\A<title>.*?<\/title>\s*/m, "")
out = head + body + "\n</body>\n</html>\n"
File.write(File.join(root, "index.html"), out)
puts "build: index.html #{(out.bytesize/1024.0).round(1)} KB, farms #{frag.scan(/id:"[a-z0-9_-]*"/).length}"
