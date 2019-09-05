### trackpad settings ###
for key in (
    'com.apple.AppleMultitouchTrackpad',
    'com.apple.driver.AppleBluetoothMultitouch.trackpad'
):
    trackpad = defaults[key]
    trackpad['Clicking'] = True  # touch to click

    # enable *both* methods of right clicking
    trackpad['TrackpadRightClick'] = True  # two finger tap
    trackpad['TrackpadCornerSecondaryClick'] = 2  # pushing to click in right corner

    # disable "smart zoom" because it puts a delay on two-finger-tap right click
    trackpad['TrackpadTwoFingerDoubleTapGesture'] = False

    trackpad['TrackpadThreeFingerDrag'] = True

# disable dashboard
defaults['com.apple.dashboard']['mcx-disabled'] = True

dock = defaults['com.apple.dock']
dock['show-recents'] = False
# http://www.defaults-write.com/enable-highlight-hover-effect-for-grid-view-stacks/
dock['mouse-over-hilite-stack'] = True
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
dock['wvous-bl-corner'] = 10  # bottom left: sleep
dock['wvous-bl-modifier'] = 0
dock['wvous-br-corner'] = 3  # bottom right: application windows
dock['wvous-br-modifier'] = 0
dock['wvous-tl-corner'] = 2  # top left: mission control
dock['wvous-tl-modifier'] = 0
dock['wvous-tr-corner'] = 4  # top right: desktop
dock['wvous-tr-modifier'] = 0

finder = defaults['com.apple.finder']
finder['ShowPathbar'] = True
finder['ShowStatusBar'] = True

# show battery % in menubar
defaults['com.apple.menuextra.battery']['ShowPercent'] = True

# key repeat rate and delay
defaults.g['InitialKeyRepeat'] = 10
defaults.g['KeyRepeat'] = 2

# set file-type associations
associations = {
    'com.microsoft.vscode': [
        # plain-text association has the side-effect of
        # controlling the default text editor (open -t)
        'public.plain-text',
        'public.python-script',
    ],
}
for program, types in associations.items():
    for type in types:
        run(['duti', '-s', program, type, 'all'])

# make tab move between "All Controls" (System Prefs -> Keyboard -> Shortcuts)
defaults.g['AppleKeyboardUIMode'] = 3

# show the date in the clock
defaults['com.apple.menuextra.clock']['DateFormat'] = "EEE MMM d  h:mm a"

# use function keys as function keys
defaults.g['com.apple.keyboard.fnState'] = True

# change spaces shortcuts away from ctrl + <- etc.
# todo

# zoom with ctrl+mouse wheel (System Prefs -> Accessibility -> Zoom)
defaults['com.apple.universalaccess']['closeViewScrollWheelToggle'] = True

flycut = defaults['com.generalarcade.flycut']
# shortcut to ctrl+cmd v
flycut["ShortcutRecorder mainHotkey"] = {'keyCode': 47, 'modifierFlags': 1310720}
flycut['loadOnStartup'] = 1
flycut['pasteMovesToTop'] = 1
flycut['removeDuplicates'] = 1

iterm = defaults['com.googlecode.iterm2']
iterm['PrefsCustomFolder'] = '~/.config/iterm2'
iterm['LoadPrefsFromCustomFolder'] = True

dash = defaults['com.kapeli.dashdoc']
dash['syncFolderPath'] = "~/Documents/Dash"
dash['snippetSQLPath'] = "~/Documents/Dash/snippets.dash"

# startup items - https://apple.stackexchange.com/a/310502/
script = 'tell application "System Events" to make login item at end with properties {{path:"/Applications/{app}.app", hidden:false}}'
for app in 'Flycut', 'SpotMenu', 'Flux', 'iTerm':
    run(['osascript', '-e', script.format(app=app)], cap='stdout')

# menubar items
menus = [
    '/System/Library/CoreServices/Menu Extras/{}.menu'.format(m)
    for m in ['Bluetooth', 'AirPort', 'Volume', 'TextInput', 'Battery', 'Clock', 'User']
]
current_menus = defaults['com.apple.systemuiserver']['menuExtras'].read()
menu_items_to_remove = set(current_menus) - set(menus)
if menu_items_to_remove:
    print("Removing:", menu_items_to_remove)
defaults['com.apple.systemuiserver']['menuExtras'] = menus
