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
  if !File.exists?(file)
    exit 0
  end

  json = JSON.parse(File.read(file))
  color = json["peacock.color"]?
  if color
    result = "
export KITTY_TAB_AFG=#fff
export KITTY_TAB_ABG=#{color}
export KITTY_TAB_IFG=#ccc
export KITTY_TAB_IBG=#{color}
"
    puts result
  end
end
