hs.alert.show("Hammerspoon config loaded")

hyper = {"cmd", "alt", "ctrl", "shift"}

hs.hotkey.bind(hyper, "R", function()
  hs.reload()
end)

function bindApp(char, app)
  hs.hotkey.bind(hyper, char, function()
    hs.application.launchOrFocus(app)
  end)
end

function bindCmd(char, cmd)
  hs.hotkey.bind(hyper, char, function()
    hs.execute(cmd, true)
  end)
end

bindApp("B", "Google Chrome")
bindApp("E", "Visual Studio Code")
bindApp("T", "Kitty")
bindCmd("C", "setup edit")
bindCmd("N", "notes")

function move(axis, increment)
  return function()
    local win = hs.window.focusedWindow()
    local f = win:frame()
    f[axis] = f[axis] + increment
    win:setFrame(f)
  end
end

right = move("x", 10)
left = move("x", -10)
up = move("y", -10)
down = move("y", 10)

hs.hotkey.bind(hyper, "Right", right, nil, right)
hs.hotkey.bind(hyper, "Left", left, nil, left)
hs.hotkey.bind(hyper, "Up", up, nil, up)
hs.hotkey.bind(hyper, "Down", down, nil, down)

hs.grid.setGrid("9x6")
hs.hotkey.bind(hyper, "G", hs.grid.show)
