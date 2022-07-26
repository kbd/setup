{
    'brew': (
        ['homebrew-workflow', 'Brewfile'],
        # zsh: update to homebrew'd shell
        'update-shell "$(brew --prefix)/bin/zsh"',
        # fzf: install and patch its history format to include timestamp
        "$(brew --prefix)/opt/fzf/install --key-bindings --completion --no-update-rc --xdg",
        'perl -pi -e \'s/fc -rl 1/fc -rli 1/\' "$(brew --prefix fzf)/shell/key-bindings.zsh"',
        # docker: https://docs.docker.com/desktop/mac/#zsh
        """
            etc=/Applications/Docker.app/Contents/Resources/etc;
            sf="$(brew --prefix)/share/zsh/site-functions";
            ln -sf $etc/docker.zsh-completion $sf/_docker;
            ln -sf $etc/docker-compose.zsh-completion $sf/_docker-compose;
        """,
        # brew python formula doesn't link 'python' and 'pip'. Why?
        'mkdir -p ~/bin', # ensure bin exists (bootstrapping)
        'ln -sf $(brew --prefix)/bin/python3 ~/bin/python',
        'ln -sf $(brew --prefix)/bin/pip3 ~/bin/pip',
        # create 'systempython' so scripts work with venv active
        'ln -sf $(brew --prefix)/bin/python3 ~/bin/systempython',
        # install kitty terminfo
        # https://sw.kovidgoyal.net/kitty/faq/#keys-such-as-arrow-keys-backspace-delete-home-end-etc-do-not-work-when-using-su-or-sudo
        """
        mkdir -p ~/.terminfo/{78,x}
        ln -snf ../x/xterm-kitty ~/.terminfo/78/xterm-kitty
        tic -x -o ~/.terminfo /Applications/kitty.app/Contents/Resources/kitty/terminfo/kitty.terminfo
        """
    ),
    'python': (
        ['pip3', 'install', '--upgrade', '-r', 'requirements.txt'],
        'poetry completions zsh > `brew --prefix`/share/zsh/site-functions/_poetry',
    ),
    'pipx': "st <(cat pipx.txt) '-' <(pipx list --json | jq -r '.venvs | keys[]') | xargs -t pipx install",
    'node': "cat npm.txt | xargs -t npm install -g",
    'go': "cat go.txt | xargs -t -L1 go install",
    'nim': "cat nimble.txt | xargs -to nimble install",
    'vscode': ['install-vscode-extensions', 'vscode.txt'],
    'manual': ['install-manual', 'manual.toml', VENDOR],
    'symlinks': ['symgr', *debug_if_debug(), HOME, Path.home()],
    'rust': """
        rustup-init -y --no-modify-path;
        source $HOME/.cargo/env;
        rustup update;
        rustup install nightly;
    """,
    'cargo': (
        "cat cargo.txt | xargs -t cargo install",
        # create directory in case bootstrapping when symlinks not yet created
        """
            mkdir -p ~/bin/shell/3rdparty/;
            broot --set-install-state refused --print-shell-function zsh > ~/bin/shell/3rdparty/br.zsh;
        """,
    ),
    'mac': {
        'exec': 'import runpy; runpy.run_path("mac.py")'
    },
    'restartservices': {
        'help': "Restart Finder, Menubar, Dock, etc.",
        'exec': 'import lib.mac; lib.mac.restart_os_functions()'
    },
    'debug': {
        'help': "Start an interactive console",
        'exec': 'import code; code.interact(local=globals())',
    },
    'edit': {
        'help': "Open the setup directory in your editor",
        'cmd': ['code', ROOT]
    },
    'pull': {
        'help': "Update the setup repository",
        'cmd': ['git', 'pull'],
    },
    'packages': {
        'help': "Install all software packages",
        'cmd': ['setup', 'python', 'node', 'go', 'rust', 'cargo', 'vscode']
    },
    'init': {
        'help': "The full set of commands used on first setup / bootstrap",
        'cmd': (
            # ensure current system deps (i.e. Python) are up to date first
            ['setup', 'brew'],
            # then subsequent run should have current base deps.
            ['setup', 'packages', 'manual', 'symlinks', 'mac', 'restartservices'],
        ),
    },
    'update': {
        'help': "One-stop shopping to update setup repo and most things",
        'cmd': (
            ['setup', 'pull'],
            ['setup', 'brew'],
            ['setup', 'packages', 'symlinks'],
        ),
    },
}
