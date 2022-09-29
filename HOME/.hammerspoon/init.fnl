(fn move [axis increment]
  "Moves the focused window by the given increment along the given axis"
  (let [win (hs.window.focusedWindow)
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

(fn set-layout [layouts name]
  (let [name (or name (: (hs.screen.primaryScreen) :name))
        layout (or (. layouts name) layouts.default)]
    (hs.layout.apply layout)))

(fn set-window-fraction [app window num den screen numwidth]
  (let [coords {:x (/ num den) :y 0 :w (/ numwidth den) :h 1}
        layout [app window screen coords nil nil]]
    (hs.layout.apply [layout])))

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

; "main"

(local browser "Orion")
(local editor "Code")
(local terminal "kitty")
(local terminal-bundleid "net.kovidgoyal.kitty") ; there's no default association like with html/text

(hs.grid.setGrid "9x6")

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

(local layouts {
  "DELL U3818DW"
    [(lo browser 0 0.275) (lo editor 0.275 0.5) (lo terminal 0.775 0.225)]
  "Built-in Retina Display"
    [(lo browser 0 0.3) (lo editor 0.3 0.38) (lo terminal 0.68 0.32)]
})
(tset layouts "default" (. layouts "DELL U3818DW"))

; keybinds
(hs.hotkey.bind hyper "G" hs.grid.show)
(hs.hotkey.bind hyper "B" #(show-app (hs.application.defaultAppForUTI "public.html") vimium-tab-switcher))
(hs.hotkey.bind hyper "T" #(show-app (hs.application.defaultAppForUTI "public.plain-text")))
(hs.hotkey.bind hyper "S" #(show-app terminal-bundleid)) ; "S=shell"
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
(hs.hotkey.bind hyper "N" move-active-window-to-next-screen)
(hs.hotkey.bind hyper "A" show-audio-fuzzy)
(hs.hotkey.bind hyper "," #(show-window-fuzzy true)) ; app windows
(hs.hotkey.bind hyper hs.keycodes.map.space show-window-fuzzy) ; all windows
(hs.hotkey.bind hyper "e" #(expose:toggleShow))
(hs.hotkey.bind hyper "u" #(expose-app:toggleShow))
(hs.hotkey.bind hyper "K" #(show-app "com.electron.logseq"))
(hs.hotkey.bind hyper "D" #(specific-vscode-window "~/setup"))
(hs.hotkey.bind "alt" "tab" hs.window.switcher.nextWindow)
(hs.hotkey.bind "alt-shift" "tab" hs.window.switcher.previousWindow)

; import zoom
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

(hs.hotkey.bind hyper "O" #(fuzzy choices #(when $1 ((. lookup $1.fn)))))

; "exports"
(tset _G :taskMenu (hs.menubar.new))
(tset _G :focusPreviousWindow focus-previous-window)
