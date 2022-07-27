(local ZOOM-BUNDLEID "us.zoom.xos")
(var ZOOM nil)
(var ZOOMENU nil)
(var WATCHER nil)

(fn audio-on [zoom] (zoom:findMenuItem ["Meeting" "Mute Audio"]))
(fn video-on [zoom] (zoom:findMenuItem ["Meeting" "Stop Video"]))
(fn share-on [zoom] (zoom:findMenuItem ["Meeting" "Stop Share"]))

(fn indicator [setting]
  (if setting "🟢" "🔴"))

(fn title []
  (.. "Zoom: "
    "A:" (indicator (audio-on ZOOM))
    "V:" (indicator (video-on ZOOM))
    "S:" (indicator (share-on ZOOM))))

(fn to-zoom [mods char]
  (when ZOOM
    (hs.eventtap.keyStroke mods char 0 ZOOM)
    (ZOOMENU:setTitle (title))))

(fn toggle-audio [] (to-zoom ["cmd" "shift"] "A"))
(fn toggle-video [] (to-zoom ["cmd" "shift"] "V"))
(fn toggle-share [] (to-zoom ["cmd" "shift"] "S"))
(fn toggle-participants [] (to-zoom ["cmd"] "U"))
(fn toggle-invite [] (to-zoom ["cmd"] "I"))

(fn create-zoom-menu [zoom-app]
  (let [menu-table [
        { :title "Toggle audio" :fn toggle-audio }
        { :title "Toggle video" :fn toggle-video }
        { :title "Toggle screen share" :fn toggle-share }
        { :title "Toggle participants" :fn toggle-participants }
        { :title "Invite" :fn toggle-invite }]]
    (set ZOOM zoom-app)
    (set ZOOMENU (hs.menubar.new))
    (doto ZOOMENU
      (: :setTitle (title))
      (: :setMenu menu-table))))

(fn destroy-zoom-menu []
  (when ZOOMENU
    (ZOOMENU:delete)
    (set ZOOM nil)))

(fn watch-zoom [name type app]
  (if (= type hs.application.watcher.launched)
        (if (= (app:bundleID) ZOOM-BUNDLEID)
          (create-zoom-menu app))
      (= type hs.application.watcher.terminated)
        (if (= (app:pid) (ZOOM:pid))
          (destroy-zoom-menu))))

; todo: the menubar doesn't update if setting changed directly in zoom
; maybe add poll while app is open to fetch the status every couple seconds
(fn init []
  ; check if app is running, if so create menu
  (let [zoom-app (hs.application.get ZOOM-BUNDLEID)]
    (when zoom-app
      (create-zoom-menu zoom-app))
  (set WATCHER (hs.application.watcher.new watch-zoom))
  (WATCHER:start)))

{ :init init
  :toggle-audio toggle-audio
  :toggle-video toggle-video
  :toggle-share toggle-share
  :toggle-participants toggle-participants
  :toggle-invite toggle-invite }
