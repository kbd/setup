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

function setWindowFraction(app, window, num, den, screen)
  local windowLayout = {
    {app, window, screen, {x=(num-1)/den, y=0, w=1/den, h=1}, nil, nil},
  }
  hs.layout.apply(windowLayout)
end

function moveActiveWindow(num, den, screen)
  return function()
    local app = hs.application.frontmostApplication()
    local window = hs.window.focusedWindow()
    setWindowFraction(app, window, num, den, screen)
  end
end

function inspect(value)
  hs.alert.show(hs.inspect(value))
end

function fuzzy(choices, func)
  local chooser = hs.chooser.new(func)
  chooser:choices(choices)
  chooser:searchSubText(true)
  chooser:fgColor({hex="#bbf"})
  chooser:subTextColor({hex="#aaa"})
  chooser:width(25)
  chooser:show()
end

function showAudioFuzzy()
  local devices = hs.audiodevice.allDevices()
  local choices = {}
  local active_input = hs.audiodevice.defaultInputDevice()
  local active_output = hs.audiodevice.defaultOutputDevice()
  local active, subtext
  for i=1, #devices do
    if devices[i]:isOutputDevice() then
      active = devices[i]:uid() == active_output:uid()
      subtext = "output"
    else
      active = devices[i]:uid() ~= active_input:uid()
      subtext = "input"
    end
    if active then subtext = subtext .. " (active)" end
    choices[i] = {
      text = devices[i]:name(),
      uid = devices[i]:uid(),
      subText = subtext,
      valid = not active,
    }
  end
  fuzzy(choices, selectAudio)
end

function selectAudio(audio)
  if audio == nil then -- nothing selected
    return
  end
  device = hs.audiodevice.findDeviceByUID(audio.uid)
  hs.alert.show("Setting "..audio.subText.." device: "..device:name())
  if device:isOutputDevice() then
    device:setDefaultOutputDevice()
  else
    device:setDefaultInputDevice()
  end
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
hs.hotkey.bind(hyper, "1", moveActiveWindow(1, 2))
hs.hotkey.bind(hyper, "2", moveActiveWindow(2, 2))
hs.hotkey.bind(hyper, "3", moveActiveWindow(1, 3))
hs.hotkey.bind(hyper, "4", moveActiveWindow(2, 3))
hs.hotkey.bind(hyper, "5", moveActiveWindow(3, 3))
hs.hotkey.bind(hyper, "A", showAudioFuzzy)
