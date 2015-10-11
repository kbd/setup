{
    'actions': {
        'status': {
            'func': 'repo',
            'cmd': ['status'],
            'help': 'Get repository status'
        },
        'diff': {
            'func': 'repo',
            'cmd': ['difftool'],
            'help': 'Get repository diff'
        },
        'commit': {
            'func': 'repo',
            'cmd': ['commit', '-am', '{message}'],
            'args': [
                ('message', {'help': 'The commit message'})
            ],
            'help': 'Commit to repository'
        },
        'pull': {
            'func': 'repo',
            'cmd': ['pull'],
            'help': 'Pull repository from server',
            'aliases': ['update'],
        },
        'push': {
            'func': 'repo',
            'cmd': ['push'],
            'help': 'Push repository to server'
        },
        'fix_usrlocal': {
            'func': 'ensure_correct_usrlocal_permissions',
            'help': 'Ensure /usr/local is owned by the current user'
        },
        'brew': {
            'func': 'brew',
            'args': [
                ('fix_repo', {'help': 'Fix a broken repository', 'optional': True})
            ],
            # initial space because the beermug takes up two character spaces
            # and overlaps if you don't pad it with a space afterwards
            'help': "\U0001F37A Homebrew\U0001F37A"
        },
        'packages': {
            'func': 'packages',
            'help': 'Install/update language-specific packages \U0001F40D'  # snake emoji
        },
        'addons': {
            'func': 'addons',
            'help': "Install World of Warcraft (and maybe other) addons",
        },
        'debug': {  # load the setup program as a module and start an interactive console
            'func': 'debug',
            'help': 'Start an interactive console'
        },
        'edit': {  # open the setup directory in your editor
            'func': 'edit',
            'help': 'Open the setup directory in your editor',
        },
        'restart_os_functions': {
            # https://blog.cloudtroopers.com/how-restart-mac-os-x-finder-dock-or-menubar
            # this should be run if any settings change, but you don't necessarily
            # need to run this every time 'update_os_settings' is run
            'func': 'restart_os_functions',
            'help': 'Restart Finder, Menubar, Dock, etc.'
        }
    },
    'symlinks': {
        'overrides': {
            # overrides should not have slashes at the end even though it's a directory
            # because it refers to the symlink that's created
            'sublime_text': 'Library/Application Support/Sublime Text 3/Packages/User'
        },
        # 'ignores_file': '.gitignore_global',  # piggyback off of gitignore_global
        # this path should be resolved correctly because 'setup' sets the cwd
        # to the root of the repository
        'ignores': list(
            filter(
                # ignore comments, negations, and empty lines
                lambda line: not line.startswith(('#', '!')) and line.strip(),
                open('HOME/.gitignore_global').read().splitlines()
            )
        ),
    },
    'homebrew': {
        'formulas': [
            'bash-completion',
            'git',
            'go',
            'jq',
            'kdiff3',
            'meld',
            'pypy',
            'python',
            'python3',
            'readline',
            'ruby',
            'rust',
            'tmux',
            'tree',
            'youtube-dl',
            'z',
        ],
        'post_install': [
            # symlink 'z' into my local shell sources so it'll be 1. run automatically in my
            # .bash_profile, 2. copied to servers by my copy_config_to_host script
            'ln -sf `brew --prefix`/etc/profile.d/z.sh HOME/bin/shell_sources/',
        ],
    },
    'packages': {
        'python{}'.format(version): {
            'cmd': ['pip{}'.format(version), 'install', '--upgrade', '{package}'],
            'packages': [
                'pip',
                'setuptools',
                'ipython[notebook]',
                'pytest',
                'flake8',
                # autopep8 after flake8: autopep8 installs newer versions of dependencies
                'autopep8',
                'pylint',
                'requests',
                'ftfy',
                'pudb',
                'pandas',
            ],
        }
        for version in ('', '3')
    },
    'addons': {
        'wow': {
            'installation_path': '/Applications/World of Warcraft/Interface/AddOns/',
            'addons': [
                # 'altoholic',
                'bagnon',
                'deadly-boss-mods',
                'dominos',
                'droodfocus',
                'mik-scrolling-battle-text',  # msbt
                'need-to-know',
                'omni-cc',
                'recount',
                'shadowed-unit-frames',
                'tidy-plates',
                'macro-toolkit',
            ]
        }
    },
    'osx': {
        'defaults': {
            'com.apple.dock': {
                # http://www.defaults-write.com/enable-highlight-hover-effect-for-grid-view-stacks/
                'mouse-over-hilite-stack': True,

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
                'wvous-bl-corner': 10,
                'wvous-bl-modifier': 0,

                # top left: mission control
                'wvous-tl-corner': 2,
                'wvous-tl-modifier': 0,

                # top right: desktop
                'wvous-tr-corner': 4,
                'wvous-tr-modifier': 0,

                # bottom right: application windows
                'wvous-br-corner': 3,
                'wvous-br-modifier': 0,
            },
            'com.apple.finder': {
                'ShowPathbar': True,
                'ShowStatusBar': True,
            },
            'com.apple.menuextra.battery': {
                # the menubar widget actually sets 'YES' or 'NO' but bool values work too
                'ShowPercent': True,
            },

            # trackpad settings
            'com.apple.AppleMultitouchTrackpad': {
                'Clicking': True,  # touch to click

                # enable *both* methods of right clicking
                'TrackpadRightClick': True,  # two finger tap
                'TrackpadCornerSecondaryClick': 2,  # pushing to click in right corner

                # disable "smart zoom" because it puts a delay on two-finger-tap right click
                'TrackpadTwoFingerDoubleTapGesture': False,

                'TrackpadThreeFingerDrag': True,
            },
            'com.apple.driver.AppleBluetoothMultitouch.trackpad': {
                'Clicking': True,  # touch to click

                # enable *both* methods of right clicking
                'TrackpadRightClick': True,  # two finger tap
                'TrackpadCornerSecondaryClick': 2,  # pushing to click in right corner

                # disable "smart zoom" because it puts a delay on two-finger-tap right click
                'TrackpadTwoFingerDoubleTapGesture': False,

                'TrackpadThreeFingerDrag': True,
            },
            'NSGlobalDomain': {
                #     'com.apple.trackpad.trackpadCornerClickBehavior': 1,
                #     'com.apple.trackpad.enableSecondaryClick': True,

                # set key repeat rate and initial repeat delay
                'KeyRepeat': 2,
                'InitialKeyRepeat': 10,
            }
        }
    }
}
