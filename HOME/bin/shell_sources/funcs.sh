#!/usr/bin/env bash
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
    mkdir -p -- "$1" && cd -- "$1"
}

# cd + ls
cl() {
    cd -- "$1" && ls "${@:2}"
}

# dirname, but treat paths that end in slash as a directory
dirnameslash(){
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

# touch directory
td() {
    if [[ -z "$1" ]]; then
        ercho "missing argument"
        return 1
    fi

    for d in "$@"; do
        mkdir -p -- "$d" && touch -- "$d"
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
