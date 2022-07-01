(fn is-zoom-muted []
  (let [apps (hs.application.applicationsForBundleID "us.zoom.xos")]
    (match apps [app]
      (if (app:findMenuItem ["Meeting" "Unmute Audio"]) true
          (app:findMenuItem ["Meeting" "Mute Audio"]) false))))

(fn is-zoom-video-on []
  (let [apps (hs.application.applicationsForBundleID "us.zoom.xos")]
    (match apps [app]
      (if (app:findMenuItem ["Meeting" "Start Video"]) true
          (app:findMenuItem ["Meeting" "Stop Video"]) false))))

(fn zoom-mute-icon []
  (match (is-zoom-muted) true "🔴" false "🟢"))


(local toggle-mute-shortcut ["us.zoom.xos" ["cmd" "shift"] "A"])
(fn toggle-mute [] (
  (do
    (inspect "Executing toggle zoom mute")
    (execute-shortcut toggle-mute-shortcut))))

(local shortcuts [
  ["Zoom toggle mute"         toggle-mute-shortcut                zoom-mute-icon]
  ["Zoom toggle screen share" ["us.zoom.xos" ["cmd" "shift"] "S"]]
  ["Zoom toggle participants" ["us.zoom.xos" ["cmd"]         "U"]]
  ["Zoom invite"              ["us.zoom.xos" ["cmd"]         "I"]]
])

; if I only update the menubar status when:
;   - the zoom window gets focus - set poll on focus and remove poll on de-focus
;   -
; really what you should do is:
; - only add the menubar widget when Zoom (or other apps) are actually open that can we can track whether they're muted or not. Then poll. Close Zoom when not in use. Set a global keyboard shortcut for mute/unmute (hyper+M). Maybe in the menubar, show status for: A:🟢V:🔴S:🔴 (audio, video, screen). Maybe you can make the drop down from the widget itself a mute/unmute, video/no video etc. menu a keyboard shortcut so you don't need to shoe-horn a bunch of random commands into your Hammerspoon fuzzy finder.

(local zoom-status (hs.menubar.new))

(fn show-zoom-mute-status [muted]
  (zoom-status:setTitle (if muted "🔴" "🟢")))

(when zoom-status
  (zoom-status:setClickCallback #(
    (do
      (toggle-mute)
      (show-zoom-mute-status (is-zoom-muted))))))

; 1. initialize: set up import hook on zoom launch that sets up the menubar icon and closes it on zoom exit
; 2. all of these options are on a dropdown in the zoom menu that can each have their own shortcuts
; 3. update toggle-mute to include a global toggle mute. If zoom not running "msg zoom not running nothing to mute".
(fn initialize []
  (print "got here"))
