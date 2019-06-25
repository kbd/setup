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
export HOMEBREW_NO_INSTALL_CLEANUP=1
export GOPATH="$HOME/go"
export GOBIN="$GOPATH/bin"
export GREP_OPTIONS='--color=auto'
export ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern cursor)
export ERL_AFLAGS="-kernel shell_history enabled"  # remember Elixir iex history across sessions
export FZF_DEFAULT_COMMAND='fd -tf -HL'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
_fzf_compgen_path() { fd -tf -HL . "$1"; }
_fzf_compgen_dir() { fd -td -HL . "$1"; }

# SHELL SPECIFIC
case $(current_shell) in
    zsh)
        alias -g FZF='$(`last_command` | fzi)'
        alias -g L='| $PAGER'
        alias -g H='| head'
    ;;
    bash)
    ;;
esac

# PLATFORM SPECIFIC
if [[ $PLATFORM == 'Darwin' ]]; then
    export EDITOR='open -t'  # use default text file association
    # PATH="/usr/local/opt/coreutils/libexec/gnubin:$PATH"
    # MANPATH="/usr/local/opt/coreutils/libexec/gnuman:$MANPATH"

    alias awk=gawk
    alias sed=gsed
    alias tar=gtar
    alias ls='/usr/local/bin/gls -F --color=auto'

    # have sshrc use GNU tar because tar-ing on Mac (with BSD tar) makes GNU tar
    # spit out a bunch of warnings on the server from extended stuff it doesn't
    # understand - https://github.com/Russell91/sshrc/pull/76
    alias sshrc='PATH="$(brew --prefix gnu-tar)/libexec/gnubin:$PATH" sshrc'

    alias lock='/System/Library/CoreServices/"Menu Extras"/User.menu/Contents/Resources/CGSession -suspend'

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
alias     ..='cd ..'
alias    ...='cd ../..'
alias   ....='cd ../../..'
alias  .....='cd ../../../..'
alias ......='cd ../../../../..'

# ls
alias l=ls
alias la='ls -a'
alias lt='ls -t'
alias ll='ls -lh'
alias lla='ll -a'
alias llt='ll -t'
alias llat='ll -at'
alias lsd='ls -d --indicator-style=none -- */'
alias lld='ll -d --indicator-style=none -- */'
cl() { cd -- "$1" && l "${@:2}"; }
cll() { cd -- "$1" && ll "${@:2}"; }
et(){ exa -alT --git -I.git --color=always "$@" | less -RFX; }
alias et1='et -L1'
alias et2='et -L2'
alias et3='et -L3'

# edit/open
alias edit=\$EDITOR "$@"
alias e=edit
alias e.='e .'
alias o=open
alias o.='o .'

alias wcl='wc -l'
alias du='du -h'
alias dud='du -d0 .'
alias ncdu='ncdu --color=dark'
alias curl='curl -L'  # follow redirects by default
alias map='parallel'
alias v='f -e vim'  # from https://github.com/clvv/fasd#examples
alias vi=vim
alias vless=vimpager
alias c=cat
alias cat=bat
alias p=python3
alias py=ipython
alias pyc='py -c'
alias x='chmod +x'
alias hex='hexyl'
alias rg='rg --colors=match:fg:green --colors=line:fg:blue --colors=path:fg:yellow --smart-case'

alias tcl='rlwrap tclsh'
alias nimr='nim c -r --verbosity:0 --"hint[Processing]":off'
alias node="env NODE_NO_READLINE=1 rlwrap node"
alias ts-node="ts-node -D6133"  # disable 'declared but not used' errors
alias goog='googler -n5 --np'
alias rot13="tr 'A-Za-z' 'N-ZA-Mn-za-m'"

alias g=git
# create aliases for all short (<= 4 character) git aliases
for gitalias in $(git alias | grep -E '^.{0,4}$'); do
    # shellcheck disable=SC2139
    alias "g$gitalias=g $gitalias"
done
alias s='g s'
alias ga='g af'
alias g-='gco -'

# "system"
alias ercho='>&2 echo'  # echo to stderr
alias pb='[[ $PROMPT_BARE ]] && unset PROMPT_BARE || PROMPT_BARE=1'
alias last_command='fc -nl -1'
alias history_unique="history | sed 's/.*\\] //' | sort | uniq"  # because bash's history is abominable
exists() { type "$1" &>/dev/null; } # check if a program exists
printv() { printf '%q\n' "$1"; } # v for verbatim
is_remote() { [[ $SSH_TTY || $SSH_CLIENT ]]; }
is_su() { [[ $USER != "$(logname)" ]]; } # if current user != login user
is_root() { [[ $EUID == 0 ]]; }
user_home() { eval echo "~$1"; } # http://stackoverflow.com/a/20506895
my_home() { user_home "$(logname)"; }

# mkdir + cd
mcd() {
    if [[ -z "$1" ]]; then
        ercho "missing argument"
        return 1
    fi
    mkdir -p -- "$1" && cl "$@"
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
