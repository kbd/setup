require "json"

exit 1 if ARGV.size == 0 # must provide argument

vscode_setings_path = ARGV[0]
puts "# path: #{vscode_setings_path}"
exit 1 if !File.exists?(vscode_setings_path)

json = JSON.parse(File.read(vscode_setings_path))
if color = json["peacock.color"]?
  puts "
export KITTY_TAB_AFG=#fff
export KITTY_TAB_ABG=#{color}
export KITTY_TAB_IFG=#ccc
export KITTY_TAB_IBG=#{color}
"
end
