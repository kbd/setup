(fn launch-app-for-uti [uti]
  (let [bundleid (hs.application.defaultAppForUTI uti)]
    (hs.application.launchOrFocusByBundleID bundleid)))

(fn move [axis increment]
  "Returns a fn that moves the focused window by the given increment along the given axis"
  #(let [win (hs.window.focusedWindow)
         f (win:frame)]
    (tset f axis (+ (. f axis) increment))
    (win:setFrame f)))

(fn get-windows-for-app-on-screen [appname screen]
  "Returns a list of windows for the given app on the given screen"
  (let [app (hs.application.get appname)]
    (if app
      (let [scr (or screen (hs.screen.mainScreen))
            wins (app:allWindows)]
        (icollect [_ win (ipairs wins)] ; filter windows by screen
          (if (= scr (win:screen)) win))))))

(fn lo [app x w]
  [app get-windows-for-app-on-screen hs.screen.mainScreen {: x :y 0 : w :h 1} nil nil])

(local layouts {
  "DELL U3818DW"
    [(lo "Firefox" 0 0.275) (lo "Code" 0.275 0.5) (lo "kitty" 0.775 0.225)]
  "Built-in Retina Display"
    [(lo "Firefox" 0 0.3) (lo "Code" 0.3 0.38) (lo "kitty" 0.68 0.32)]
})
(tset layouts "default" (. layouts "DELL U3818DW"))

(fn set-layout [name]
  (let [name (or name (: (hs.screen.primaryScreen) "name"))
        layout (or (. layouts name) layouts.default)]
    (hs.layout.apply layout)))

(fn set-window-fraction [app window num den screen]
  (let [coords {:x (/ (- num 1) den) :y 0 :w (/ 1 den) :h 1}
        layout [app window screen coords nil nil]]
    (hs.layout.apply [layout])))

(fn move-active-window [num den screen]
  "Moves the active window to the given dimensions"
  (let [app (hs.application.frontmostApplication)
        window (hs.window.focusedWindow)
        scr (or screen (window:screen))]
    (set-window-fraction app window num den scr)))

(fn move-active-window-to-next-screen []
  (let [w (hs.window.focusedWindow)]
    (w:moveToScreen (: (w:screen) "next"))))

(fn fuzzy [choices func]
  (doto (hs.chooser.new func)
    (: :choices choices)
    (: :searchSubText true)
    (: :fgColor {:hex "#bbf"})
    (: :subTextColor {:hex "#aaa"})
    (: :width 25)
    (: :show)))

(fn select-audio [audio]
  (if audio
    (let [device (hs.audiodevice.findDeviceByUID audio.uid)]
      (hs.alert.show (.. "Setting " audio.subText " device: " (device:name)))
      (if (device:isOutputDevice)
        (device:setDefaultOutputDevice)
        (device:setDefaultInputDevice)))))

(fn show-audio-fuzzy []
  (let [devices (hs.audiodevice.allDevices)
        input-uid (: (hs.audiodevice.defaultInputDevice) "uid")
        output-uid (: (hs.audiodevice.defaultOutputDevice) "uid")
        choices (icollect [_ device (ipairs devices)]
          (let [uid (device:uid)
                (active subText) (if (device:isOutputDevice)
                  (values (= uid output-uid) "output")
                  (values (= uid input-uid) "input"))
                text (device:name)
                subText (if active (.. subText " (active)") subText)
                uid (device:uid)
                valid (not active)]
            {: text : uid : subText : valid}))]
    (fuzzy choices select-audio)))

(fn select-window [window]
  (if window
    (: (hs.window.get window.id) "focus")))

(fn show-window-fuzzy [app]
  (let [app_images {}
        focused_id (: (hs.window.focusedWindow) "id")
        windows (if (= app nil) (hs.window.allWindows) ; all windows
          (= app true) (: (hs.application.frontmostApplication) "allWindows") ; focused app windows
          (app:allWindows)) ; specific app windows
        choices (icollect [_ window (ipairs windows)]
          (let [win-app (window:application)]
            (if (= (. app_images win-app) nil) ; cache the app image per app
              (tset app_images win-app (hs.image.imageFromAppBundle (win-app:bundleID))))
            (let [text (window:title)
                  id (window:id)
                  active (= id focused_id)
                  subText (.. (win-app:title) (if active " (active)" ""))
                  image (. app_images win-app)
                  valid (= id focused_id)]
              {: text : subText : image : valid : id})))]
    (fuzzy choices select-window)))

(fn execute-shortcut [shortcut]
  (if shortcut
    (let [action shortcut.action
          bundleid (. action 1)
          app (hs.application.applicationsForBundleID bundleid)]
      (if (= (length app) 0)
        (hs.application.launchOrFocusByBundleID bundleid))
      (hs.eventtap.keyStroke (. action 2) (. action 3) 0 (. app 1)))))

(fn show-shortcut-fuzzy [shortcuts]
  "Shows a fuzzy finder of app-specific shortcuts"
  (let [choices (icollect [_ shortcut (ipairs shortcuts)]
    (let [text (. shortcut 1)
          func (?. shortcut 3)
          subText (if func (func) nil)
          action (. shortcut 2)
          bundleid (. action 1)
          image (hs.image.imageFromAppBundle bundleid)
          valid true]
      {: text : subText : image : valid : action}))]
  (fuzzy choices execute-shortcut)))

(fn is-zoom-muted []
  (let [apps (hs.application.applicationsForBundleID "us.zoom.xos")]
    (if (not= (length apps) 0)
      (let [app (. apps 1)]
        (if (app:findMenuItem ["Meeting" "Unmute Audio"]) true
          (app:findMenuItem ["Meeting" "Mute Audio"]) false
          nil)))))

(fn zoom-mute-icon []
  (let [muted (is-zoom-muted)]
    (if (= nil muted) nil (if muted "🔴" "🟢" ))))

(local caffeine (hs.menubar.new))
(fn show-caffeine [awake]
  (caffeine:setTitle (if awake "☕" "🍵")))
(when caffeine
  (caffeine:setClickCallback #(show-caffeine (hs.caffeinate.toggle "displayIdle")))
  (show-caffeine (hs.caffeinate.get "displayIdle")))

(fn browser []
  "Activate browser. If already active, bring up vimium tab switcher."
  (let [browser-bundleid (hs.application.defaultAppForUTI "public.html")
        focused-app (hs.application.frontmostApplication)]
    (if (not= (focused-app:bundleID) browser-bundleid)
      (hs.application.launchOrFocusByBundleID browser-bundleid)
      (hs.eventtap.keyStroke ["shift"] "T" 0 focused-app)))) ; vimium switch tabs

; main

(local [right left up down]
  [(move "x" 50) (move "x" -50) (move "y" -50) (move "y" 50)])
(local expose (hs.expose.new)) ; default windowfilter, no thumbnails
(local expose_app (hs.expose.new nil {:onlyActiveApplication true})) ; show windows for the current application
(local shortcuts [
  ["Zoom toggle mute" ["us.zoom.xos" ["cmd" "shift"] "A"] zoom-mute-icon]
  ["Zoom toggle screen share" ["us.zoom.xos" ["cmd" "shift"] "S"]]
  ["Zoom toggle participants" ["us.zoom.xos" ["cmd"] "U"]]
  ["Zoom invite" ["us.zoom.xos" ["cmd"] "I"]]
])

(hs.grid.setGrid "9x6")
(hs.hotkey.bind hyper "G" hs.grid.show)
(hs.hotkey.bind hyper "B" browser)
(hs.hotkey.bind hyper "T" #(launch-app-for-uti "public.plain-text"))
(hs.hotkey.bind hyper "S" #(hs.application.launchOrFocus "kitty")) ; "S=shell"
(hs.hotkey.bind hyper "C" #(hs.application.launchOrFocus "kitty")) ; "C=console"
(hs.hotkey.bind hyper "L" set-layout)
(hs.hotkey.bind hyper "Right" right nil right)
(hs.hotkey.bind hyper "Left" left nil left)
(hs.hotkey.bind hyper "Up" up nil up)
(hs.hotkey.bind hyper "Down" down nil down)
(hs.hotkey.bind hyper "1" #(move-active-window 1 2))
(hs.hotkey.bind hyper "2" #(move-active-window 2 2))
(hs.hotkey.bind hyper "3" #(move-active-window 1 3))
(hs.hotkey.bind hyper "4" #(move-active-window 2 3))
(hs.hotkey.bind hyper "5" #(move-active-window 3 3))
(hs.hotkey.bind hyper "6" #(move-active-window 1 1))
(hs.hotkey.bind hyper "N" move-active-window-to-next-screen)
(hs.hotkey.bind hyper "A" show-audio-fuzzy)
(hs.hotkey.bind hyper "," #(show-window-fuzzy true)) ; app windows
(hs.hotkey.bind hyper "." show-window-fuzzy) ; all windows
(hs.hotkey.bind hyper "e" #(expose:toggleShow))
(hs.hotkey.bind hyper "u" #(expose_app:toggleShow))
(hs.hotkey.bind hyper "K" #(show-shortcut-fuzzy shortcuts))
(hs.hotkey.bind "alt" "tab" hs.window.switcher.nextWindow)
(hs.hotkey.bind "alt-shift" "tab" hs.window.switcher.previousWindow)
