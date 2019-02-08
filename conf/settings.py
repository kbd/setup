{
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
            'cmd': ['pip3', 'install', '--upgrade', '-r', 'conf/requirements.txt'],
        },
        'node': {
            'cmd': [
                'npm', 'install', '-g',
                'coffeescript',
                'typescript',
                'ts-node',
                'jest',
                'git-open',
                'npx',
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
