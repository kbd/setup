#!/usr/bin/env bash

# VARS
if [[ -z "$PATH_SET" ]]; then
  export PATH="$HOME/bin:$PATH:$HOME/.cargo/bin:$HOME/.nimble/bin"
  export PATH_SET=1
fi
export PLATFORM="$(uname)"
export PAGER=less
export LESS='-iMFx4 --mouse' # smart-case, status bar, quit 1 screen, 4sp tabs
export EDITOR=vim
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export PYTHONDONTWRITEBYTECODE=1
export PYTHONBREAKPOINT=pudb.set_trace
export PIPENV_SHELL_FANCY=1
export VIRTUAL_ENV_DISABLE_PROMPT=1
export HOMEBREW_NO_INSTALL_CLEANUP=1
export GOPATH="$HOME/go"
export GOBIN="$GOPATH/bin"
export ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern cursor)
export ERL_AFLAGS="-kernel shell_history enabled"  # remember Elixir iex history across sessions
export FZF_DEFAULT_COMMAND='fd -tf -HL'
export FZF_DEFAULT_OPTS='--height 30% --reverse --multi'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd -td -HL'
export FZF_ALT_C_OPTS="--preview 'tree -C {} | head -200'"
_fzf_compgen_path() { fd -tf -HL . "$1"; }
_fzf_compgen_dir() { fd -td -HL . "$1"; }

# SHELL SPECIFIC
if [[ $ZSH_VERSION ]]; then
  alias -g FZF='$(`last_command` | fzf)'
  alias -g L='| $PAGER'
  alias -g H='| head'
fi

# PLATFORM SPECIFIC
if [[ $PLATFORM == 'Darwin' ]]; then
  # PATH="/usr/local/opt/coreutils/libexec/gnubin:$PATH"
  # MANPATH="/usr/local/opt/coreutils/libexec/gnuman:$MANPATH"

  alias awk=gawk
  alias sed=gsed
  alias tar=gtar
  alias ls='/usr/local/bin/gls -F --color=auto'

  alias lock='/System/Library/CoreServices/"Menu Extras"/User.menu/Contents/Resources/CGSession -suspend'
  alias locks='pmset sleepnow' # locks = "lock+sleep". 'sleep' is a unix command

  # bundleid/uti funcs from https://superuser.com/a/341429/
  # useful with 'duti' to set file associations
  bundleid() {
    osascript -e "id of app \"$*\""
  }

  uti() {
    local f="/tmp/me.lri.getuti.${1##*.}"
    touch "$f"
    mdimport "$f"
    mdls -name kMDItemContentTypeTree "$f"
    rm "$f"
  }
fi

# directory/navigation
alias   -- -='cd -'
alias  -- --='cd -2'
alias -- ---='cd -3'
alias     ..='cd ..'
alias    ...='cd ../..'
alias   ....='cd ../../..'
alias  .....='cd ../../../..'
alias ......='cd ../../../../..'

# ls
alias l=ls
alias la='ls -A'
alias lt='ls -t'
alias ll='ls -lh'
alias lla='ll -A'
alias llt='ll -t'
alias llat='ll -At'
alias lsd='ls -d --indicator-style=none -- */'
alias lld='ll -d --indicator-style=none -- */'
cl() { cd -- "$1" && l "${@:2}"; }
cll() { cd -- "$1" && ll "${@:2}"; }
et() { exa -alT --git -I'.git|node_modules|.mypy_cache|.pytest_cache' --color=always "$@" | less -R; }
alias et1='et -L1'
alias et2='et -L2'
alias et3='et -L3'

# edit/open
alias edit=code
alias e=edit
alias e.='e .'
alias o=open
alias o.='o .'
alias a='o -a'

# personal
alias notes='mkdir -p ~/notes/ && e ~/notes/'

# shortcuts/defaults
alias dh='dirs -v'
alias wcl='wc -l'
alias du='du -h'
alias dud='du -d0 .'
alias ncdu='ncdu --color=dark'
alias curl='curl -L'  # follow redirects by default
alias map='parallel'
alias vless=vimpager
alias c=cat
alias cat=bat
alias cn='bat --style=numbers'
alias chn='bat --style=header,numbers'
alias cnh='bat --style=header,numbers'
alias py=ipython
alias pyc='py -c'
alias pym='py -i -c "import pandas as pd; import re; import datetime as dt; from pathlib import Path; import sys; import os; import json; from pprint import pprint as pp;"'
alias x='chmod +x'
alias d='docker'
alias hex='hexyl'
alias grep='grep --color=auto'
alias rg='rg --colors=match:fg:green --colors=line:fg:blue --colors=path:fg:yellow --smart-case'
alias fdu='fd -uu'  # fd, but don't ignore any files
alias fu='fdu'  # fd, but don't ignore any files
alias tcl='rlwrap tclsh'
alias yaegi='rlwrap $GOBIN/yaegi'
alias nimr='nim c -r --verbosity:0 --"hint[Processing]":off'
alias node="env NODE_NO_READLINE=1 rlwrap node"
alias goog='googler -n5 --np'
alias pe=path-extractor
alias ssh='sshrc'  # always sshrc
jqpager() { jq -C "$@" | less -FR; }
alias jq='jqpager'

# "functions"
alias dp='cd "$(dirs -pl | fzf)"'
alias rot13="tr 'A-Za-z' 'N-ZA-Mn-za-m'"

# django
alias da='django-admin'
alias dm='python3 manage.py'  # "django manage"

# "system"
alias ercho='>&2 echo'  # echo to stderr
alias pb='[[ $PROMPT_BARE ]] && unset PROMPT_BARE || PROMPT_BARE=1'
alias last_command='fc -nl -1'
alias history_unique="history | sed 's/.*\\] //' | sort | uniq"  # because bash's history is abominable
exists() { type "$1" &>/dev/null; } # check if a program exists
printv() { printf '%q\n' "$1"; } # v for verbatim
is_remote() { [[ $SSH_TTY || $SSH_CLIENT ]]; }
is_docker() { [[ -f '/.dockerenv' ]]; }
is_not_local() { is_remote || is_docker; }
is_local() { ! is_not_local; }
is_su() { [[ $(whoami) != $(logname) ]]; } # if current user != login user
is_root() { [[ $EUID == 0 ]]; }
user_home() { eval echo "~$1"; } # http://stackoverflow.com/a/20506895
my_home() { user_home "$(logname)"; }

if is_local; then
  # git
  alias g=git
  # create aliases for all short (<= 4 character) git aliases
  for gitalias in $(git alias | grep -E '^.{0,4}$'); do
    # shellcheck disable=SC2139
    alias "g$gitalias=g $gitalias"
  done
  alias g-='gw-'
  alias ga='g af'
  alias gaf='g a -f'
  alias p='gpg'
  alias s='gs'
  gccb() {
    local url="$(cb)"
    local dir="${@:-$(basename "$url" .git)}"
    git clone -- "$url" "$dir" && cd "$dir" || return;
  }
fi

# mkdir + cd
mcd() {
  if [[ -z "$1" ]]; then
    ercho "missing argument"
    return 1
  fi
  mkdir -p -- "$1" && cl "$@" -A
}

# dirname, but treat paths that end in slash as a directory
dirnameslash() {
  if [[ "$1" == */ ]]; then
    echo "$1"
  else
    dirname -- "$1"
  fi
}

# {x}, creating directories if necessary
xpm() {
  # ${@: -1} is a bash/zsh-ism for the last arg. Enables passing args to {x}.
  local d="$(dirnameslash "${@: -1}")"
  if [[ ! -d "$d" ]]; then
    echo "Creating '$d'"  # -v on Mac's mkdir -p does nothing
    mkdir -p -- "$d"
  fi
  local cmd="$1"
  shift
  $cmd "$@"
}
cpm() { xpm cp "$@"; }
mvm() { xpm mv "$@"; }

# touch, creating intermediate directories
t() {
  if [[ -z "$1" ]]; then
    ercho "missing argument"
    return 1
  fi

  for f in "$@"; do
    mkdir -p -- "$(dirnameslash "$f")" && touch -- "$f"
  done
}

# repeat
rep() {
  # https://stackoverflow.com/a/5349842
  printf -- "$1%.s" $(seq 1 ${2-$(tput cols)})
}

filter() {
  # take a space-separated string of words and filter it
  # based on a filter expression (like "word" or "word1|word2").
  # This seems goofy but at least it's a simple one-liner.
  # note I *don't* want to quote $1, since this is meant to operate on "words"
  echo $1 | tr ' ' '\n' | grep -Ewv "$2" | tr '\n' ' '
}

join_by() {
  # usage: join_by delim list of strings
  # join_by - a b c de => a-b-c-de
  local d=$1
  local f=$2
  shift 2
  printf "%s" "$f${@/#/$d}";
}

# "reload history"
rlh() {
  if [[ $ZSH_VERSION ]]; then
    fc -R
  else
    history -r
  fi
  echo "History reloaded"
}

# "reload shell"
rls() {
  # make it easier to reload shell config
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
