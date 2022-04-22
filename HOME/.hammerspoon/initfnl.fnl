(fn bind-app [char app]
  (hs.hotkey.bind hyper char #(hs.application.launchOrFocus app)))

(fn bind-app-by-uti [char uti]
  (hs.hotkey.bind hyper char #(
    (let [bundleid (hs.application.defaultAppForUTI uti)]
      (hs.application.launchOrFocusByBundleID bundleid)))))

(fn bind-cmd [char cmd]
  (hs.hotkey.bind hyper char #(hs.execute cmd true)))

(fn move [axis increment] (fn []
  (let [win (hs.window.focusedWindow)
        f (win:frame)]
    (tset f axis (+ (. f axis) increment))
    (win:setFrame f))))

(fn get-windows-for-app-on-screen [appname screen]
  (let [app (hs.application.get appname)]
    (if (= app nil)
      nil
      (let [scr (or screen (hs.screen.mainScreen))
            wins (app:allWindows)
            result {}]
        (each [i win (pairs wins)]
          (if (= scr (win:screen))
            (table.insert result win)))
        result))))

(fn lo [app x w]
  [app get-windows-for-app-on-screen hs.screen.mainScreen {"x" x "y" 0 "w" w "h" 1} nil nil])

(local layouts {
  "DELL U3818DW" [
    (lo "Firefox" 0 0.275) (lo "Code" 0.275 0.5) (lo "kitty" 0.775 0.225)
  ]
  "Built-in Retina Display" [
    (lo "Firefox" 0 0.3) (lo "Code" 0.3 0.38) (lo "kitty" 0.68 0.32)
  ]
})
(tset layouts "default" (. layouts "DELL U3818DW"))

(fn set-layout [name]
  (let [name (or name (: (hs.screen.primaryScreen) "name"))
        layout (or (. layouts name) layouts.default)]
    (hs.layout.apply layout)))

(fn set-window-fraction [app window num den screen]
  (let [coords {"x" (/ (- num 1) den) "y" 0 "w" (/ 1 den) "h" 1}
        layout [app window screen coords nil nil]]
    (hs.layout.apply [layout])))

(fn move-active-window [num den screen]
  (fn []
   (let [app (hs.application.frontmostApplication)
          window (hs.window.focusedWindow)
          scr (or screen (: window "screen"))]
        (inspect app)
        (inspect window)
        (inspect scr)
    (set-window-fraction app window num den scr))))

(fn move-active-window-to-next-screen []
  (let [w (hs.window.focusedWindow)]
    (w:moveToScreen (: (w:screen) "next"))))

(fn fuzzy [choices func]
  (let [chooser (hs.chooser.new func)]
    (chooser:choices choices)
    (chooser:searchSubText true)
    (chooser:fgColor {"hex" "#bbf"})
    (chooser:subTextColor {"hex" "#aaa"})
    (chooser:width 25)
    (chooser:show)))

(fn select-audio [audio]
  (if (not= audio nil)
    (let [device (hs.audiodevice.findDeviceByUID audio.uid)]
      (hs.alert.show (.. "Setting " audio.subText " device: " (device:name)))
      (if (device:isOutputDevice)
        (device:setDefaultOutputDevice)
        (device:setDefaultInputDevice)
      ))))

(fn show-audio-fuzzy []
  (let [devices (hs.audiodevice.allDevices)
        choices {}
        active_input (hs.audiodevice.defaultInputDevice)
        active_output (hs.audiodevice.defaultOutputDevice)]
    (var [active subtext] [nil nil])
    (each [i device (pairs devices)]
      (if (device:isOutputDevice)
        (set [active subtext]
          [(= (device:uid) (active_output:uid)) "output"])
        (set [active subtext]
          [(= (device:uid) (active_input:uid)) "input"]))
      (if active
        (set subtext (.. subtext " (active)")))

      (tset choices i {
        "text" (device:name)
        "uid" (device:uid)
        "subText" subtext
        "valid" (not active)
      })
    )
  (fuzzy choices select-audio)))

(fn select-window [window]
  (if (not= window nil)
    (: (hs.window.get window.id) "focus")))

(fn show-window-fuzzy [app]
  (local windows
    (if (= app nil) (hs.window.allWindows) ; all windows
        (= app true) (: (hs.application.frontmostApplication) "allWindows") ; focused app windows
        (app:allWindows)) ; specific app windows
  )
  (local focused_id (: (hs.window.focusedWindow) "id"))
  (local [choices app_images] [{} {}])
  (each [i window (pairs windows)]
    (local id (window:id))
    (local active (= id focused_id))
    (local app (window:application))
    (if (= (. app_images app) nil) ; cache the app image per app
      (tset app_images app (hs.image.imageFromAppBundle (app:bundleID))))
    (local image (. app_images app))
    (local text (window:title))
    (local subText (.. (app:title) (if active " (active)" "")))
    (tset choices i {
      "text" text
      "subText" subText
      "image" image
      "valid" (not active)
      "id" id
    }))
  (fuzzy choices select-window))

(fn execute-shortcut [shortcut]
  (if (not= shortcut nil)
    (let [action shortcut.action
          bundleid (. action 1)
          app (hs.application.applicationsForBundleID bundleid)]
      (if (= (length app) 0)
        (hs.application.launchOrFocusByBundleID bundleid))
      (hs.eventtap.keyStroke (. action 2) (. action 3) 0 (. app 1)))))

; show a fuzzy finder of app-specific shortcuts
(fn show-shortcut-fuzzy [shortcuts]
  (fn []
    (local choices {})
    (each [i shortcut (pairs shortcuts)]
      (local shortcut (. shortcuts i))
      (local name (. shortcut 1))
      (local action (. shortcut 2))
      (local bundleid (. action 1))
      (local func (?. shortcut 3))
      (tset choices i {
        "text" name
        "subText" "" ; (if (not= nil func) (func) nil) ; tf?
        "image" (hs.image.imageFromAppBundle bundleid)
        "valid" true
        "action" action
      }
    (fuzzy choices execute-shortcut)))))

(fn is-zoom-muted []
  (local apps (hs.application.applicationsForBundleID "us.zoom.xos"))
  (if (not= (length apps) 0)
    (let [app (. apps 1)]
      (if (not= nil ((: app "findMenuItem") ["Meeting" "Unmute Audio"]))
        true
        (not= nil ((: app "findMenuItem") ["Meeting" "Mute Audio"]))
        false
        nil))))

(fn zoom-mute-icon []
  (let [muted (is-zoom-muted)]
    (if (= nil muted) nil (if muted "🔴" "🟢" ))))

(local caffeine (hs.menubar.new))
(fn show-caffeine [awake]
  (local title (if awake "☕" "🍵"))
  (caffeine:setTitle title))

(fn toggle-caffeine []
  (show-caffeine (hs.caffeinate.toggle "displayIdle")))

(if caffeine
  (do
    (caffeine:setClickCallback toggle-caffeine)
    (show-caffeine (hs.caffeinate.get "displayIdle"))))

(fn browser []
  ; activate browser. if already active, bring up vimium tab switcher
  (local browser-bundleid (hs.application.defaultAppForUTI "public.html"))
  ; get active app, if active app bundle id = browser bundle id, then vimium, otherwise activate
  (local focused-app (hs.application.frontmostApplication))
  (if (not= (: focused-app "bundleID") browser-bundleid)
    (hs.application.launchOrFocusByBundleID browser-bundleid)
    (hs.eventtap.keyStroke ["shift"] "T" 0 focused-app))) ; vimium switch tabs

; main

(local right (move "x" 50))
(local left (move "x" -50))
(local up (move "y" -50))
(local down (move "y" 50))

(hs.hotkey.bind hyper "B" browser)
(bind-app-by-uti "T" "public.plain-text")
(bind-app "S" "kitty") ; "S=shell"
(bind-app "C" "kitty") ; "C=console"
(hs.grid.setGrid "9x6")
(hs.hotkey.bind hyper "G" hs.grid.show)
(hs.hotkey.bind hyper "L" set-layout)
(hs.hotkey.bind hyper "Right" right nil right)
(hs.hotkey.bind hyper "Left" left nil left)
(hs.hotkey.bind hyper "Up" up nil up)
(hs.hotkey.bind hyper "Down" down nil down)
(hs.hotkey.bind hyper "1" (move-active-window 1 2))
(hs.hotkey.bind hyper "2" (move-active-window 2 2))
(hs.hotkey.bind hyper "3" (move-active-window 1 3))
(hs.hotkey.bind hyper "4" (move-active-window 2 3))
(hs.hotkey.bind hyper "5" (move-active-window 3 3))
(hs.hotkey.bind hyper "6" (move-active-window 1 1))
(hs.hotkey.bind hyper "N" move-active-window-to-next-screen)
(hs.hotkey.bind hyper "A" show-audio-fuzzy)
(hs.hotkey.bind hyper "," #((show-window-fuzzy true))) ; app windows
(hs.hotkey.bind hyper "." show-window-fuzzy) ; all windows
(hs.hotkey.bind "alt" "tab" hs.window.switcher.nextWindow)
(hs.hotkey.bind "alt-shift" "tab" hs.window.switcher.previousWindow)

(local expose (hs.expose.new)) ; default windowfilter, no thumbnails
(local expose_app (hs.expose.new nil {"onlyActiveApplication" true})) ; show windows for the current application
(hs.hotkey.bind hyper "e" #(expose:toggleShow))
(hs.hotkey.bind hyper "u" #(expose_app:toggleShow))

(local shortcuts {
  ["Zoom toggle mute" ["us.zoom.xos" ["cmd" "shift"] "A"] zoom-mute-icon]
  ["Zoom toggle screen share" ["us.zoom.xos" ["cmd" "shift"] "S"]]
  ["Zoom toggle participants" ["us.zoom.xos" ["cmd"] "U"]]
  ["Zoom invite" ["us.zoom.xos" ["cmd"] "I"]]
})
(hs.hotkey.bind hyper "K" (show-shortcut-fuzzy shortcuts))
