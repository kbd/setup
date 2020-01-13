{
    'packages': {
        'brew': {
            'bundle': 'conf/Brewfile',
            'post_install': (
                # set shell to homebrew'd shell
                'HOME/bin/update_shell.sh `brew --prefix`/bin/zsh',
                # symlink zsh autosuggestions
                'ln -sf `brew --prefix`/share/zsh-autosuggestions/zsh-autosuggestions.zsh ~/bin/shell/3rdparty',
                # patch fzf's history format to include timestamp
                'perl -pi -e \'s/fc -rl 1/fc -rli 1/\' "$(brew --prefix fzf)/shell/key-bindings.zsh"',
                # https://docs.docker.com/docker-for-mac/#zsh
                """
                    etc=/Applications/Docker.app/Contents/Resources/etc;
                    sf=`brew --prefix`/share/zsh/site-functions;
                    ln -sf $etc/docker.zsh-completion $sf/_docker;
                    ln -sf $etc/docker-machine.zsh-completion $sf/_docker-machine;
                    ln -sf $etc/docker-compose.zsh-completion $sf/_docker-compose;
                """,
            ),
        },
        'python': {
            'cmd': ['pip3', 'install', '--upgrade', '-r', 'conf/requirements.txt'],
            'post_install': (
                'poetry completions zsh > `brew --prefix`/share/zsh/site-functions/_poetry',
            )
        },
        'node': {
            'skip_if_not_requested': True,
            'cmd': "cat conf/npm.txt | xargs -t npm install -g",
        },
        'go': {
            'cmd': "cat conf/go.txt | xargs -t -L1 go get -v -u"
        },
        'rust': {
            'skip_if_not_requested': True,
            'cmd': (
                ['rustup-init', '-y', '--no-modify-path'],
                ['rustup', 'update'],
                ['rustup', 'install', 'nightly'],
            ),
        },
        'cargo': {
            'cmd': "cat conf/cargo.txt | xargs -t cargo +nightly install",
            'post_install': (
                'mkdir -p ~/Library/Preferences/org.dystroy.broot/launcher/',
                'touch ~/Library/Preferences/org.dystroy.broot/launcher/refused',
                'broot --print-shell-function zsh > ~/bin/shell/3rdparty/br.zsh',
            )
        },
        'mac': {
            'skip_if_not_requested': True,
            'path': 'conf/mac.py'
        },
        'vscode': {
            'extensions': 'conf/vscode.txt',
        },
        'manual': {
            'skip_if_not_requested': True,
            'dir': '3rdparty',  # 3rdparty is already in gitignore
            'packages': {
                'symgr': {
                    'url': 'https://github.com/kbd/symgr.git',
                    # this command is equivalent to setting 'bin' to 'symgr',
                    # but this is bootstrapping the symlinking done for 'bin'
                    'cmd': 'ln -sf $(setup --root)/3rdparty/symgr/symgr ~/bin/symgr'
                },
                'bak': {
                    'url': 'https://github.com/kbd/bak.git',
                    'bin': 'bak'
                },
                'repo_status': {
                    'url': 'https://github.com/kbd/repo_status.git',
                    'bin': 'repo_status'
                }
            }
        }
    }
}
