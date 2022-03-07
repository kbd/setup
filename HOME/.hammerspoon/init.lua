hs.alert.show("Hammerspoon config loaded")

hyper = {"cmd", "alt", "ctrl", "shift"}

-- bind reload at start in case of error later in config
hs.hotkey.bind(hyper, "R", hs.reload)
hs.hotkey.bind(hyper, "Y", hs.toggleConsole)
hs.ipc.cliInstall()
hs.ipc.cliSaveHistory(true)

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

function getWindowsForAppOnScreen(appname, screen)
  local app = hs.application.get(appname)
  if app == nil then
    return
  end
  local scr = screen or hs.screen.mainScreen()
  local wins = app:allWindows()
  local result = {}
  for i, win in pairs(wins) do
    if win:screen() == scr then
      table.insert(result, win)
    end
  end
  return result
end

function lo(app, x, w)
  return {app, getWindowsForAppOnScreen, hs.screen.mainScreen, {x=x, y=0, w=w, h=1}, nil, nil}
end

layouts = {
  ["DELL U3818DW"] = {
    lo("Firefox", 0, 0.275), lo("Code", 0.275, 0.5), lo("kitty", 0.775, 0.225)
  },
  ["Built-in Retina Display"] = {
    lo("Firefox", 0, 0.3), lo("Code", 0.3, 0.38), lo("kitty", 0.68, 0.32)
  }
}
layouts["default"] = layouts["DELL U3818DW"]

function setlayout(name)
  local name = name or hs.screen.primaryScreen():name()
  local layout = layouts[name] or layouts["default"]
  hs.layout.apply(layout)
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
    local scr = screen or window:screen()
    setWindowFraction(app, window, num, den, scr)
  end
end

function moveActiveWindowToNextScreen()
  local w = hs.window.focusedWindow()
  w:moveToScreen(w:screen():next())
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
      active = devices[i]:uid() == active_input:uid()
      subtext = "input"
    end
    if active then
      subtext = subtext .. " (active)"
    end
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
  local device = hs.audiodevice.findDeviceByUID(audio.uid)
  hs.alert.show("Setting "..audio.subText.." device: "..device:name())
  if device:isOutputDevice() then
    device:setDefaultOutputDevice()
  else
    device:setDefaultInputDevice()
  end
end

function selectWindow(window)
  if window == nil then -- nothing selected
    return
  end
  hs.window.get(window.id):focus()
end

function showWindowFuzzy(app)
  local windows = nil
  if app == nil then -- all windows
    windows = hs.window.allWindows()
  elseif app == true then -- focused app windows
    windows = hs.application.frontmostApplication():allWindows()
  else -- specific app windows
    windows = app:allWindows()
  end
  local focused_id = hs.window.focusedWindow():id()
  local choices = {}
  for i=1, #windows do
    local w = windows[i]
    local id = w:id()
    local active = id == focused_id
    choices[i] = {
      text = (w:application():title()..": "..w:title()),
      id = id,
      subText = active and " (active)" or "",
      valid = not active,
    }
  end
  fuzzy(choices, selectWindow)
end

caffeine = hs.menubar.new()
function showCaffeine(awake)
  local title = awake and '☕' or '🍵'
  caffeine:setTitle(title)
end

function toggleCaffeine()
  showCaffeine(hs.caffeinate.toggle("displayIdle"))
end

if caffeine then
  caffeine:setClickCallback(toggleCaffeine)
  showCaffeine(hs.caffeinate.get("displayIdle"))
end

-- "main"

right = move("x", 50)
left = move("x", -50)
up = move("y", -50)
down = move("y", 50)

bindAppByUti("B", "public.html")
bindAppByUti("T", "public.plain-text")
bindApp("S", "kitty") -- "S=shell"
bindApp("C", "kitty") -- "C=console"
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
hs.hotkey.bind(hyper, "6", moveActiveWindow(1, 1))
hs.hotkey.bind(hyper, "N", moveActiveWindowToNextScreen)
hs.hotkey.bind(hyper, "A", showAudioFuzzy)
hs.hotkey.bind(hyper, ",", function() showWindowFuzzy(true) end) -- app windows
hs.hotkey.bind(hyper, ".", showWindowFuzzy) -- all windows
hs.hotkey.bind('alt', 'tab', hs.window.switcher.nextWindow)
hs.hotkey.bind('alt-shift', 'tab', hs.window.switcher.previousWindow)
expose = hs.expose.new() -- default windowfilter, no thumbnails
expose_app = hs.expose.new(nil, {onlyActiveApplication=true}) -- show windows for the current application
hs.hotkey.bind(hyper, 'e', function() expose:toggleShow() end)
hs.hotkey.bind(hyper, 'u', function() expose_app:toggleShow() end)
