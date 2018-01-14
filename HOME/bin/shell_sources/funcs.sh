#!/usr/bin/env bash
alias ercho='>&2 echo'  # echo to stderr

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

printv() {  # v for verbatim
    printf '%q\n' "$1"
}

# 'less' using vim
vless() {
    # http://vimdoc.sourceforge.net/htmldoc/starting.html#$VIMRUNTIME
    # http://vimdoc.sourceforge.net/htmldoc/various.html#less
    # maybe use https://github.com/rkitover/vimpager instead?
    local vimruntime=`vim -e -T dumb --cmd 'exe "set t_cm=\<C-M>"|echo $VIMRUNTIME|quit' | tr -d '\015' `
    local lessvim="$vimruntime/macros/less.vim"
    vim -u "$lessvim" "$@"
}

# mkdir + cd
mcd() {
    if [[ -z "$1" ]]; then
        ercho "missing argument"
        return 1
    fi
    mkdir -p "$1" && cd "$1";
}

# cd + ls
cl() {
    cd "$1" && ls "${@:2}"
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

is_remote() {
    [[ $SSH_TTY || $SSH_CLIENT ]]
}

is_su() {
    [[ $USER != "$(logname)" ]]  # if current user != login user
}

is_root() {
    [[ $EUID == 0 ]]
}

# "reload shell"
rls() {
    # make it easier to reload shell config
    . "$HOME/.bash_profile"
}
