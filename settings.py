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
        'brew': {
            'func': 'brew',
            'args': [
                ('fix_repo', {'help': 'Fix a broken repository', 'optional': True})
            ],
            'help': "🍺 Homebrew🍺"
        },
        'packages': {
            'func': 'install_packages',
            'args': [
                ('language_filter', {'help': 'Only update languages matching regex', 'optional': True}),
                ('package_filter', {'help': 'Only update packages matching regex', 'optional': True}),
            ],
            'help': 'Install/update language-specific packages 🐍'
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
        'pointers': {
            # pointers to directories should not have slashes at the end because the value
            # refers to the symlink that's created
            'sublime_text': 'Library/Application Support/Sublime Text 3/Packages/User',
        },
        'partials': [
            # partials refer to directories that won't be symlinked directly, but will have their
            # contents symlinked. This avoids overwriting a directory that has files we want to
            # leave in place and not alter. Pointer directories can be partials, and partials can
            # be nested, otherwise subdirs within the partial will still be treated normally
            # partials should be an absolute path, possibly with the home directory
            '~/.config'
        ],
        # 'ignores_file': '.gitignore_global',  # piggyback off of gitignore_global
        # the relative path should be correct because 'setup' sets the cwd to the root of the repo
        'ignores': list(
            filter(
                # ignore comments, negations, and empty lines
                lambda line: not line.startswith(('#', '!')) and line.strip(),
                open('HOME/.config/git/ignore').read().splitlines()
            )
        ),
    },
    'homebrew': {
        'taps': [
            'homebrew/cask-fonts',
        ],
        'formulas': [
            'aria2',
            'awscli',
            'bash',
            'bash-completion',
            'bat',
            'cmake',
            'coreutils',
            'diff-so-fancy',
            'elixir',
            'entr',
            'exa',
            'fasd',
            'fd',
            'fpp',
            'fzf',
            'gawk',
            'git',
            'gnu-sed',
            'gnu-tar',
            'go',
            'googler',
            'httpie',
            'jq',
            'libgit2',
            'mas',
            'minimal-racket',
            'osquery',
            'ncdu',
            'path-extractor',
            'perl',
            'pgcli',
            'postgresql',
            'progress',
            'pup',
            'pv',
            'pyenv',
            'pypy',
            'python',
            'rakudo-star',
            'ranger',
            'readline',
            'rethinkdb',
            'ripgrep',
            'rlwrap',
            'ruby',
            'rust',
            'shellcheck',
            'sshrc',
            'switchaudio-osx',
            'thefuck',
            'tig',
            'tmux',
            'tokei',
            'tree',
            'vim',
            'vimpager',
            'wget',
            'xsv',
            'yarn',  # installs Node
            'youtube-dl',
            'zsh',
            'zsh-autosuggestions',
            'zsh-syntax-highlighting',
        ],
        'casks': [
            'alfred',
            'appcleaner',
            'caffeine',
            'dbeaver-community',
            'docker',
            'epichrome',
            'firefox',
            'flycut',
            'google-chrome',
            'grandperspective',
            'iina',
            'iterm2',
            'karabiner-elements',
            'kdiff3',
            'kindle',
            'libreoffice',
            'meld',
            'rq',
            'slack',
            'sourcetree',
            'spotify',
            'spotmenu',
            'sublime-text',
            # 'vagrant',  # requires package installer, disable by default
            # 'virtualbox',  # requires kernel extensions, disable by default
            'visual-studio-code',
            'vlc',
            'xquartz',

            # caskroom/fonts tap
            'font-fantasque-sans-mono',
        ],
        'post_install': [
            'HOME/bin/update_shell.sh `brew --prefix`/bin/zsh',  # set shell to homebrew'd shell
            'ln -sf `brew --prefix`/share/zsh-autosuggestions/zsh-autosuggestions.zsh HOME/bin/shell_sources/3rdparty',
            # https://docs.docker.com/docker-for-mac/#zsh
            """
                etc=/Applications/Docker.app/Contents/Resources/etc;
                sf=`brew --prefix`/share/zsh/site-functions;
                ln -sf $etc/docker.zsh-completion $sf/_docker;
                ln -sf $etc/docker-machine.zsh-completion $sf/_docker-machine;
                ln -sf $etc/docker-compose.zsh-completion $sf/_docker-compose;
            """,
        ],
    },
    'packages': {
        'macos': {
            'cmd': ['mas', 'install', '{package}'],
            'packages': [
                '497799835',  # xcode
            ],
        },
        'python': {
            'cmd': ['pip3', 'install', '--upgrade', '{package}'],
            'cmd_all': ['pip3', 'install', '-r', '{packages}'],
            'packages': [
                'ansible',
                'attrs',
                'black',
                'boto3',
                'Django',
                'fire',
                'flask',
                'flask-restful',
                'flask-socketio',
                'ftfy',
                'ipdb',
                'jupyter',
                'pandas',
                'pip',
                'pipdeptree',
                'pipenv',
                'psycopg2-binary',
                'pygit2',
                'python-dateutil',
                'pudb',
                'pygments',
                'pyquery',
                'pytest',
                'PyYAML',
                'requests',
                'rethinkdb',
                'setuptools',
                'Sphinx',
                'sqlalchemy',
                'tmuxp',
                'virtualenv',
            ],
        },
        'node': {
            'cmd': ['yarn', 'global', 'add', '{package}'],
            'packages': [
                'coffeescript',
                'typescript',
            ],
        },
        'ruby': {
            'cmd': ['gem', 'install', '{package}'],
            'packages': [
            ]
        },
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

                # other addons I've used in the past:
                # elkano's buff bars, monkeyquest, prat, auctioneer
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
            'com.apple.dashboard': {
                'mcx-disabled': True,
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
