{
    'packages': {
        'brew': {
            'bundle': 'conf/Brewfile',
            'post_install': (
                'HOME/bin/update_shell.sh `brew --prefix`/bin/zsh',  # set shell to homebrew'd shell
                'ln -sf `brew --prefix`/share/zsh-autosuggestions/zsh-autosuggestions.zsh HOME/bin/shell_sources/3rdparty',
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
            'cmd': "cat conf/npm.txt | xargs -t npm install -g",
        },
        'rust': {
            'cmd': (
                ['rustup', 'update'],
                ['cargo', 'install', 'pyoxidizer'],
            ),
        },
        'mac': {
            'skip_if_not_requested': True,
            'path': 'conf/mac.py'
        },
        'vscode': {
            'extensions': 'conf/vscode.txt',
        },
    },
}
