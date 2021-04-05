hs.alert.show("Hammerspoon config loaded")

hyper = {"cmd", "alt", "ctrl", "shift"}

-- bind reload at start in case of error later in config
hs.hotkey.bind(hyper, "R", hs.reload)

function bindApp(char, app)
  hs.hotkey.bind(hyper, char, function()
    hs.application.launchOrFocus(app)
  end)
end

function bindAppByUti(char, uti)
  hs.hotkey.bind(hyper, char, function()
    local bundleid = hs.application.defaultAppForUTI(uti)
    hs.application.launchOrFocusByBundleID(bundleid)
  end)
end

function bindCmd(char, cmd)
  hs.hotkey.bind(hyper, char, function()
    hs.execute(cmd, true)
  end)
end

function move(axis, increment)
  return function()
    local win = hs.window.focusedWindow()
    local f = win:frame()
    f[axis] = f[axis] + increment
    win:setFrame(f)
  end
end

function setlayout()
  local main = hs.screen.allScreens()[1]:name()
  local windowLayout = {
      {"Firefox", nil, main, {x=0,     y=0, w=0.275, h=1}, nil, nil},
      {"Code",    nil, main, {x=0.275, y=0, w=0.5,   h=1}, nil, nil},
      {"kitty",   nil, main, {x=0.775, y=0, w=0.225, h=1}, nil, nil},
  }
  hs.layout.apply(windowLayout)
end

right = move("x", 10)
left = move("x", -10)
up = move("y", -10)
down = move("y", 10)

bindAppByUti("B", "public.html")
bindAppByUti("T", "public.plain-text")
bindApp("S", "kitty")
bindCmd("C", "setup edit")
bindCmd("N", "notes")
hs.grid.setGrid("9x6")
hs.hotkey.bind(hyper, "G", hs.grid.show)
hs.hotkey.bind(hyper, "L", setlayout)
hs.hotkey.bind(hyper, "Right", right, nil, right)
hs.hotkey.bind(hyper, "Left", left, nil, left)
hs.hotkey.bind(hyper, "Up", up, nil, up)
hs.hotkey.bind(hyper, "Down", down, nil, down)
