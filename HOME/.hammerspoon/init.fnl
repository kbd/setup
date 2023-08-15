; constants (reload Hammerspoon config to rebind)
(local browser-bundleid (hs.application.defaultAppForUTI "public.html"))
(local browser-name (hs.application.nameForBundleID browser-bundleid))
(local editor-bundleid (hs.application.defaultAppForUTI "public.plain-text"))
(local editor-name (hs.application.nameForBundleID editor-bundleid))
(local notes-bundleid "md.obsidian")
(local music-bundleid "com.spotify.client")
(local tasks-bundleid "com.TickTick.task.mac")
(local projects-bundleid "com.electron.asana")
(local messages-bundleid "com.apple.MobileSMS")
; unfortunately for terminal there's no default association like with html/text
(local terminal-name "kitty")
(local terminal-bundleid "net.kovidgoyal.kitty")
(local terminal-app-image (hs.image.imageFromAppBundle terminal-bundleid))

(fn get-windows-for-app-on-screen [appname screen]
  "Returns a list of windows for the given app on the given screen"
  (let [app (hs.application.get appname)]
    (if app
      (let [scr (or screen (hs.screen.mainScreen))
            wins (app:allWindows)]
        (icollect [_ win (ipairs wins)] ; filter windows by screen
          (if (= scr (win:screen)) win))))))

(fn lo [appname x w]
  [(hs.application.get appname) get-windows-for-app-on-screen hs.screen.mainScreen {: x :y 0 : w :h 1} nil nil])

(local layouts {
  "DELL U3818DW"
    [[browser-name 0 0.275] [editor-name 0.275 0.5] [terminal-name 0.775 0.225]]
  "Built-in Retina Display"
    [[browser-name 0 0.3] [editor-name 0.3 0.38] [terminal-name 0.68 0.32]]
})
(tset layouts "default" (. layouts "DELL U3818DW"))

(fn move [axis increment]
  "Moves the focused window by the given increment along the given axis"
  (let [win (hs.window.focusedWindow)
        f (win:frame)]
    (tset f axis (+ (. f axis) increment))
    (win:setFrame f)))

(fn layout-with-enhanced-interface-off [layout]
  (let [app (. layout 1)
        el (hs.axuielement.applicationElement app)
        enhanced el.AXEnhancedUserInterface]
    (set el.AXEnhancedUserInterface false)
    (hs.layout.apply [layout])
    (set el.AXEnhancedUserInterface enhanced)))

(fn set-layout [layouts name]
  (let [name (or name (: (hs.screen.primaryScreen) :name))
        layout (or (. layouts name) layouts.default)]
    (each [_ l (pairs layout)]
      (layout-with-enhanced-interface-off (lo (table.unpack l))))))

(fn set-window-fraction [app window num den screen numwidth]
  (let [coords (hs.geometry.rect (/ num den) 0 (/ numwidth den) 1)
        layout [app window screen coords]]
    (layout-with-enhanced-interface-off layout)))

(fn move-active-window [num den numwidth screen]
  "Moves the active window to the given dimensions"
  (let [numwidth (or numwidth 1)
        app (hs.application.frontmostApplication)
        window (hs.window.focusedWindow)
        scr (or screen (window:screen))]
    (set-window-fraction app window num den scr numwidth)))

(fn move-active-window-to-next-screen []
  (let [w (hs.window.focusedWindow)]
    (w:moveToScreen (: (w:screen) :next))))

(fn fuzzy [choices func]
  (doto (hs.chooser.new func)
    (: :searchSubText true)
    (: :fgColor {:hex "#bbf"})
    (: :subTextColor {:hex "#aaa"})
    (: :width 25)
    (: :show)
    (: :choices choices)))

(fn select-audio [audio]
  (if audio
    (let [device (hs.audiodevice.findDeviceByUID audio.uid)]
      (hs.alert.show (.. "Setting " audio.subText " device: " (device:name)))
      (if (device:isOutputDevice)
        (device:setDefaultOutputDevice)
        (device:setDefaultInputDevice)))))

(fn show-audio-fuzzy []
  (let [devices (hs.audiodevice.allDevices)
        input-uid (: (hs.audiodevice.defaultInputDevice) :uid)
        output-uid (: (hs.audiodevice.defaultOutputDevice) :uid)
        choices #(icollect [_ device (ipairs devices)]
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
  (when window (window.window:focus)))

; todo: fix: if no focused window, gives "attempt to index a nil value"
(fn show-window-fuzzy [app]
  (let [app-images {}
        focused-id (: (hs.window.focusedWindow) :id)
        windows (if (= app nil) (hs.window.orderedWindows)
                  (= app true) (: (hs.application.frontmostApplication) :allWindows)
                  (= (type app) "string") (: (hs.application.open app) :allWindows)
                  (app:allWindows))
        choices #(icollect [_ window (ipairs windows)]
                  (let [win-app (window:application)]
                    (if (= (. app-images win-app) nil) ; cache the app image per app
                      (tset app-images win-app (hs.image.imageFromAppBundle (win-app:bundleID))))
                    (let [text (window:title)
                          id (window:id)
                          active (= id focused-id)
                          subText (.. (win-app:title) (if active " (active)" ""))
                          image (. app-images win-app)
                          valid (= id focused-id)]
                      {: text : subText : image : valid : window})))]
    (fuzzy choices select-window)))

(fn show-app [bundleid func]
  "Activate app with bundleid.

  If already active, call (func or show-window-fuzzy)(app)"
  (let [focused-app (hs.application.frontmostApplication)]
    (if (not= bundleid (focused-app:bundleID))
      (hs.application.launchOrFocusByBundleID bundleid)
      ((or func show-window-fuzzy) focused-app))))

(fn toggle-window [new-window command]
  "Activates new-window. If new-window is already active, goes back to prior."
  (let [current-window (hs.window.focusedWindow)]
    (if (= new-window current-window)
      (let [last _G.last_window] (when last (last:focus)))
      (if new-window (new-window:focus) (command))
    (set _G.last_window current-window))))

(fn specific-vscode-window [path]
  (toggle-window (hs.window.find (.. "^" path)) #(hs.execute (.. "code " path) true)))

(fn get-previous-window []
  "Returns a window object for the most-recent window"
  (let [windows (hs.window.orderedWindows)]
    (var found-one false) ; return the second "normal" window
    (for [i 1 (length windows)]
      (let [w (. windows i)]
        (when (not= (w:subrole) "AXUnknown")
          (if found-one (lua "return w") (set found-one true)))))))

(fn focus-previous-window []
  (: (get-previous-window) :focus))

(fn vimium-tab-switcher [] ; open vimium tab switcher in active browser
  (hs.eventtap.keyStroke [] "ESCAPE")
  (hs.eventtap.keyStroke ["shift"] "T"))

(fn kitty-socket [kitty-pid]
  (.. "unix:/tmp/mykitty-" kitty-pid))

(fn get-kitty-windows [kitty-pid]
  (let [socket (kitty-socket kitty-pid)
        kitty-cmd (.. "kitty @ --to " socket " ls")
        jq-cmd "jq '[.[].tabs[].windows[] | {id, title, is_focused}]'"
        cmd (.. kitty-cmd " | " jq-cmd)
        (output status type rc) (hs.execute cmd true)
        windows (hs.json.decode output)]
    windows))

(fn select-kitty-window [kitty-pid choice]
  (when choice
    (let [kitty-cmd (.. "kitty @ --to " (kitty-socket kitty-pid) " focus-window -m \"id:" choice.wid "\"")]
      (hs.execute kitty-cmd true))))

(fn kitty-window-switcher [kitty-instance]
  (var active-index 1)
  (let [pid (kitty-instance:pid)
        windows (get-kitty-windows pid)
        image terminal-app-image ; cached on HS init
        choices (icollect [index window (ipairs windows)]
          (let [text window.title
                wid window.id]
            (when window.is_focused (set active-index index))
            {: text : image : wid }))]
    (let [chooser (fuzzy choices #(select-kitty-window pid $1))]
      (chooser:selectedRow active-index))))

; "main"

(hs.grid.setGrid "9x6")
(set hs.window.animationDuration 0)

; the default global chooser callback seems to be incorrect:
; if a chooser is opened when one is already open, closing it doesn't properly
;   restore focus. Seems to work properly without?
(tset hs.chooser :globalCallback nil)

(local caffeine (hs.menubar.new))
(when caffeine
  (let [show-caffeine #(caffeine:setTitle (if $1 "☕" "🍵"))]
    (caffeine:setClickCallback #(show-caffeine (hs.caffeinate.toggle "displayIdle")))
    (show-caffeine (hs.caffeinate.get "displayIdle"))))

(local [left right up down]
  [#(move "x" -50) #(move "x" 50) #(move "y" -50) #(move "y" 50)])
(local expose (hs.expose.new)) ; default windowfilter, no thumbnails
(local expose-app (hs.expose.new nil {:onlyActiveApplication true})) ; show windows for the current application

; keybinds
(hs.hotkey.bind hyper "G" hs.grid.show)
(hs.hotkey.bind hyper "B" #(show-app browser-bundleid vimium-tab-switcher))
(hs.hotkey.bind hyper "T" #(show-app editor-bundleid))
(hs.hotkey.bind hyper "S" #(show-app terminal-bundleid kitty-window-switcher)) ; "S=shell"
(hs.hotkey.bind hyper "M" #(show-app music-bundleid focus-previous-window))
(hs.hotkey.bind hyper "J" #(show-app projects-bundleid focus-previous-window))
(hs.hotkey.bind hyper "K" #(show-app tasks-bundleid focus-previous-window))
(hs.hotkey.bind hyper "N" #(show-app notes-bundleid focus-previous-window))
(hs.hotkey.bind hyper "-" #(show-app messages-bundleid focus-previous-window))
(hs.hotkey.bind hyper "L" #(set-layout layouts $1))
(hs.hotkey.bind hyper "Right" right nil right)
(hs.hotkey.bind hyper "Left" left nil left)
(hs.hotkey.bind hyper "Up" up nil up)
(hs.hotkey.bind hyper "Down" down nil down)
(hs.hotkey.bind hyper "1" #(move-active-window 0 2))
(hs.hotkey.bind hyper "2" #(move-active-window 1 2))
(hs.hotkey.bind hyper "3" #(move-active-window 0 3))
(hs.hotkey.bind hyper "4" #(move-active-window 1 3))
(hs.hotkey.bind hyper "5" #(move-active-window 2 3))
(hs.hotkey.bind hyper "6" #(move-active-window 0 3 2)) ; two-thirds, left
(hs.hotkey.bind hyper "7" #(move-active-window 1 3 2)) ; two-thirds, right
(hs.hotkey.bind hyper "8" #(move-active-window 1 4 2)) ; half-screen, center
(hs.hotkey.bind hyper "9" #(move-active-window 0 1))
(hs.hotkey.bind hyper "0" focus-previous-window)
(hs.hotkey.bind hyper "E" move-active-window-to-next-screen)
(hs.hotkey.bind hyper "A" show-audio-fuzzy)
(hs.hotkey.bind hyper "," #(show-window-fuzzy true)) ; app windows
(hs.hotkey.bind hyper hs.keycodes.map.space show-window-fuzzy) ; all windows
(hs.hotkey.bind hyper "X" #(expose:toggleShow))
(hs.hotkey.bind hyper "U" #(expose-app:toggleShow))
(hs.hotkey.bind hyper "D" #(specific-vscode-window "~/setup"))
(hs.hotkey.bind "alt" "tab" hs.window.switcher.nextWindow)
(hs.hotkey.bind "alt-shift" "tab" hs.window.switcher.previousWindow)

; import zoom
(fn init-zoom []
  (local zoom (require :zoom))
  (zoom.init)

  ; todo: support cross-app functions like "toggle mute" in app-independent way
  (hs.hotkey.bind hyper "M" zoom.toggle-audio)

  ; arbitrary-function fuzzy chooser
  (local choices [
    {:text "Zoom toggle audio"        :fn zoom.toggle-audio}
    {:text "Zoom toggle video"        :fn zoom.toggle-video}
    {:text "Zoom toggle screen share" :fn zoom.toggle-share}
    {:text "Zoom toggle participants" :fn zoom.toggle-participants}
    {:text "Zoom invite"              :fn zoom.toggle-invite}
  ])
  ; can't pass a function value to chooser directly, so indirect through a lookup
  (local lookup {})
  (each [i v (ipairs choices)]
    (let [name (tostring v.fn)] ; tostring(fn) -> "function: 0x6000023f43c0"
      (tset lookup name v.fn)
      (tset v :fn name)))

  (hs.hotkey.bind hyper "O" #(fuzzy choices #(when $1 ((. lookup $1.fn))))))

; (init-zoom)

; "exports"
(tset _G :taskMenu (hs.menubar.new))
(tset _G :focusPreviousWindow focus-previous-window)
