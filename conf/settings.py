{
    'symlinks': {
        'partials': [
            # partials refer to directories that won't be symlinked directly, but will have their
            # contents symlinked. This avoids overwriting a directory that has files we want to
            # leave in place and not alter. Pointer directories can be partials, and partials can
            # be nested, otherwise subdirs within the partial will still be treated normally
            # partials should be an absolute path, possibly with the home directory
            '~/.config',
            '~/.parallel',
            '~/Library/Application Support/Sublime Text 3/Packages/User',
            '~/Library/Application Support/Code/User',
        ],
    },
    'packages': {
        'brew': {
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
        'python': {
            'cmd': ['pip3', 'install', '--upgrade', '-r', 'conf/requirements.txt'],
        },
        'node': {
            'cmd': "cat conf/npm.txt | xargs -t npm install -g",
        },
        'vscode': {
            'extensions': 'conf/vscode.txt',
        },
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
            ],
        },
    },
}
