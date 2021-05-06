{
    'brew': {
        'cmd': (
            ['HOME/bin/homebrew-workflow', 'conf/Brewfile'],
            # brew bundle has no link https://github.com/Homebrew/homebrew-bundle/issues/84
            # so you need to do this if you want an old version to take precedence
            ['brew', 'link', 'node@14'],
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
        # setup module is available because exec'd in context of packages.py
        'exec': 'print(setup.root())'
    },
    'home': {
        'help': "Print the path of the setup HOME dir",
        'exec': 'print(setup.home())'
    },
    'edit': {
        'help': "Open the setup directory in your editor",
        'cmd': ['bash', '-ic', 'edit .']
    },
    'manual': {
        'dir': '3rdparty',  # 3rdparty is already in gitignore
        'packages': {
            'symgr': {
                'git': 'https://github.com/kbd/symgr.git',
                # this command is equivalent to setting 'bin' to 'symgr',
                # but this is bootstrapping the symlinking done for 'bin'
                'cmd': 'ln -sf $(setup root)/3rdparty/symgr/symgr ~/bin/symgr'
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
                'git': 'https://github.com/zigtools/zls.git',
                'tag': '0.1.0',
                'cmd': 'zig build -Drelease-safe',
                'bin': 'zig-cache/bin/zls',
            },
            'fzf-tab': {
                'git': 'https://github.com/Aloxaf/fzf-tab',
            },
            'zsh-prompt-benchmark': {
                'git': 'https://github.com/romkatv/zsh-prompt-benchmark.git'
            },
        }
    }
}
