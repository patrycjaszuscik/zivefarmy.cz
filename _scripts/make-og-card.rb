# encoding: utf-8
# Writes _og/card.html -- the source of the social preview picture -- from the
# same data the map uses, so the farm count and the pins can never go stale.
#   ruby _scripts/make-og-card.rb && ./_scripts/make-og.sh
# Region outlines come from _og/regions.txt (extracted once from the map's
# REGIONS array); pin positions are projected from _og/farms.json with the
# map's own projection constants.
require "json"
root   = File.expand_path("..", __dir__)
farms  = JSON.parse(File.read(File.join(root, "_og", "farms.json"), encoding: "UTF-8"))
paths  = File.readlines(File.join(root, "_og", "regions.txt")).map(&:strip).reject(&:empty?)
abort("expected 14 region paths, got #{paths.length}") unless paths.length == 14

VB_W, VB_H = 900.0, 532.92
MINLON, MAXLAT, SCALE, COSLAT, MARGIN = 12.090575, 51.055701, 196.8613, 0.645408, 20.0
pins = farms.map { |f|
  x = (f["lon"] - MINLON) * COSLAT * SCALE + MARGIN
  y = (MAXLAT - f["lat"]) * SCALE + MARGIN
  format('<circle cx="%.1f" cy="%.1f" r="6.6"/>', x, y)
}.join("\n")

n = farms.length
word = n == 1 ? "farma" : (n < 5 ? "farmy" : "farem")

File.write(File.join(root, "_og", "card.html"), <<~HTML)
  <!doctype html><html lang="cs"><head><meta charset="utf-8"><style>
    *{margin:0;padding:0;box-sizing:border-box}
    html,body{width:1200px;height:630px;overflow:hidden}
    body{
      background:#F6F0E1;
      background-image:radial-gradient(1150px 820px at 76% 22%, #FFFDF7 0%, #F6F0E1 50%, #EEE0C2 100%);
      font-family:"Helvetica Neue",Helvetica,Arial,sans-serif;
      color:#332619; position:relative;
    }
    .edge{position:absolute;inset:0;border:1px solid #DECBA3;border-bottom-width:8px;border-bottom-color:#B2552A}
    .wrap{position:absolute;inset:0;display:flex;align-items:center;padding:0 54px 8px 70px;gap:10px}
    .left{width:452px;flex:none}
    .mark{
      width:72px;height:72px;border-radius:21px;
      background:linear-gradient(145deg,#5B7A3A,#5C7C8B);
      display:flex;align-items:center;justify-content:center;
      box-shadow:0 6px 16px rgba(51,38,25,.20); margin-bottom:24px;
    }
    .mark svg{width:41px;height:41px;fill:none;stroke:#fff;stroke-width:2;stroke-linecap:round;stroke-linejoin:round}
    h1{font-family:"Iowan Old Style",Georgia,"Times New Roman",serif;font-weight:600;font-size:90px;line-height:.98;letter-spacing:-.018em}
    .rule{width:92px;height:5px;border-radius:3px;background:#B2552A;margin:24px 0 22px}
    p.tag{font-size:29px;line-height:1.32;color:#6E5C44;max-width:430px}
    .count{margin-top:28px;display:flex;align-items:baseline;gap:12px;white-space:nowrap}
    .count b{font-family:"Iowan Old Style",Georgia,serif;font-size:48px;font-weight:700;color:#5B7A3A;letter-spacing:-.01em}
    .count span{font-size:27px;color:#7C6A50}
    p.cats{margin-top:8px;font-size:21px;color:#8A7558;white-space:nowrap}
    .domain{position:absolute;left:70px;bottom:44px;font-size:25px;font-weight:700;letter-spacing:.055em;color:#B2552A;text-transform:uppercase}
    .mapbox{flex:1;display:flex;align-items:center;justify-content:center;margin-top:-10px}
    svg.map{width:106%;height:auto;display:block;overflow:visible}
    .map .land{fill:#DCE3C2;stroke:#8EA66C;stroke-width:1.6;stroke-linejoin:round}
    .map .pin{fill:#B2552A;stroke:#FFFDF7;stroke-width:2.6}
  </style></head><body>
  <div class="edge"></div>
  <div class="wrap">
    <div class="left">
      <div class="mark"><svg viewBox="0 0 24 24"><path d="M12 22V12"/><path d="M12 12C12 7 8 5 4 5c0 5 3 8 8 7Z"/><path d="M12 12c0-6 4-8 8-8 0 6-3 9-8 8Z"/></svg></div>
      <h1>Živé farmy</h1>
      <div class="rule"></div>
      <p class="tag">Mapa bio a&nbsp;regenerativních farem v&nbsp;Česku</p>
      <div class="count"><b>#{n}</b><span>#{word} na mapě</span></div>
      <p class="cats">maso · mléko a sýry · vejce · zelenina · med</p>
    </div>
    <div class="mapbox">
      <svg class="map" viewBox="14 12 872 509" xmlns="http://www.w3.org/2000/svg">
        <g class="land">
  #{paths.map { |d| "<path d=\"#{d}\"/>" }.join("\n")}
        </g>
        <g class="pin">
  #{pins}
        </g>
      </svg>
    </div>
  </div>
  <div class="domain">zivefarmy.cz</div>
  </body></html>
HTML
puts "card: #{n} #{word}, #{farms.length} pins, #{paths.length} regions"
