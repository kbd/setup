#!/usr/bin/env bash

# path/system
if [[ -z "$PATH_SET" ]]; then
  export PATH="$HOME/bin:$PATH:$HOME/.cargo/bin:$HOME/go/bin:$HOME/.local/bin:$HOME/.nimble/bin"
  export PATH_SET=1
fi
export XDG_CONFIG_HOME=~/.config
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

# PLATFORM SPECIFIC
if [[ "$(uname)" == 'Darwin' ]]; then
  # PATH="/usr/local/opt/coreutils/libexec/gnubin:$PATH"
  # MANPATH="/usr/local/opt/coreutils/libexec/gnuman:$MANPATH"

  # prefer GNU versions of common utils
  alias awk=gawk
  alias sed=gsed
  alias tar=gtar
  LS_PATH='/usr/local/bin/gls'

  alias lock='pmset displaysleepnow'
  alias locks='pmset sleepnow' # locks = "lock+sleep". 'sleep' is a unix command

  alias switch-output="SwitchAudioSource -a -t output | f ' (' 0 | fzf | xargs -I% SwitchAudioSource -t output -s '%'"
  alias switch-input="SwitchAudioSource -a -t input | f ' (' 0 | fzf | xargs -I% SwitchAudioSource -t input -s '%'"
fi

# SHELL SPECIFIC
if [[ $ZSH_VERSION ]]; then
  export ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern cursor)

  # global aliases
  alias -g L='| $PAGER'
  alias -g H='| head'
  alias -g C='| grcat log'

  # fzf tab preview doesn't work properly without this set
  # $SHELL is defaulting to /bin/sh
  export SHELL='/usr/local/bin/zsh'
fi

# TERMINAL SPECIFIC
if [[ $TERM == 'xterm-kitty' ]]; then
  alias cati="kitty +kitten icat --align=left"
fi

# pag{ers,ing}/editors
export PAGER=less
export LESS='-iMFx4 --mouse --incsearch' # smart-case, status bar, quit 1 screen, 4sp tabs
export EDITOR=vim
export VISUAL='code -nw'
export GIT_EDITOR='kw --wait vim'
export DELTA_PAGER="less $LESS -R"
alias http='autopager http --pretty=all'
alias https='autopager https --pretty=all'
alias jq='autopager jq -C'
alias curl='autopager curl -L'
alias xh='autopager xh --pretty=all'
alias yq='autopager yq -C'
alias gh='PAGER= gh' # use gh default pager; gh needs 'less -R' for colors
alias glab='PAGER= glab' # ...

# edit/open
alias edit=code
alias e=edit
alias e.='e .'
alias e-='e -'
alias eg='e -g'
alias o=open
alias o.='o .'
alias a='o -a'
te(){ t "$@" && e "$@"; }

# directory/navigation
alias   -- -='cd -'
alias  -- --='cd -2'
alias -- ---='cd -3'
alias     ..='cd ..'
alias    ...='cd ../..'
alias   ....='cd ../../..'
alias  .....='cd ../../../..'
alias ......='cd ../../../../..'
# shellcheck disable=SC2139
alias ls="${LS_PATH:-ls} -F --color=auto --group-directories-first"
alias l=ls
alias la='ls -A'
alias lt='ls -t'
alias ll='ls -lh'
alias lla='ll -A'
alias llt='ll -t'
alias llat='ll -At'
alias lsd='ls -d --indicator-style=none -- */'
alias lld='ll -d --indicator-style=none -- */'
cl() { cd -- "${1-$HOME}" && l "${@:2}"; }
cll() { cd -- "${1-$HOME}" && ll "${@:2}"; }
et() { exa -alT --git -I'.git|node_modules|.mypy_cache|.pytest_cache|.venv' --color=always "$@" | less -R; }
alias et1='et -L1'
alias et2='et -L2'
alias et3='et -L3'
mcd() {
  # mkdir + cd
  [[ -z "$1" ]] && echo >&2 "missing argument" && return 1
  mkdir -p -- "$1" && cl "$@" -A
}

# fzf
export FZF_DEFAULT_COMMAND='fd -tf -HL'
export FZF_DEFAULT_OPTS='--height 30% --reverse --multi'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd -td -HL'
export FZF_ALT_C_OPTS="--preview 'tree -C {} | head -200'"
_fzf_compgen_path() { fd -tf -HL . "$1"; }
_fzf_compgen_dir() { fd -td -HL . "$1"; }

# git
# create aliases for all short (<= 4 character) git aliases
for gitalias in $(git alias 2>/dev/null | grep -E '^.{0,4}$'); do
  # shellcheck disable=SC2139
  alias "g$gitalias=g $gitalias"
done
alias g=git
alias s='gs' # status
alias p='gpg' # pull and show graph of recent changes
alias g-='gw-' # switch to most recent branch
alias ga='gaf' # add files with fuzzy finder
alias gb='gbf' # show/switch branches using fuzzy finder
alias gbr='gbrf' # show/switch remote branches using fuzzy finder
gccb() {
  # check out a repository from the url in the clipboard and cd into it
  local url="$(cb)"
  local dir="${1:-$(basename "$url" .git)}"
  git clone -- "$url" "$dir" && cd "$dir" || return
}

# go
dlv() {
  local args=('debug')
  if [[ $# != 0 ]]; then
    args=("$@")
  fi
  EDITOR=delve-editor command dlv "${args[@]}"
}
go(){ if [[ $# -eq 0 ]]; then rlwrap yaegi; else command go "$@"; fi }
alias yaegi='rlwrap yaegi'

# homebrew
export HOMEBREW_NO_AUTO_UPDATE=1
export HOMEBREW_NO_INSTALL_CLEANUP=1
export HOMEBREW_NO_INSTALLED_DEPENDENTS_CHECK=1

# python
export PIPENV_SHELL_FANCY=1
export PTPYTHON_CONFIG_HOME=$XDG_CONFIG_HOME/ptpython  # defaults to ~/Library/Application Support/... on Mac
export PYTHONBREAKPOINT=pudb.set_trace
export PYTHONDONTWRITEBYTECODE=1
export VIRTUAL_ENV_DISABLE_PROMPT=1
alias da='django-admin'
alias dm='python3 manage.py' # "django manage"
alias ds='dm shell_plus --ptpython'
alias py='pyt'
alias pyb='bpython'
alias pyc='py -c'
alias pyi='ptipython'
alias pym='py -i -c "import pandas as pd; import re; import datetime as dt; from pathlib import Path; import sys; import os; import json; from pprint import pprint as pp;"'
alias pyt='ptpython'

# shortcuts/defaults/config
export ERL_AFLAGS="-kernel shell_history enabled" # remember Elixir iex history across sessions
export RIPGREP_CONFIG_PATH=$XDG_CONFIG_HOME/ripgrep/rc
alias 1p='eval $(op signin)'
alias c=bat
alias chn='bat --style=header,numbers'
alias cn='bat --style=numbers'
alias cnh='bat --style=header,numbers'
alias d='docker'
alias dc='docker-compose'
alias dp='cd "$(dirs -pl | tail -n+2 | fzf)"'
alias dtrx='dtrx --one=inside'
alias du='du -h'
alias dud='du -d0 .'
alias emoji='uni emoji all | fzf | f 0 | cb'
alias ercho='>&2 echo' # echo to stderr
alias exists='type &>/dev/null' # check if a program exists
alias fennel='rlwrap fennel'
alias fu='fd -uu' # fd, but don't ignore any files
alias goog='googler -n5 --np'
alias grep='grep --color=auto'
alias hex='hexyl'
alias is_docker='[[ -f "/.dockerenv" ]]'
alias is_local='! is_not_local'
alias is_not_local='is_remote || is_docker'
alias is_remote='[[ $SSH_TTY || $SSH_CLIENT ]]'
alias is_root='[[ $EUID == 0 ]]'
alias is_su='[[ $(whoami) != $(logname) ]]' # if current user != login user
alias map='parallel'
alias my_home='user_home "$(logname)"'
alias ncdu='ncdu --color=dark'
alias nimr='nim c -r --verbosity:0 --"hint[Processing]":off'
alias node="env NODE_NO_READLINE=1 rlwrap node"
alias notes='te ~/notes/'
alias pb='[[ $PROMPT_BARE ]] && unset PROMPT_BARE || export PROMPT_BARE=1'
alias printv='printf "%q\n"' # v for verbatim
alias ssh='sshrc' # always sshrc
alias tcl='rlwrap tclsh'
alias title='printf "\e]0;%s\a"' # https://tldp.org/HOWTO/Xterm-Title-3.html#ss3.1
alias title-tab='printf "\e]1;%s\a"'
alias title-win='printf "\e]2;%s\a"'
user_home() { eval echo "~$1"; } # http://stackoverflow.com/a/20506895
alias wcl='wc -l'
alias x='chmod +x'

rlh() {
  # reload history
  if [[ $ZSH_VERSION ]]; then
    fc -R
  else
    history -r
  fi
  echo "History reloaded"
}

rls() {
  # "reload shell" config
  if [[ $ZSH_VERSION ]]; then
    echo "Reloading zsh config"
    source "$HOME/.zshrc"
  elif [[ $BASH_VERSION ]]; then
    echo "Reloading bash config"
    source "$HOME/.bashrc"
  else
    echo "Unknown shell, can't reload config"
  fi
}

create() {
  # since scripts can't cd, need a function to cd after 'create-' scripts
  [[ -z "$1" || -z "$2" ]] && echo >&2 "type and project name required" && return 1
  local cmd="create-$1"
  local project="$2"
  shift 2
  ! exists "$cmd" && echo >&2 "'$cmd' doesn't exist" && return 2
  $cmd "$project" "$@" && cd "$project" || return 3
}
