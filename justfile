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

	# run everything for homebrew
	homebrew-workflow conf/Brewfile

	# cache brew shellenv
	brew shellenv > ~/bin/shell/3rdparty/.brew.sh

	# post-install steps
	# zsh: update to homebrew'd shell
	update-shell "$(brew --prefix)/bin/zsh"

	# cache zsh plugins
	# note: '3rdparty' subdir should sort and therefore be sourced first
	plugins=~/bin/shell/3rdparty/_plugins.zsh
	direnv hook zsh > $plugins
	zoxide init zsh >> $plugins
	fzf --zsh >> $plugins
	atuin init zsh >> $plugins

python:
	uv venv ~/bin/.venv
	uv pip install --strict --python ~/bin/.venv/bin/python -r conf/requirements.txt

pipx:
	cat conf/pipx.txt | xargs -t -n1 pipx install
	pipx upgrade-all

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

	broot --set-install-state refused
	broot --print-shell-function zsh > ~/bin/shell/3rdparty/br.zsh

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
packages: python pipx node go rust cargo vscode

bootstrap:
	mkdir -p ~/bin/shell/3rdparty/

# The full set of commands used on first setup
init: bootstrap brew packages manual symlinks mac restartservices

# One-stop shopping to update setup repo and most things
update: pull brew packages symlinks

# 'Bless' files
bless path:
	#!/usr/bin/env zsh
	cd "{{invocation_directory()}}"
	source_path="$(grealpath "{{path}}")"
	controlled_path="$(grealpath --relative-to="$HOME" "$source_path")"
	symgr --bless "$source_path" "{{justfile_directory()}}/HOME/$controlled_path"
