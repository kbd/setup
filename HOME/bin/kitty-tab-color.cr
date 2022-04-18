require "json"

if ARGV[0]? == "-s"
  `kitty @ set-tab-color \
    active_fg=${KITTY_TAB_AFG:-NONE} \
    active_bg=${KITTY_TAB_ABG:-NONE} \
    inactive_fg=${KITTY_TAB_IFG:-NONE} \
    inactive_bg=${KITTY_TAB_IBG:-NONE}`
else
  # pull colors from vscode settings if exists
  file = ".vscode/settings.json"
  exit 0 if !File.exists?(file)

  json = JSON.parse(File.read(file))
  if color = json["peacock.color"]?
    puts "
export KITTY_TAB_AFG=#fff
export KITTY_TAB_ABG=#{color}
export KITTY_TAB_IFG=#ccc
export KITTY_TAB_IBG=#{color}
"
  end
end
