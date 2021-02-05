hs.alert.show("Hammerspoon config loaded")

browser = "Google Chrome"
editor = "Visual Studio Code"
terminal = "Kitty"

hyper = {"cmd", "alt", "ctrl", "shift"}

hs.hotkey.bind(hyper, "R", function()
  hs.reload()
end)

hs.hotkey.bind(hyper, "B", function()
  hs.application.launchOrFocus(browser)
end)
hs.hotkey.bind(hyper, "E", function()
  hs.application.launchOrFocus(editor)
end)
hs.hotkey.bind(hyper, "T", function()
  hs.application.launchOrFocus(terminal)
end)

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
