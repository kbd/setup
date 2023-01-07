list:
  @just --list --justfile {{justfile()}}

vendor := "~/3rdparty"

vendor:
  @echo {{vendor}}

bin:
  @echo {{justfile_directory()}}/HOME/bin

brew:
  #!/usr/bin/env bash
  set -Eeuxo pipefail

  brew_prefix="$(brew --prefix)"

  homebrew-workflow conf/Brewfile

  # zsh: update to homebrew'd shell
  update-shell "$brew_prefix/bin/zsh"

  # fzf: install and patch its history format to include timestamp
  $brew_prefix/opt/fzf/install --key-bindings --completion --no-update-rc --xdg
  perl -pi -e 's/fc -rl 1/fc -rli 1/' "$(brew --prefix fzf)/shell/key-bindings.zsh"

  # docker: https://docs.docker.com/desktop/mac/#zsh
  etc=/Applications/Docker.app/Contents/Resources/etc
  sf="$brew_prefix/share/zsh/site-functions"
  ln -sf $etc/docker.zsh-completion $sf/_docker
  ln -sf $etc/docker-compose.zsh-completion $sf/_docker-compose

  # brew python formula doesn't link 'python' and 'pip'. Why?
  mkdir -p ~/bin # ensure bin exists (bootstrapping)
  ln -sf $brew_prefix/bin/python3 ~/bin/python
  ln -sf $brew_prefix/bin/pip3 ~/bin/pip

  # create 'systempython' so scripts work with venv active
  ln -sf $brew_prefix/bin/python3 ~/bin/systempython

  # install kitty terminfo
  # https://sw.kovidgoyal.net/kitty/faq/#keys-such-as-arrow-keys-backspace-delete-home-end-etc-do-not-work-when-using-su-or-sudo
  mkdir -p ~/.terminfo/{78,x}
  ln -snf ../x/xterm-kitty ~/.terminfo/78/xterm-kitty
  tic -x -o ~/.terminfo /Applications/kitty.app/Contents/Resources/kitty/terminfo/kitty.terminfo

python:
  pip3 install --upgrade -r conf/requirements.txt

pipx:
  st <(cat conf/pipx.txt) '-' <(pipx list --json | jq -r '.venvs | keys[]') | xargs -t pipx install

node:
  cat conf/npm.txt | xargs -t npm install -g

go:
  cat conf/go.txt | xargs -t -L1 go install

nim:
  cat conf/nimble.txt | xargs -to nimble install

vscode:
  install-vscode-extensions conf/vscode.txt

manual:
  install-manual conf/manual.toml {{vendor}}

symlinks:
  symgr HOME ~

rust:
  #!/usr/bin/env bash
  set -Eeuxo pipefail

  rustup-init -y --no-modify-path;
  source $HOME/.cargo/env;
  rustup update;
  rustup install nightly;

cargo:
  cat conf/cargo.txt | xargs -t cargo install

  # create directory in case bootstrapping when symlinks not yet created
  mkdir -p ~/bin/shell/3rdparty/
  broot --set-install-state refused --print-shell-function zsh > ~/bin/shell/3rdparty/br.zsh

mac:
  PYTHONPATH=~/bin python3 conf/mac.py

# Restart Finder, Menubar, Dock, etc.
restartservices:
  PYTHONPATH=~/bin python3 -c "import lib.mac; lib.mac.restart_os_functions()"

# Open the setup directory in your editor
edit:
  code {{justfile_directory()}}

# Update the setup repository
pull:
  git pull

# Install all software packages
packages: python node go rust cargo vscode

# The full set of commands used on first setup / bootstrap
init: brew packages manual symlinks mac restartservices

# One-stop shopping to update setup repo and most things
update: pull brew packages symlinks

# 'Bless' files
bless path:
  #!/usr/bin/env zsh
  cd "{{invocation_directory()}}"
  source_path="$(realpath "{{path}}")"
  controlled_path="$(realpath --relative-to="$HOME" $source_path)"
  symgr --bless "$source_path" "{{justfile_directory()}}/HOME/$controlled_path"
