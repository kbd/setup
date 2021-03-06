# type: ignore

# silence linter errors
defaults = defaults
run = run

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
dock['autohide'] = False
dock['autohide-delay'] = .05
dock['autohide-time-modifier'] = 0.4
dock['show-recents'] = False
# http://www.defaults-write.com/enable-highlight-hover-effect-for-grid-view-stacks/
dock['mouse-over-hilite-stack'] = True

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

# turn on "shake mouse pointer to locate"
defaults.g['CGDisableCursorLocationMagnification'] = False

# set file-type associations
associations = {
    'com.microsoft.vscode': [
        # plain-text association also sets default text editor (open -t)
        'public.plain-text',
        'public.python-script',
        'public.yaml',
    ],
    'org.videolan.vlc': [
        'public.mp3',
        'public.mpeg-4',
        'org.matroska.mkv',
        'org.videolan.webm',
    ],
    'org.libreoffice.script': [
        'public.comma-separated-values-text',
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

# don't close windows when quitting program (required for iterm2 to restore windows)
defaults.g['NSQuitAlwaysKeepsWindows'] = True

# zoom with ctrl+mouse wheel (System Prefs -> Accessibility -> Zoom)
defaults['com.apple.universalaccess']['closeViewScrollWheelToggle'] = True

flycut = defaults['com.generalarcade.flycut']
# shortcut to ctrl+cmd v
flycut["ShortcutRecorder mainHotkey"] = {'keyCode': 47, 'modifierFlags': 1310720}
flycut['loadOnStartup'] = 1
flycut['pasteMovesToTop'] = 1
flycut['removeDuplicates'] = 1
flycut['savePreference'] = 2  # "after each clip"

iterm = defaults['com.googlecode.iterm2']
iterm['PrefsCustomFolder'] = '~/.config/iterm2'
iterm['LoadPrefsFromCustomFolder'] = True
iterm['HotkeyTermAnimationDuration'] = 0

dash = defaults['com.kapeli.dashdoc']
dash['syncFolderPath'] = "~/Documents/Dash"
dash['snippetSQLPath'] = "~/Documents/Dash/snippets.dash"

caffeine = defaults['com.intelliscapesolutions.caffeine']
caffeine['ActivateOnLaunch'] = False
caffeine['SuppressLaunchMessage'] = True

# startup items - https://apple.stackexchange.com/a/310502/
required_login_apps = {'Flycut', 'SpotMenu', 'Flux', 'iTerm', 'Alfred 4', 'Horo', 'Caffeine'}
current_login_apps = set(
    filter(None,
        run(['osascript', '-e' 'tell application "System Events" to get the name of every login item'], cap='stdout').strip().split(', ')
    )
)

script = 'tell application "System Events" to make login item at end with properties {{path:"/Applications/{app}.app", hidden:false}}'
print(f"Current login apps: {current_login_apps}. Required login apps: {required_login_apps}")
for app in required_login_apps - current_login_apps:
    print(f"Setting '{app}' to run on login")
    run(['osascript', '-e', script.format(app=app)])

# menubar items
menus = [
    '/System/Library/CoreServices/Menu Extras/{}.menu'.format(m)
    for m in ['Bluetooth', 'Volume', 'AirPort', 'TextInput', 'Battery', 'Clock', 'Displays', 'User']
]
current_menus = defaults['com.apple.systemuiserver']['menuExtras'].read()
menu_items_to_remove = set(current_menus) - set(menus)
if menu_items_to_remove:
    print("Removing:", menu_items_to_remove)
defaults['com.apple.systemuiserver']['menuExtras'] = menus

# screenshots
screenshot_dir = '~/Desktop/Screenshots'
run(f"mkdir -p {screenshot_dir}")
screenshots = defaults['com.apple.screencapture']
screenshots['location'] = screenshot_dir
screenshots['show-thumbnail'] = False
screenshots['disable-shadow'] = True

# turn off "hey Siri" (on Mac, triggers more by accident than on purpose)
defaults['com.apple.Siri']['VoiceTriggerUserEnabled'] = False
