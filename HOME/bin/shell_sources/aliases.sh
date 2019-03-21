#!/usr/bin/env bash

# VARS
if [[ -z "$PATH_SET" ]]; then
    export PATH="$HOME/bin:$PATH:$HOME/.cargo/bin"
    export PATH_SET=1
fi
export PLATFORM="$(uname)"
export PAGER=less
export LESS='-iM'  # smart-case searches and status bar
export EDITOR=vim
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export PYTHONDONTWRITEBYTECODE=1
export PYTHONBREAKPOINT=pudb.set_trace
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
alias lt='ls -t'
alias ll='ls -l'
alias lla='ls -la'
alias llt='ls -lt'
alias llat='ls -lat'
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

alias g=git
alias s='git s'
alias gl='git l'

alias tcl='rlwrap tclsh'
alias node="env NODE_NO_READLINE=1 rlwrap node"
alias ts-node="ts-node -D6133"  # disable 'declared but not used' errors
alias goog='googler -n3 --np'

alias ercho='>&2 echo'  # echo to stderr
alias last_command='fc -nl -1'
alias history_unique="history | sed 's/.*\\] //' | sort | uniq"  # because bash's history is abominable

# FUNCTIONS
# source a file or a directory of files, ignore if doesn't exist
_source() {
    if [[ -d "$1" ]]; then
        # if it's a directory, source everything in the directory, recursively
        local file
        for file in "$1"/**/*.sh; do  # requires bash 4 and shopt -s globstar
            source "$file" 2>/dev/null
        done
    elif [[ -f "$1" ]]; then
        # If it's a file, source it
        source "$1" 2>/dev/null
    fi
}

exists() {
    # check if a program exists
    type "$1" &>/dev/null
}

printv() {  # v for verbatim
    printf '%q\n' "$1"
}

# mkdir + cd
mcd() {
    if [[ -z "$1" ]]; then
        ercho "missing argument"
        return 1
    fi
    mkdir -p -- "$1" && cl "$@"
}

# cd + ls
cl() {
    cd -- "$1" && ls "${@:2}"
}

# dirname, but treat paths that end in slash as a directory
dirnameslash() {
    if [[ "$1" == */ ]]; then
        echo "$1"
    else
        dirname -- "$1"
    fi
}

# cp, creating directories if necessary
cpm() {
    # ${@: -1} is a bash/zsh-ism for the last arg. Enables passing args to cp.
    local d="$(dirnameslash "${@: -1}")"
    if [[ ! -d "$d" ]]; then
        echo "Creating '$d'"  # -v on Mac's mkdir -p does nothing
        mkdir -p -- "$d"
    fi
    cp "$@"
}

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

# get the homedir of another user. Be careful cause of eval.
# http://stackoverflow.com/a/20506895
user_home() {
    eval echo "~$1"
}

my_home() {
    user_home "$(logname)"
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

is_remote() {
    [[ $SSH_TTY || $SSH_CLIENT ]]
}

is_su() {
    [[ $USER != "$(logname)" ]]  # if current user != login user
}

is_root() {
    [[ $EUID == 0 ]]
}

# "reload history"
rlh() {
    if [[ "$(current_shell)" == 'zsh' ]]; then
        fc -R
    else
        history -r
    fi
    echo "History reloaded"
}

# "reload shell"
rls() {
    # make it easier to reload shell config
    local s=$(current_shell)
    case $s in
        bash)
            echo "Reloading bash config"
            source "$HOME/.bash_profile"
        ;;
        zsh)
            echo "Reloading zsh config"
            source "$HOME/.zshrc"  # not perfect, doesn't get all files
        ;;
        *)
            echo "Unknown shell '$s', can't reload config"
        ;;
    esac
}

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

    # have sshrc use GNU tar because tar-ing on Mac (with BSD tar) makes GNU tar
    # spit out a bunch of warnings on the server from extended stuff it doesn't
    # understand - https://github.com/Russell91/sshrc/pull/76
    alias sshrc='PATH="$(brew --prefix gnu-tar)/libexec/gnubin:$PATH" sshrc'

    alias lock='/System/Library/CoreServices/"Menu Extras"/User.menu/Contents/Resources/CGSession -suspend'
fi
