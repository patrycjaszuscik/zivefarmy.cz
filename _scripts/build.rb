# encoding: utf-8
# Wraps the artifact fragment in a real document and writes index.html at the repo root.
root = File.expand_path("..", __dir__)
frag = File.read(File.join(root, "_src", "czech-farm-atlas.html"), encoding: "UTF-8")
desc = "Mapa bio a regenerativnich farem v Cesku - kde nakoupit primo od farmare."
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
