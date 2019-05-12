#!/bin/sh

### trackpad settings ###
for key in com.apple.AppleMultitouchTrackpad com.apple.driver.AppleBluetoothMultitouch.trackpad; do
    defaults write $key Clicking -boolean True # touch to click

    # enable *both* methods of right clicking
    defaults write $key TrackpadRightClick -boolean True # two finger tap
    defaults write $key TrackpadCornerSecondaryClick -integer 2 # pushing to click in right corner

    # disable "smart zoom" because it puts a delay on two-finger-tap right click
    defaults write $key TrackpadTwoFingerDoubleTapGesture -boolean False

    defaults write $key TrackpadThreeFingerDrag -boolean True
done


# disable dashboard
defaults write com.apple.dashboard mcx-disabled -boolean True

# http://www.defaults-write.com/enable-highlight-hover-effect-for-grid-view-stacks/
defaults write com.apple.dock mouse-over-hilite-stack -boolean True


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
defaults write com.apple.dock wvous-bl-corner -integer 10
defaults write com.apple.dock wvous-bl-modifier -integer 0

# bottom right: application windows
defaults write com.apple.dock wvous-br-corner -integer 3
defaults write com.apple.dock wvous-br-modifier -integer 0

# top left: mission control
defaults write com.apple.dock wvous-tl-corner -integer 2
defaults write com.apple.dock wvous-tl-modifier -integer 0

# top right: desktop
defaults write com.apple.dock wvous-tr-corner -integer 4
defaults write com.apple.dock wvous-tr-modifier -integer 0


# finder
defaults write com.apple.finder ShowPathbar -boolean True
defaults write com.apple.finder ShowStatusBar -boolean True

# show battery % in menubar
defaults write com.apple.menuextra.battery ShowPercent -boolean True

# key repeat rate and delay
defaults write NSGlobalDomain InitialKeyRepeat -integer 10
defaults write NSGlobalDomain KeyRepeat -integer 2

# set default text file association to vscode
duti -s com.microsoft.vscode public.plain-text all

# make tab move between "All Controls" (System Prefs -> Keyboard -> Shortcuts)
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

# show the date in the clock
defaults write com.apple.menuextra.clock DateFormat "EEE MMM d  h:mm a"

# use function keys as function keys
defaults write -g com.apple.keyboard.fnState true

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

# startup items - https://apple.stackexchange.com/a/310502/
for app in Flycut SpotMenu Flux iTerm; do
  osascript -e 'tell application "System Events" to make login item at end with properties {path:"/Applications/'$app'.app", hidden:false}' > /dev/null
done
