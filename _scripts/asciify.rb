# encoding: utf-8
# Keeps the source pure ASCII: &#NNN; in the HTML half, \uXXXX in the script half.
# Run after every edit to _src/czech-farm-atlas.html, before build.rb.
root = File.expand_path("..", __dir__)
path = File.join(root, "_src", "czech-farm-atlas.html")
s = File.read(path, encoding: "UTF-8")
i = s.index("<script>")
head, tail = s[0...i], s[i..-1]
head = head.chars.map { |c| c.ord < 128 ? c : "&##{c.ord};" }.join
tail = tail.chars.map { |c| c.ord < 128 ? c : format("\\u%04X", c.ord) }.join
File.write(path, head + tail)
puts "asciify: #{(head + tail).chars.count { |c| c.ord > 127 }} non-ASCII chars left"
