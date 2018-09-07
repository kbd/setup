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
            '~/.config',
            '~/.parallel',
        ],
        # 'ignores_file': '.gitignore_global',  # piggyback off of gitignore_global
        # the relative path should be correct because 'setup' sets the cwd to the root of the repo
        'ignores': [
            line for line in open('HOME/.config/git/ignore').read().splitlines()
            # ignore comments, negations, and empty lines
            if not line.startswith(('#', '!')) and line.strip()
        ]
    },
    'homebrew': {
        'bundle': 'conf/Brewfile',
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
        'python': {
            'cmd': ['pip3', 'install', '-r', 'conf/requirements.txt'],
        },
        'node': {
            'cmd': [
                'npm', 'install', '-g',
                'coffeescript',
                'typescript',
            ],
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
}
