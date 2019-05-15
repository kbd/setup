#!/bin/sh

### trackpad settings ###
for key in com.apple.AppleMultitouchTrackpad com.apple.driver.AppleBluetoothMultitouch.trackpad; do
    defaults write $key Clicking -bool true # touch to click

    # enable *both* methods of right clicking
    defaults write $key TrackpadRightClick -bool true # two finger tap
    defaults write $key TrackpadCornerSecondaryClick -int 2 # pushing to click in right corner

    # disable "smart zoom" because it puts a delay on two-finger-tap right click
    defaults write $key TrackpadTwoFingerDoubleTapGesture -bool false

    defaults write $key TrackpadThreeFingerDrag -bool true
done


# disable dashboard
defaults write com.apple.dashboard mcx-disabled -bool true

# http://www.defaults-write.com/enable-highlight-hover-effect-for-grid-view-stacks/
defaults write com.apple.dock mouse-over-hilite-stack -bool true


# hot corners
# Possible values:
#  0: no-op
#  2: Mission Control
#  3: Show application windows
#  4: Desktop
#  5: Start screen saver
#  6: Disable screen saver
#  7: Dashboard
# 10: Put display to sleep
# 11: Launchpad
# 12: Notification Center

# bottom left: sleep
defaults write com.apple.dock wvous-bl-corner -int 10
defaults write com.apple.dock wvous-bl-modifier -int 0

# bottom right: application windows
defaults write com.apple.dock wvous-br-corner -int 3
defaults write com.apple.dock wvous-br-modifier -int 0

# top left: mission control
defaults write com.apple.dock wvous-tl-corner -int 2
defaults write com.apple.dock wvous-tl-modifier -int 0

# top right: desktop
defaults write com.apple.dock wvous-tr-corner -int 4
defaults write com.apple.dock wvous-tr-modifier -int 0


# finder
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true

# show battery % in menubar
defaults write com.apple.menuextra.battery ShowPercent -bool true

# key repeat rate and delay
defaults write -g InitialKeyRepeat -int 10
defaults write -g KeyRepeat -int 2

# set default text file association to vscode
duti -s com.microsoft.vscode public.plain-text all

# make tab move between "All Controls" (System Prefs -> Keyboard -> Shortcuts)
defaults write -g AppleKeyboardUIMode -int 3

# show the date in the clock
defaults write com.apple.menuextra.clock DateFormat "EEE MMM d  h:mm a"

# use function keys as function keys
defaults write -g com.apple.keyboard.fnState -bool true

# change spaces shortcuts away from ctrl + <- etc.
# todo

# zoom with ctrl+mouse wheel (System Prefs -> Accessibility -> Zoom)
defaults write com.apple.universalaccess closeViewScrollWheelToggle -bool true

# flycut preferences
# shortcut to ctrl+cmd v
defaults write com.generalarcade.flycut "ShortcutRecorder mainHotkey" -dict keyCode -int 47 modifierFlags -int 1310720
defaults write com.generalarcade.flycut loadOnStartup -int 1
defaults write com.generalarcade.flycut pasteMovesToTop -int 1
defaults write com.generalarcade.flycut removeDuplicates -int 1

# iterm preferences
defaults write com.googlecode.iterm2.plist PrefsCustomFolder '~/.config/iterm2'
defaults write com.googlecode.iterm2.plist LoadPrefsFromCustomFolder -bool true

# startup items - https://apple.stackexchange.com/a/310502/
for app in Flycut SpotMenu Flux iTerm; do
  osascript -e 'tell application "System Events" to make login item at end with properties {path:"/Applications/'$app'.app", hidden:false}' > /dev/null
done
