# encoding: utf-8
# Wraps the artifact fragment in a real document and writes index.html at the repo root.
root = File.expand_path("..", __dir__)
frag = File.read(File.join(root, "_src", "czech-farm-atlas.html"), encoding: "UTF-8")
# Entities, not bare ASCII: this string is what Google prints under the
# result, and stripping the diacritics made it read as broken Czech.
desc = "Mapa bio a regenerativn&#237;ch farem v &#268;esku &#8212; kde nakoupit maso, ml&#233;ko, vejce a zeleninu p&#345;&#237;mo od farm&#225;&#345;e."
head = <<~HTML
  <!doctype html>
  <html lang="cs">
  <head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <meta name="description" content="#{desc}">
  <link rel="canonical" href="https://zivefarmy.cz/">
  <meta property="og:type" content="website">
  <meta property="og:url" content="https://zivefarmy.cz/">
  <meta property="og:title" content="&#381;iv&#233; farmy">
  <meta property="og:description" content="#{desc}">
  <meta name="twitter:card" content="summary">
  <link rel="icon" href="data:image/svg+xml,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'><text y='.9em' font-size='90'>&#127806;</text></svg>">
  </head>
  <body>
HTML
out = head + frag.sub(/\A<meta charset="utf-8">\s*/, "") + "\n</body>\n</html>\n"
File.write(File.join(root, "index.html"), out)
puts "build: index.html #{(out.bytesize/1024.0).round(1)} KB, farms #{frag.scan(/id:"[a-z0-9_-]*"/).length}"
