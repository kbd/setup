#!/usr/bin/env bash

# VARS
if [[ -z "$PATH_SET" ]]; then
    export PATH="$HOME/bin:$HOME/bin/scripts:$PATH:$HOME/.cargo/bin"
    export PATH_SET=1
fi
export PLATFORM=$(uname)
export PAGER=less
export LESS='-iM'  # smart-case searches and status bar
export EDITOR=vim
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export PYTHONDONTWRITEBYTECODE=1
export PIPENV_SHELL_FANCY=1
export VIRTUAL_ENV_DISABLE_PROMPT=1
export GOPATH="$HOME/go"
export GOBIN="$GOPATH/bin"
export ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern cursor)
export ERL_AFLAGS="-kernel shell_history enabled"  # remember Elixir iex history across sessions
export FZF_DEFAULT_COMMAND='fd -tf -HL'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
_fzf_compgen_path() { $FZF_DEFAULT_COMMAND "$1"; }
_fzf_compgen_dir() { fd -td -HL "$1"; }

# ALIASES
alias   -- -='cd -'
alias     ..='cd ..'
alias    ...='cd ../..'
alias   ....='cd ../../..'
alias  .....='cd ../../../..'
alias ......='cd ../../../../..'

alias l=ls
alias la='ls -a'
alias ll='ls -l'
alias lla='ls -la'
# gnu ls
# '--' necessary to correctly handle filenames beginning with -
# bsd ls handles this correctly by default and doesn't allow --
# indicator-style=none so you don't get directories with // at the end
alias lsd='ls -d --indicator-style=none -- */'
alias lld='ll -d --indicator-style=none -- */'

alias wcl='wc -l'
alias du='du -h'
alias dud='du -d0 .'
alias ncdu='ncdu --color=dark'
alias grep='grep --color=auto'
alias g=grep
alias h=history
alias curl='curl -L'  # follow redirects by default
alias map='parallel'
alias vi=vim
alias v='f -e vim'  # from https://github.com/clvv/fasd#examples
alias vless=vimpager
alias p=python3
alias py=ipython
alias pe=path-extractor
alias c=cat
alias cat=bat
alias bat='bat --italic-text=always'
alias x='chmod +x'
alias hex='hexyl'

alias edit=\$EDITOR "$@"
alias e=edit
alias e.='e .'
alias o=open
alias o.='o .'

alias s='git s'
alias gl='git l'

alias tcl='rlwrap tclsh'
alias node="env NODE_NO_READLINE=1 rlwrap node"
alias ts-node="ts-node -D6133"  # disable 'declared but not used' errors
alias goog='googler -n3 --np'

alias ercho='>&2 echo'  # echo to stderr
alias last_command='fc -nl -1'
alias history_unique="history | sed 's/.*\\] //' | sort | uniq"  # because bash's history is abominable

# SHELL SPECIFIC
case $(current_shell) in
    zsh)
        alias history='history -i'  # always include timestamp
        alias hs='h 0 | rg'  # 'history search'

        # global aliases (zsh-only)
        alias -g FZF='$(`last_command` | fzi)'
        alias -g L='| $PAGER'  # would be nice to map ↑ +this to ⌘l
    ;;
    bash)
        alias hs='h | rg'
    ;;
esac

# PLATFORM SPECIFIC
if [[ $PLATFORM == 'Darwin' ]]; then
    export EDITOR='open -t'
    # PATH="/usr/local/opt/coreutils/libexec/gnubin:$PATH"
    # MANPATH="/usr/local/opt/coreutils/libexec/gnuman:$MANPATH"

    alias awk=gawk
    alias sed=gsed
    alias tar=gtar
    alias ls='gls -F --color=auto'

    alias lock='/System/Library/CoreServices/"Menu Extras"/User.menu/Contents/Resources/CGSession -suspend'
fi
