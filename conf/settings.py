{
    'packages': {
        'brew': {
            'bundle': 'conf/Brewfile',
            'post_install': (
                # set shell to homebrew'd shell
                'HOME/bin/update_shell.sh `brew --prefix`/bin/zsh',
                # install fzf
                "$(brew --prefix)/opt/fzf/install --key-bindings --completion --no-update-rc --xdg",
                # patch fzf's history format to include timestamp
                'perl -pi -e \'s/fc -rl 1/fc -rli 1/\' "$(brew --prefix fzf)/shell/key-bindings.zsh"',
                # https://docs.docker.com/docker-for-mac/#zsh
                """
                    etc=/Applications/Docker.app/Contents/Resources/etc;
                    sf=`brew --prefix`/share/zsh/site-functions;
                    ln -sf $etc/docker.zsh-completion $sf/_docker;
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
        'nim': {
            'skip_if_not_requested': True,
            'cmd': "cat conf/nimble.txt | xargs -to nimble install"
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
            'skip_if_not_requested': True,
            'cmd': "cat conf/cargo.txt | xargs -t cargo install",
            'post_install': (
                'broot --set-install-state refused --print-shell-function zsh > ~/bin/shell/3rdparty/br.zsh',
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
                    'git': 'https://github.com/kbd/symgr.git',
                    # this command is equivalent to setting 'bin' to 'symgr',
                    # but this is bootstrapping the symlinking done for 'bin'
                    'cmd': 'ln -sf $(setup --root)/3rdparty/symgr/symgr ~/bin/symgr'
                },
                'bak': {
                    'git': 'https://github.com/kbd/bak.git',
                    'bin': 'bak'
                },
                'repo_status': {
                    'git': 'https://github.com/kbd/repo_status.git',
                    'cmd': 'nim c -d:release repo_status.nim',
                    'bin': 'repo_status'
                },
                'prompt': {
                    'git': 'https://github.com/kbd/prompt.git',
                    'cmd': 'zig build-exe -OReleaseFast prompt.zig',
                    'bin': 'prompt',
                },
                'zls': {
                    'url': 'https://github.com/zigtools/zls/releases/download/0.1.0/x86_64-macos.tar.xz',
                    'cmd': 'dtrx x86_64-macos.tar.xz',
                    'bin': 'x86_64-macos/zls',
                }
            }
        }
    }
}
