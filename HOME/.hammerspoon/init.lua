hs.alert.show("Hammerspoon config loaded")

hyper = {"cmd", "alt", "ctrl", "shift"}

-- bind reload at start in case of error later in config
hs.hotkey.bind(hyper, "R", hs.reload)
hs.hotkey.bind(hyper, "Y", hs.toggleConsole)

function inspect(value)
  hs.alert.show(hs.inspect(value))
end

-- install cli
arch = io.popen('uname -p', 'r'):read('*l')
path = arch == 'arm' and '/opt/homebrew' or nil
hs.ipc.cliInstall(path)
hs.ipc.cliSaveHistory(true)

fennel = require("fennel")
table.insert(package.loaders or package.searchers, fennel.searcher)
fennel.dofile("init.fnl") -- exports into global namespace
