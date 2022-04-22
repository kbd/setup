hs.alert.show("Hammerspoon config loaded")

hyper = {"cmd", "alt", "ctrl", "shift"}

-- bind reload at start in case of error later in config
hs.hotkey.bind(hyper, "R", hs.reload)
hs.hotkey.bind(hyper, "Y", hs.toggleConsole)
hs.ipc.cliInstall()
hs.ipc.cliSaveHistory(true)

function inspect(value)
  hs.alert.show(hs.inspect(value))
end

fennel = require("fennel")
table.insert(package.loaders or package.searchers, fennel.searcher)
init = fennel.dofile("initfnl.fnl")
