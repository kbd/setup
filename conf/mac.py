# pylint:disable=no-name-in-module
from pathlib import Path

import pandas as pd
from aush import duti, mkdir, osascript, sudo

from lib.mac import defaults

### trackpad settings ###
for key in (
    'com.apple.AppleMultitouchTrackpad',
    'com.apple.driver.AppleBluetoothMultitouch.trackpad'
):
    trackpad = defaults[key]
    trackpad['Clicking'] = 1  # tap to click

    # enable *both* methods of right clicking
    trackpad['TrackpadRightClick'] = 1  # two finger tap
    trackpad['TrackpadCornerSecondaryClick'] = 2  # push to click in right corner

    # disable "smart zoom" because it puts a delay on two-finger-tap right click
    trackpad['TrackpadTwoFingerDoubleTapGesture'] = 0

    # drag and drop with three fingers
    trackpad['TrackpadThreeFingerDrag'] = 1

    # without unsetting this app expose with four fingers down is disabled?
    trackpad['TrackpadThreeFingerVertSwipeGesture'] = 0

# disable dashboard
defaults['com.apple.dashboard']['mcx-disabled'] = True

dock = defaults['com.apple.dock']
dock['autohide'] = True
dock['autohide-delay'] = .05
dock['autohide-time-modifier'] = 0.4
dock['show-recents'] = False
# http://www.defaults-write.com/enable-highlight-hover-effect-for-grid-view-stacks/
dock['mouse-over-hilite-stack'] = True
dock['appswitcher-all-displays'] = True  # show alt-tab chooser on all monitors

# Spaces
dock['mru-spaces'] = False  # don't reorder spaces based on use
defaults.g['AppleSpacesSwitchOnActivate'] = False  # don't switch to another space when alt tabbing

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
# for modifier values: https://blog.jiayu.co/2018/12/quickly-configuring-hot-corners-on-macos/
shift, ctrl, opt, cmd = (2**n for n in range(17,21))
dock['wvous-bl-corner'] = 10  # bottom left: sleep
dock['wvous-bl-modifier'] = ctrl
dock['wvous-br-corner'] = 3  # bottom right: application windows
dock['wvous-br-modifier'] = ctrl
dock['wvous-tl-corner'] = 2  # top left: mission control
dock['wvous-tl-modifier'] = ctrl
dock['wvous-tr-corner'] = 4  # top right: desktop
dock['wvous-tr-modifier'] = ctrl

finder = defaults['com.apple.finder']
finder['ShowPathbar'] = True
finder['ShowStatusBar'] = True

# show battery % in menubar
defaults['com.apple.menuextra.battery']['ShowPercent'] = True

# key repeat rate and delay
defaults.g['InitialKeyRepeat'] = 10
defaults.g['KeyRepeat'] = 1  # can this be a float? 1 seems a bit fast and 2 a bit slow

# turn on "shake mouse pointer to locate"
defaults.g['CGDisableCursorLocationMagnification'] = False

# set file-type associations
associations_path = Path(__file__).parent / "associations.csv"
associations = pd.read_csv(associations_path)
for _i, row in associations.iterrows():
    duti('-s', row.bundleid, row.uti, 'all')

# make tab move between "All Controls" (System Prefs -> Keyboard -> Shortcuts)
defaults.g['AppleKeyboardUIMode'] = 3

# show the date in the clock
defaults['com.apple.menuextra.clock']['DateFormat'] = "EEE MMM d HH:mm"

# use function keys as function keys
defaults.g['com.apple.keyboard.fnState'] = True

# don't change my keyboard layout by tapping the fn key!
defaults['com.apple.HIToolbox']['AppleFnUsageType'] = 0

# don't close windows when quitting program
defaults.g['NSQuitAlwaysKeepsWindows'] = True

# zoom with ctrl+mouse wheel (System Prefs -> Accessibility -> Zoom)
# commented out because it requires sudo, and then still seems to not take.
# Must set manually in System Prefs.
# defaults['com.apple.universalaccess']['closeViewScrollWheelToggle'] = True

# turn off touch-bar autocompletion (horrific! distracting!)
defaults.g['NSAutomaticTextCompletionEnabled'] = False

# startup items - https://apple.stackexchange.com/a/310502/
required_login_apps = {'SpotMenu', 'Alfred 5', 'Hammerspoon', 'Tinkle'}
cmd = 'tell application "System Events" to get the name of every login item'
current_login_apps = set(str(osascript(e=cmd)).split(', '))

script = 'tell application "System Events" to make login item at end with properties {{path:"/Applications/{app}.app", hidden:false}}'
print(f"Current login apps: {current_login_apps}. Required login apps: {required_login_apps}")
for app in required_login_apps - current_login_apps:
    print(f"Setting '{app}' to run on login")
    osascript(e=script.format(app=app))

# menubar items
# menus = [
#     '/System/Library/CoreServices/Menu Extras/{}.menu'.format(m)
#     for m in ['Bluetooth', 'Volume', 'AirPort', 'TextInput', 'Battery', 'Clock', 'Displays', 'User']
# ]
# current_menus = defaults['com.apple.systemuiserver']['menuExtras'].read()
# menu_items_to_remove = set(current_menus) - set(menus)
# if menu_items_to_remove:
#     print("Removing:", menu_items_to_remove)
# defaults['com.apple.systemuiserver']['menuExtras'] = menus

# set order of menubar items
# must restart computer for this to take effect
# to find all values: defaults find "NSStatusItem Preferred Position"
position_key = "NSStatusItem Preferred Position"
visible_key = "NSStatusItem Visible"
menuitems = [
    ('com.apple.controlcenter', 'Clock'),
    ('com.apple.systemuiserver', 'Siri'),
    ('com.apple.controlcenter', 'BentoBox'), # control center
    ('com.apple.TextInputMenuAgent', 'Item-0'), # us/dvorak
    ('com.apple.Spotlight', 'Item-0'),
    ('com.apple.controlcenter', 'Battery'),
    ('com.apple.controlcenter', 'WiFi'),
    ('com.apple.controlcenter', 'Bluetooth'),
    ('com.apple.controlcenter', 'Display'),
    ('com.apple.controlcenter', 'Sound'),
    ('com.apple.controlcenter', 'NowPlaying'),
    ('com.apple.controlcenter', 'ScreenMirroring'),
    ('85C27NK92C.com.flexibits.fantastical2.mac.helper', 'Fantastical'),
    ('com.agilebits.onepassword7', 'Item-0'),
    ('org.pqrs.Karabiner-Menu', 'Item-0'),
    ('org.hammerspoon.Hammerspoon', 'Item-0'),  # must quit hammerspoon before running for this to take effect
    ('org.pqrs.Tinkle', 'Item-0'),
    ('com.runningwithcrayons.Alfred', 'Item-0'),
    ('com.KMikiy.SpotMenu', 'Item-0'),
]
increment = 10.0
value = increment
for domain, key in menuitems:
    value += increment
    print(f"Setting menubar position {domain} {key} = {value}")
    defaults[domain][f"{position_key} {key}"] = value
    defaults[domain][f"{visible_key} {key}"] = True

# screenshots
screenshot_dir = str(Path('~/Desktop/Screenshots').expanduser())
mkdir['-p'](screenshot_dir)
screenshots = defaults['com.apple.screencapture']
screenshots['location'] = screenshot_dir
screenshots['show-thumbnail'] = False
screenshots['disable-shadow'] = True

# turn off "hey Siri" (on Mac, triggers more by accident than on purpose)
defaults['com.apple.Siri']['VoiceTriggerUserEnabled'] = False

# screen settings. screensaver 7 minutes, monitor power 10 minutes
defaults.currentHost["com.apple.screensaver"]["idleTime"] = 420
defaults.currentHost["com.apple.screensaver"]["showClock"] = True
sudo.pmset.displaysleep(10)
