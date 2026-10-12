# encoding: utf-8
dom = File.read(ARGV[0], encoding: "UTF-8")
m = dom.match(/<pre id="__dump">(.*?)<\/pre>/m)
abort("MISS: no dump element") unless m
json = m[1]
       .gsub("&lt;", "<").gsub("&gt;", ">").gsub("&quot;", '"').gsub("&amp;", "&")
File.write(ARGV[1], json)
require "json"
farms = JSON.parse(json)
puts "farms parsed: #{farms.length}"
puts "with website:  #{farms.count { |f| f['website'] }}"
puts "with eshop:    #{farms.count { |f| f['eshop'] }}"
puts "with cert bio: #{farms.count { |f| f['cert'] == 'bio' }}"
puts "regions:       #{farms.map { |f| f.dig('region','cs') }.uniq.length}"
puts "sample: #{farms[0]['name']} / #{farms[0].dig('town','cs')} / #{farms[0]['cats'].join(',')}"
missing = farms.reject { |f| f['id'] && f['name'] && f.dig('town','cs') && f.dig('region','cs') && f['lat'] && f['story'] }
puts "records missing core fields: #{missing.length}#{missing.empty? ? '' : ' -> ' + missing.map{|f| f['id']}.join(',')}"
