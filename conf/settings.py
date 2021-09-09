{
    'brew': {
        'cmd': (
            ['HOME/bin/homebrew-workflow', 'conf/Brewfile'],
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
        'cmd': (
            ['pip3', 'install', '--upgrade', '-r', 'conf/requirements.txt'],
            'poetry completions zsh > `brew --prefix`/share/zsh/site-functions/_poetry',
        ),
    },
    'pipx': {
        'cmd': "st <(cat conf/pipx.txt) '-' <(pipx list --json | jq -r '.venvs | keys[]') | xargs -t pipx install"
    },
    'node': {
        'cmd': "cat conf/npm.txt | xargs -t npm install -g",
    },
    'go': {
        'cmd': "cat conf/go.txt | xargs -t -L1 go get -v -u"
    },
    'nim': {
        'cmd': "cat conf/nimble.txt | xargs -to nimble install"
    },
    'rust': {
        'cmd': (
            ['rustup-init', '-y', '--no-modify-path'],
            ['rustup', 'update'],
            ['rustup', 'install', 'nightly'],
        ),
    },
    'cargo': {
        'cmd': (
            "cat conf/cargo.txt | xargs -t cargo install",
            'broot --set-install-state refused --print-shell-function zsh > ~/bin/shell/3rdparty/br.zsh',
        )
    },
    'mac': {
        'exec': 'import runpy; runpy.run_path("conf/mac.py")'
    },
    'restartservices': {
        'help': "Restart Finder, Menubar, Dock, etc.",
        'exec': 'import lib.mac; lib.mac.restart_os_functions()'
    },
    'vscode': {
        'cmd': ['install-vscode-extensions', 'conf/vscode.txt'],
    },
    'root': {
        'help': "Print the path of the setup dir",
        'exec': 'print(root())'
    },
    'home': {
        'help': "Print the path of the setup HOME dir",
        'exec': 'print(home())'
    },
    'edit': {
        'help': "Open the setup directory in your editor",
        'cmd': ['bash', '-ic', 'edit .']
    },
    'manual': {
        'cmd': 'install-manual conf/manual.toml "$(setup root)/3rdparty"'
    },
    'symlinks': {
        'exec': "run_commands(['symgr', *debug_if_debug(), home(), Path.home()])"
    },
    'pull': {
        'help': "Update the setup repository",
        'cmd': ['git', 'pg'],
    },
    'packages': {
        'help': "Install all software packages",
        'cmd': [
            'setup',
            'brew', 'python', 'pipx', 'node', 'go', 'rust', 'cargo', 'nim', 'vscode'
        ]
    },
    'init': {
        'help': "The full set of commands used on first setup / bootstrap",
        'cmd': ['setup', 'packages', 'manual', 'symlinks', 'mac', 'restartservices'],
    },
    'update': {
        'help': "One-stop shopping to update setup repo and most things",
        'cmd': (
            ['setup', 'pull'],
            ['setup', 'packages', 'symlinks'],
        ),
    },
}
