# encoding: utf-8
# Generates the crawlable half of zivefarmy.cz.
#
# The map itself builds all 91 farms in JavaScript, which means search engines
# that do not run JS -- and that is most AI crawlers (GPTBot, ClaudeBot,
# PerplexityBot) -- see an empty page. This script writes the same data out as
# plain HTML so the farms can actually be read, quoted and indexed:
#
#   /farmy/                 every farm, grouped by region   (hub)
#   /farma/<id>/            one page per farm               (91)
#   /kraj/<slug>/           farms in one region             (14)
#   /co-koupit/<cat>/       farms by what they sell          (5)
#
# Input is _og/farms.json, dumped from the page's own FARMS array by
# _scripts/dump-farms.sh -- the data is never re-typed or parsed by hand.
require "json"
require "cgi"
require "date"
require "fileutils"

ROOT  = File.expand_path("..", __dir__)
SITE  = "https://zivefarmy.cz"
TODAY = Date.today.to_s
farms = JSON.parse(File.read(File.join(ROOT, "_og", "farms.json"), encoding: "UTF-8"))

CATS = {
  "meat"    => "Maso",
  "dairy"   => "Mléko a sýry",
  "eggs"    => "Vejce a drůbež",
  "veggies" => "Zelenina a plodiny",
  "honey"   => "Med",
}
CAT_INTRO = {
  "meat"    => "Hovězí, vepřové, jehněčí i drůbež z pastevních chovů. U masa se vyplatí ptát se na dobu zrání a na to, jestli farma bourá sama.",
  "dairy"   => "Čerstvé mléko, sýry, jogurty a tvaroh z vlastních stád. Část farem má mléčný automat, část prodává jen v otevírací době mlékárny.",
  "eggs"    => "Vejce ze pastvy a z mobilních kurníků, u většiny farem i drůbež. Klecové chovy na této mapě nenajdete.",
  "veggies" => "Zelenina, ovoce, brambory a obiloviny. Hodně z toho je sezonní, takže se nabídka v průběhu roku mění.",
  "honey"   => "Med od farem, které vedle něj hospodaří i na poli nebo na pastvě.",
}
CHANNELS = { "scuk" => "Scuk.cz", "rohlik" => "Rohlík.cz", "kosik" => "Košík.cz", "sklizeno" => "Sklizeno.cz" }
DELIVERY = { "praha" => "Rozvoz do Prahy", "brno" => "Rozvoz do Brna", "ostrava" => "Rozvoz po Ostravě",
             "cr" => "Rozvoz po celé ČR", "pickup" => "Jen osobní odběr" }
OFFERS   = { "bedynky" => "bedýnky", "samosber" => "samosběr", "bistro" => "bistro",
             "automat" => "prodejní automat", "kpz" => "KPZ (komunitou podporované zemědělství)",
             "tours" => "exkurze", "mobile" => "pojízdná prodejna" }

# Czech declines, so a region name cannot just be dropped after a preposition:
# "farmy v Zlínský kraj" is broken Czech. These are the locative forms, with
# the preposition baked in because it changes too (v / ve / na).
LOC = {
  "Hlavní město Praha"    => "v Praze",
  "Středočeský kraj"      => "ve Středočeském kraji",
  "Jihočeský kraj"        => "v Jihočeském kraji",
  "Plzeňský kraj"         => "v Plzeňském kraji",
  "Karlovarský kraj"      => "v Karlovarském kraji",
  "Ústecký kraj"          => "v Ústeckém kraji",
  "Liberecký kraj"        => "v Libereckém kraji",
  "Královéhradecký kraj"  => "v Královéhradeckém kraji",
  "Pardubický kraj"       => "v Pardubickém kraji",
  "Kraj Vysočina"         => "na Vysočině",
  "Jihomoravský kraj"     => "v Jihomoravském kraji",
  "Olomoucký kraj"        => "v Olomouckém kraji",
  "Zlínský kraj"          => "ve Zlínském kraji",
  "Moravskoslezský kraj"  => "v Moravskoslezském kraji",
}
def loc(region); LOC[region] || "v #{region}"; end

# Accusative, for "koupit ..." and "prodává ...".
CAT_ACC = {
  "meat" => "maso", "dairy" => "mléko a sýry", "eggs" => "vejce a drůbež",
  "veggies" => "zeleninu a plodiny", "honey" => "med",
}

# 1 farma / 2-4 farmy / 5+ farem.
def pl(n); n == 1 ? "farma" : (n < 5 ? "farmy" : "farem"); end

def short_place(town)
  parts = town.to_s.split(",").map(&:strip).reject(&:empty?)
  return town.to_s if parts.length < 2
  parts.first =~ /\d\s*\z/ ? parts.last : parts.first
end


def h(s); CGI.escapeHTML(s.to_s); end

# Diacritics out, spaces to dashes: the region slugs have to survive being
# typed, mailed and pasted, so they stay ASCII.
TR_FROM = "áäčďéěíľĺňóôöřŕšťúůüýžÁÄČĎÉĚÍĽĹŇÓÔÖŘŔŠŤÚŮÜÝŽ".chars
TR_TO   = "aacdeeillnooorrstuuuyzAACDEEILLNOOORRSTUUUYZ".chars
def slug(s)
  out = s.chars.map { |c| (i = TR_FROM.index(c)) ? TR_TO[i] : c }.join
  out.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/\A-|-\z/, "")
end

def clip(s, n = 155)
  s = s.to_s.strip.gsub(/\s+/, " ")
  s.length <= n ? s : s[0, n].sub(/\s+\S*\z/, "") + "…"
end

# One head for every generated page. These pages exist to be read by crawlers,
# so each gets its own title, description and canonical -- never the homepage's.
def page(title:, desc:, path:, body:, jsonld: nil, breadcrumb: nil)
  url = "#{SITE}#{path}"
  ld  = [jsonld, breadcrumb].compact.map { |o|
    %(<script type="application/ld+json">#{JSON.generate(o)}</script>)
  }.join("\n")
  <<~HTML
    <!doctype html>
    <html lang="cs">
    <head>
    <meta charset="utf-8">
    <title>#{h title}</title>
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <meta name="description" content="#{h desc}">
    <link rel="canonical" href="#{h url}">
    <meta property="og:type" content="website">
    <meta property="og:url" content="#{h url}">
    <meta property="og:site_name" content="Živé farmy">
    <meta property="og:title" content="#{h title}">
    <meta property="og:description" content="#{h desc}">
    <meta property="og:locale" content="cs_CZ">
    <meta property="og:image" content="#{SITE}/og.png">
    <meta name="twitter:card" content="summary_large_image">
    <meta name="twitter:image" content="#{SITE}/og.png">
    <link rel="icon" href="data:image/svg+xml,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'><text y='.9em' font-size='90'>%F0%9F%8C%BE</text></svg>">
    <link rel="stylesheet" href="#{SITE}/pages.css">
    #{ld}
    </head>
    <body>
    <header class="top"><a class="brand" href="#{SITE}/">🌾 Živé farmy</a>
    <nav><a href="#{SITE}/">Mapa</a> <a href="#{SITE}/farmy/">Seznam farem</a></nav></header>
    <main>
    #{body}
    </main>
    <footer><p>Kurátorovaný výběr bio a regenerativních farem v Česku. Údaje pocházejí z webů jednotlivých farem.
    <a href="#{SITE}/">Zpět na mapu</a></p></footer>
    </body>
    </html>
  HTML
end

def crumbs(items)
  { "@context" => "https://schema.org", "@type" => "BreadcrumbList",
    "itemListElement" => items.each_with_index.map { |(name, url), i|
      { "@type" => "ListItem", "position" => i + 1, "name" => name, "item" => url } } }
end

def farm_url(f); "#{SITE}/farma/#{f[%q{id}]}/"; end

# A farm as it appears in a list: enough to be useful without opening it.
def farm_li(f)
  bits = f["cats"].map { |c| CATS[c] }.compact.join(" · ")
  bio  = f["cert"] == "bio" ? %(<span class="bio">BIO</span>) : ""
  %(<li><a href="#{farm_url(f)}"><strong>#{h f['name']}</strong></a> #{bio}
     <span class="where">#{h f.dig('town','cs')}</span>
     <span class="what">#{h bits}</span></li>)
end

def dl(rows)
  rows = rows.reject { |_, v| v.nil? || v.to_s.empty? }
  return "" if rows.empty?
  "<dl>" + rows.map { |k, v| "<dt>#{h k}</dt><dd>#{v}</dd>" }.join + "</dl>"
end

written = []
def write(path, html, written)
  full = File.join(ROOT, path)
  FileUtils.mkdir_p(File.dirname(full))
  File.write(full, html)
  written << path
end

# ---------------------------------------------------------------- farm pages
farms.each do |f|
  region = f.dig("region", "cs")
  story  = (f.dig("story", "cs") || [])
  desc   = clip(story.first || "#{f['name']} – #{f.dig('town','cs')}")

  buy = []
  buy << %(<a href="#{h f['website']}" rel="nofollow noopener" target="_blank">Web farmy</a>) if f["website"]
  buy << %(<a href="#{h f['eshop']}" rel="nofollow noopener" target="_blank">E-shop / objednávky</a>) if f["eshop"]
  (f["shops"] || {}).each { |k, v| buy << %(<a href="#{h v}" rel="nofollow noopener" target="_blank">#{h CHANNELS[k] || k}</a>) }
  (f["sellers"] || []).each { |s|
    buy << (s["url"] ? %(<a href="#{h s['url']}" rel="nofollow noopener" target="_blank">#{h s['name']}</a>) : h(s["name"])) }

  contact = []
  contact << %(<a href="tel:#{h f['phone'].gsub(/\s+/, '')}">#{h f['phone']}</a>) if f["phone"]
  contact << %(<a href="mailto:#{h f['email']}">#{h f['email']}</a>) if f["email"]
  contact << %(<a href="#{h f['facebook']}" rel="nofollow noopener" target="_blank">Facebook</a>) if f["facebook"]
  contact << %(<a href="#{h f['instagram']}" rel="nofollow noopener" target="_blank">Instagram</a>) if f["instagram"]

  siblings = farms.select { |g| g.dig("region", "cs") == region && g["id"] != f["id"] }.first(6)

  ld = { "@context" => "https://schema.org", "@type" => "LocalBusiness",
         "name" => f["name"], "url" => farm_url(f),
         "description" => story.join(" "),
         "address" => { "@type" => "PostalAddress", "addressLocality" => f.dig("town", "cs"),
                        "addressRegion" => region, "addressCountry" => "CZ" },
         "geo" => { "@type" => "GeoCoordinates", "latitude" => f["lat"], "longitude" => f["lon"] },
         "makesOffer" => f["cats"].map { |c|
           { "@type" => "Offer", "itemOffered" => { "@type" => "Product", "name" => CATS[c] } } } }
  ld["telephone"] = f["phone"] if f["phone"]
  ld["email"]     = f["email"] if f["email"]
  ld["sameAs"]    = [f["website"], f["facebook"], f["instagram"]].compact if f["website"] || f["facebook"]
  ld["additionalProperty"] = [{ "@type" => "PropertyValue", "name" => "Certifikace",
                                "value" => "Ekologické zemědělství (BIO)" }] if f["cert"] == "bio"

  body = +""
  body << %(<p class="crumb"><a href="#{SITE}/">Mapa</a> › <a href="#{SITE}/kraj/#{slug(region)}/">#{h region}</a> › #{h f['name']}</p>)
  body << "<h1>#{h f['name']}#{f['cert'] == 'bio' ? %( <span class="bio">BIO</span>) : ''}</h1>"
  body << %(<p class="lede">#{h f.dig('town','cs')}, #{h region} — #{h f['cats'].map { |c| CATS[c] }.compact.join(', ')}</p>)
  body << "<h2>O farmě</h2><ul class=\"story\">" + story.map { |s| "<li>#{h s}</li>" }.join + "</ul>" unless story.empty?
  body << dl([
    ["Kde koupit",    buy.empty? ? nil : buy.join(" · ")],
    ["Otevírací doba / výdej", f.dig("hours", "cs")],
    ["Doprava",       (f["delivery"] || []).map { |d| DELIVERY[d] }.compact.join(", ")],
    ["Na farmě také", (f["offers"] || []).map { |o| OFFERS[o] }.compact.join(", ")],
    ["Ocenění",       (f["awards"] || []).map { |a| a["cs"] }.compact.join("; ")],
    ["Kontakt",       contact.empty? ? nil : contact.join(" · ")],
    ["Certifikace",   f["cert"] == "bio" ? "Ekologické zemědělství (BIO)" : nil],
  ])
  body << %(<p class="cta"><a class="btn" href="#{SITE}/#farma=#{h f['id']}">Zobrazit na mapě</a></p>)
  unless siblings.empty?
    body << %(<h2>Další farmy #{h loc(region)}</h2><ul class="farms">) + siblings.map { |g| farm_li(g) }.join + "</ul>"
    body << %(<p><a href="#{SITE}/kraj/#{slug(region)}/">Všechny farmy #{h loc(region)}</a></p>)
  end

  write("farma/#{f['id']}/index.html",
        page(title: "#{f['name']} – #{short_place(f.dig('town','cs'))} | Živé farmy",
             desc: desc, path: "/farma/#{f['id']}/", body: body, jsonld: ld,
             breadcrumb: crumbs([["Mapa", "#{SITE}/"],
                                 [region, "#{SITE}/kraj/#{slug(region)}/"],
                                 [f["name"], farm_url(f)]])), written)
end

# ------------------------------------------------------------- region pages
by_region = farms.group_by { |f| f.dig("region", "cs") }
by_region.each do |region, list|
  list = list.sort_by { |f| f["name"] }
  body = +""
  body << %(<p class="crumb"><a href="#{SITE}/">Mapa</a> › #{h region}</p>)
  body << "<h1>Bio a regenerativní farmy — #{h region}</h1>"
  body << %(<p class="lede">#{list.length} #{pl(list.length)} #{h loc(region)}, u kterých se dá nakoupit přímo od farmáře.</p>)
  body << %(<ul class="farms">) + list.map { |f| farm_li(f) }.join + "</ul>"
  body << %(<h2>Další kraje</h2><ul class="cols">) +
          by_region.keys.sort.reject { |r| r == region }
                   .map { |r| %(<li><a href="#{SITE}/kraj/#{slug(r)}/">#{h r}</a> (#{by_region[r].length})</li>) }.join + "</ul>"
  write("kraj/#{slug(region)}/index.html",
        page(title: "Bio farmy #{loc(region)} — #{list.length} #{pl(list.length)} | Živé farmy",
             desc: clip("Seznam #{list.length} bio a regenerativních farem #{loc(region)}: co prodávají, kde je koupit a jak je kontaktovat."),
             path: "/kraj/#{slug(region)}/", body: body,
             jsonld: { "@context" => "https://schema.org", "@type" => "ItemList",
                       "name" => "Bio a regenerativní farmy – #{region}",
                       "numberOfItems" => list.length,
                       "itemListElement" => list.each_with_index.map { |f, i|
                         { "@type" => "ListItem", "position" => i + 1, "name" => f["name"], "url" => farm_url(f) } } },
             breadcrumb: crumbs([["Mapa", "#{SITE}/"], [region, "#{SITE}/kraj/#{slug(region)}/"]])), written)
end

# ----------------------------------------------------------- category pages
CATS.each do |cat, label|
  list = farms.select { |f| f["cats"].include?(cat) }.sort_by { |f| f["name"] }
  next if list.empty?
  body = +""
  body << %(<p class="crumb"><a href="#{SITE}/">Mapa</a> › #{h label}</p>)
  body << "<h1>Kde koupit #{h CAT_ACC[cat]} přímo od farmáře</h1>"
  body << %(<p class="lede">#{h CAT_INTRO[cat]}</p>)
  body << %(<p>#{list.length} #{pl(list.length)} na mapě prodává #{h CAT_ACC[cat]}.</p>)
  body << %(<ul class="farms">) + list.map { |f| farm_li(f) }.join + "</ul>"
  body << %(<h2>Další kategorie</h2><ul class="cols">) +
          CATS.reject { |k, _| k == cat }
              .map { |k, v| %(<li><a href="#{SITE}/co-koupit/#{k}/">#{h v}</a></li>) }.join + "</ul>"
  write("co-koupit/#{cat}/index.html",
        page(title: "Kde koupit #{CAT_ACC[cat]} od farmáře — #{list.length} #{pl(list.length)} | Živé farmy",
             desc: clip("#{list.length} bio a regenerativních farem v Česku, u kterých koupíte #{CAT_ACC[cat]} přímo od farmáře."),
             path: "/co-koupit/#{cat}/", body: body,
             jsonld: { "@context" => "https://schema.org", "@type" => "ItemList",
                       "name" => "Farmy – #{label}", "numberOfItems" => list.length,
                       "itemListElement" => list.each_with_index.map { |f, i|
                         { "@type" => "ListItem", "position" => i + 1, "name" => f["name"], "url" => farm_url(f) } } },
             breadcrumb: crumbs([["Mapa", "#{SITE}/"], [label, "#{SITE}/co-koupit/#{cat}/"]])), written)
end

# ------------------------------------------------------------- the hub page
body = +""
body << "<h1>Seznam bio a regenerativních farem v Česku</h1>"
body << %(<p class="lede">#{farms.length} farem, u kterých se dá nakoupit přímo od farmáře — maso, mléko a sýry, vejce, zeleninu i med.
  Každá farma má vlastní stránku s tím, co prodává, kde to koupit a jak ji kontaktovat.
  Interaktivní verzi najdete na <a href="#{SITE}/">mapě</a>.</p>)
body << %(<h2>Podle toho, co hledáte</h2><ul class="cols">) +
        CATS.map { |k, v| %(<li><a href="#{SITE}/co-koupit/#{k}/">#{h v}</a> (#{farms.count { |f| f['cats'].include?(k) }})</li>) }.join + "</ul>"
body << %(<h2>Podle kraje</h2><ul class="cols">) +
        by_region.keys.sort.map { |r| %(<li><a href="#{SITE}/kraj/#{slug(r)}/">#{h r}</a> (#{by_region[r].length})</li>) }.join + "</ul>"
by_region.keys.sort.each do |region|
  body << %(<h2 id="#{slug(region)}">#{h region}</h2>)
  body << %(<ul class="farms">) + by_region[region].sort_by { |f| f["name"] }.map { |f| farm_li(f) }.join + "</ul>"
end
write("farmy/index.html",
      page(title: "Seznam bio a regenerativních farem v Česku — #{farms.length} farem | Živé farmy",
           desc: clip("Kompletní seznam #{farms.length} bio a regenerativních farem v Česku podle krajů: maso, mléko, vejce, zelenina a med přímo od farmáře."),
           path: "/farmy/", body: body,
           jsonld: { "@context" => "https://schema.org", "@type" => "ItemList",
                     "name" => "Bio a regenerativní farmy v Česku",
                     "numberOfItems" => farms.length,
                     "itemListElement" => farms.each_with_index.map { |f, i|
                       { "@type" => "ListItem", "position" => i + 1, "name" => f["name"], "url" => farm_url(f) } } },
           breadcrumb: crumbs([["Mapa", "#{SITE}/"], ["Seznam farem", "#{SITE}/farmy/"]])), written)

# ---------------------------------------------------------------- sitemap
urls = [["#{SITE}/", "1.0", "weekly"], ["#{SITE}/farmy/", "0.9", "weekly"]]
CATS.each_key { |c| urls << ["#{SITE}/co-koupit/#{c}/", "0.8", "monthly"] }
by_region.each_key { |r| urls << ["#{SITE}/kraj/#{slug(r)}/", "0.7", "monthly"] }
farms.each { |f| urls << [farm_url(f), "0.6", "monthly"] }
File.write(File.join(ROOT, "sitemap.xml"), <<~XML)
  <?xml version="1.0" encoding="UTF-8"?>
  <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  #{urls.map { |u, p, c| "  <url>\n    <loc>#{u}</loc>\n    <lastmod>#{TODAY}</lastmod>\n    <changefreq>#{c}</changefreq>\n    <priority>#{p}</priority>\n  </url>" }.join("\n")}
  </urlset>
XML

# ---- prune pages whose farm, region or category no longer exists ----------
# A farm removed from the map must not leave its page behind: it would stay
# served, linked from nobody's navigation, quietly contradicting the map.
def prune(root, dir, keep)
  base = File.join(root, dir)
  return [] unless Dir.exist?(base)
  gone = Dir.children(base).select { |c| File.directory?(File.join(base, c)) && !keep.include?(c) }
  gone.each { |c| FileUtils.rm_rf(File.join(base, c)) }
  gone.map { |c| "#{dir}/#{c}" }
end
pruned = prune(ROOT, "farma", farms.map { |f| f["id"] }) +
         prune(ROOT, "kraj", by_region.keys.map { |r| slug(r) }) +
         prune(ROOT, "co-koupit", CATS.keys)
puts "pruned: #{pruned.empty? ? 'nothing' : pruned.join(', ')}"

puts "pages: #{written.length}"
puts "  farma/:     #{written.count { |p| p.start_with?('farma/') }}"
puts "  kraj/:      #{written.count { |p| p.start_with?('kraj/') }}"
puts "  co-koupit/: #{written.count { |p| p.start_with?('co-koupit/') }}"
puts "sitemap urls: #{urls.length}"
