require "colorize"
require "json"
require "math"

def get_color(color)
  rgb = color.to_s[1..-1].to_i 16
  r = ((rgb >> 16) & 0xff).to_u8
  g = ((rgb >>  8) & 0xff).to_u8
  b = ((rgb >>  0) & 0xff).to_u8
  Colorize::ColorRGB.new r, g, b
end

# https://www.w3.org/TR/AERT/#color-contrast
def get_brightness(c)
  (c.red.to_f * 299 + c.green.to_f * 587 + c.blue.to_f * 114).to_f / 1000
end

def color_difference(c1, c2)
  (Math.max(c1.red, c2.red) - Math.min(c1.red, c2.red))
  + (Math.max(c1.green, c2.green) - Math.min(c1.green, c2.green))
  + (Math.max(c1.blue, c2.blue) - Math.min(c1.blue, c2.blue))
end

# main

exit 1 if ARGV.size == 0 # must provide argument

vscode_setings_path = ARGV[0]
puts "# path: #{vscode_setings_path}"
exit 1 if !File.exists?(vscode_setings_path)

json = JSON.parse(File.read(vscode_setings_path))
color = json["peacock.color"]?
exit 0 if !color

colorrgb = get_color(color)
brightness = get_brightness(colorrgb)
puts "# color: #{color}"
puts "# brightness: #{brightness}"
if (brightness < 150)
  afg = "#fff"
  ifg = "#ccc"
else
  afg = "#000"
  ifg = "#333"
end

puts "
export KITTY_TAB_AFG=#{afg}
export KITTY_TAB_ABG=#{color}
export KITTY_TAB_IFG=#{ifg}
export KITTY_TAB_IBG=#{color}
"
