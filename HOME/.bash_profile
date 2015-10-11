#!/usr/bin/env bash
export PLATFORM=$(uname)
export PATH="$HOME/bin:$PATH"
export EDITOR=vi
export SVN_EDITOR=vi
export GIT_EDITOR=vi
export GIT_PS1_SHOWCOLORHINTS=1
export GIT_PS1_SHOWDIRTYSTATE=1
export GIT_PS1_SHOWSTASHSTATE=1
export GIT_PS1_SHOWUNTRACKEDFILES=1
export GIT_PS1_SHOWUPSTREAM='auto'
export VERTICAINI=/etc/vertica.ini
export LS_COLORS="ex=31"  # set executables to red (gnu ls)
export GREP_OPTIONS='--color=auto'
export HISTCONTROL='ignoredups'  # I'd prefer to ignore dups on autocomplete instead of eliminating
                                 # them from history, but that seems not possible
export HISTTIMEFORMAT="[%F %T %z] "

export    COLOR_RESET="\[$(tput sgr0)\]"
export     COLOR_BOLD="\[$(tput bold)\]"
export      COLOR_DIM="\[$(tput dim)\]"
export    COLOR_ULINE="\[$(tput smul)\]"
export COLOR_NO_ULINE="\[$(tput rmul)\]"
export    COLOR_BLINK="\[$(tput blink)\]"

export    COLOR_BLACK="\[$(tput setaf 0)\]"
export      COLOR_RED="\[$(tput setaf 1)\]"
export    COLOR_GREEN="\[$(tput setaf 2)\]"
export   COLOR_YELLOW="\[$(tput setaf 3)\]"
export     COLOR_BLUE="\[$(tput setaf 4)\]"
export   COLOR_PURPLE="\[$(tput setaf 5)\]"
export     COLOR_CYAN="\[$(tput setaf 6)\]"
export     COLOR_GREY="\[$(tput setaf 7)\]"

export  BGCOLOR_BLACK="\[$(tput setab 0)\]"
export    BGCOLOR_RED="\[$(tput setab 1)\]"
export  BGCOLOR_GREEN="\[$(tput setab 2)\]"
export BGCOLOR_YELLOW="\[$(tput setab 3)\]"
export   BGCOLOR_BLUE="\[$(tput setab 4)\]"
export BGCOLOR_PURPLE="\[$(tput setab 5)\]"
export   BGCOLOR_CYAN="\[$(tput setab 6)\]"
export   BGCOLOR_GREY="\[$(tput setab 7)\]"

# BEGIN prompt code

function _prompt_date {
    echo "$COLOR_GREY\D{%m/%d@%H:%M}$COLOR_RESET:"
}

function _prompt_user {
    # root/user info
    if [[ $EUID -eq 0 ]]; then
        local user="$COLOR_RED\u$COLOR_RESET"
    elif [[ $USER != "$(logname)" ]]; then
        # if the current user is different from the logon user
        local user="$COLOR_YELLOW$COLOR_BOLD\u$COLOR_RESET"
    else
        local user="$COLOR_GREEN\u$COLOR_RESET"
    fi
    echo "$user"
}

function _prompt_at {
    # show the @ in red if not local
    local at='@'
    if [[ -n $SSH_TTY ]]; then
        at="$COLOR_RED$COLOR_BOLD$at$COLOR_RESET"
    fi
    echo "$at"
}

# a function so that it can do more logic later if desired
# such as showing the full host by default if you're not local
function _prompt_show_full_host { [[ -n $PROMPT_SHOW_FULL_HOST ]]; }

function _prompt_host {
    local host
    _prompt_show_full_host && host='\H' || host='\h'
    echo "$COLOR_BLUE$host$COLOR_RESET"
}

# screen/tmux status in prompt
function _prompt_screen {
    if [[ $TERM == "screen" ]]; then
        # figure out whether 'screen' or 'tmux'
        if [[ -n "$TMUX" ]]; then
            local screen='tmux'
            local name="$(tmux display-message -p '#S')"
            local window="$(tmux display-message -p '#I')"
        else  # screen
            local screen='screen'
            local name="$STY"
            local window="$WINDOW"
        fi
        echo "[$COLOR_ULINE$COLOR_GREEN$screen$COLOR_BLACK:$COLOR_BLUE$name$COLOR_BLACK:$COLOR_PURPLE$window$COLOR_RESET]"
    fi
}

function _prompt_sep {
    # separator - red if cwd unwritable
    local sep=':';
    if [[ ! -w "${PWD}" ]]; then
        sep="$COLOR_RED$COLOR_BOLD$sep$COLOR_RESET"
    fi
    echo "$sep"
}

function _prompt_path {
    echo "$COLOR_PURPLE\w$COLOR_RESET"
}

# source control information in prompt
function _prompt_repo {
    local vcs=
    local branch=
    if [[ $(declare -F __git_ps1) ]]; then
        branch="$(__git_ps1 '%s')"
    fi
    if [[ $branch ]]; then
        # this is what to use if __git_ps1 is not sourced
        # branch=$(type -P git &>/dev/null && git branch 2>/dev/null)
        vcs=git
    else
        # would be nice to replace with hg_prompt and get dirty information etc.
        branch=$(type -P hg &>/dev/null && hg branch 2>/dev/null)
        if [[ $branch ]]; then
            vcs=hg
        elif [[ -e .bzr ]]; then
            vcs=bzr
        elif [[ -e .svn ]]; then
            vcs=svn
        fi
    fi
    if [[ $vcs ]]; then
        if [[ $branch ]]; then
            vcs="$COLOR_CYAN$vcs$COLOR_RESET:$COLOR_YELLOW$branch$COLOR_RESET"
        fi
        echo -n "[$vcs]"
    fi
}

# running and stopped jobs
function _prompt_jobs {
    local running=$(( $(jobs -rp | wc -l) ))  # convert to numeric
    local stopped=$(( $(jobs -sp | wc -l) ))  # convert to numeric

    local jobs=''
    if [[ $running -ne 0 ]]; then
        jobs="$COLOR_GREEN$running&$COLOR_RESET"  # '&' for 'background'
    fi

    if [[ $stopped -ne 0 ]]; then
        if [[ $jobs ]]; then
            jobs="$jobs:"  # separate running and stopped job count with a colon
        fi
        jobs="$jobs$COLOR_RED${stopped}z$COLOR_RESET"  # 'z' for 'ctrl+z' to stop
    fi

    if [[ $jobs ]]; then
        echo "[$jobs]"
    fi
}

function _prompt_char {
    # prompt char, with info about last return code
    local pchar="\\$"  # slashes to prevent further substitution
    if [[ $_LAST_RETURN_CODE -eq 0 ]]; then
        local prompt="$COLOR_GREEN$pchar$COLOR_RESET"
    else
        local prompt="$COLOR_RED$pchar:$_LAST_RETURN_CODE$COLOR_RESET"
    fi
    echo "$prompt "
}

function _save_last_return_code {
    export _LAST_RETURN_CODE=$?  # save away last command result
}

function trap_debug {
    printf "\e[0m"  # reset prompt formatting
}
trap trap_debug DEBUG

# PROMPT_COMMAND function
function generate_ps1 {
    _save_last_return_code
    local ps1=''
    for f in 'date' 'user' 'at' 'host' 'screen' 'sep' 'path' 'repo' 'jobs' 'char'; do
        ps1+="\$(_prompt_$f)"
    done

    ps1+='$COLOR_BOLD'  # bold what you type. Reset formatting in trap_debug.

    # if provided no argument, set PS1 yourself, else echo it to be used elsewhere
    if [[ -z $1 ]]; then
        eval "PS1=$ps1"
    else
        echo $ps1
    fi
}

# basic prompt
# export PS1="\u@\h:\w$ "

function prompt_command_is_readonly {
    readonly -p | awk -F' |=' '{print $3}' | fgrep -qx 'PROMPT_COMMAND'
}

# work around the PROMPT_COMMAND being read-only. At least you'll get a basic prompt.
if prompt_command_is_readonly; then
    echo "PROMPT_COMMAND is readonly"
    eval "PS1=$(generate_ps1 1)"
else
    PROMPT_COMMAND=generate_ps1
fi

# END prompt code

# ALIASES
alias   -- -="cd -"
alias     ..="cd .."
alias    ...="cd ../.."
alias   ....="cd ../../.."
alias  .....="cd ../../../.."
alias ......="cd ../../../../.."

alias l=ls
alias ll="ls -l"
alias lla="ls -la"

alias edit=\$EDITOR "$@"
alias e=edit
alias e.="e ."

alias grep=egrep
alias g=grep

alias h=history

alias ercho='>&2 echo'  # echo to stderr

# backslashes are necessary to call the function 'ipython' instead of the built-in
alias ipython="\ipython '' --no-banner --no-confirm-exit"
alias ipython3="\ipython 3 --no-banner --no-confirm-exit"

# PLATFORM SPECIFIC
if [[ $PLATFORM == 'Darwin' ]]; then
    export EDITOR='open -t'

    function cb { [[ -t 0 ]] && pbpaste || pbcopy; }  # cb=clipboard
    # see if you can use xclip or xsel on linux, or write your own
    # that behaves similarly but uses an env variable or a file
    # http://superuser.com/questions/288320/whats-like-osxs-pbcopy-for-linux

    # bsd ls
    alias ls="ls -FG"
    # escape ls to ignore -F so you don't get directories with // at the end
    alias lsd="\ls -dG */"
    alias lld="\ls -ldG */"
else
    # gnu ls
    alias ls="ls -F --color"
    # '--' necessary to correctly handle filenames beginning with -
    # bsd ls handles this correctly by default and doesn't allow --
    # indicator-style=none so you don't get directories with // at the end
    alias lsd="ls -d --indicator-style=none -- */"
    alias lld="ll -d --indicator-style=none -- */"
fi

function ipython {
    # fix ipython to handle arguments like python
    # https://twitter.com/keithdevens/status/595294880533876736
    # this is an imperfect hack because you could do "-c 'command'" and have command
    # actually be a file in contrived cases, but this shouldn't cause problems normally
    # to show why this is necessary, use ipython -i python print_sysargv.py -i
    local version=$1
    shift
    local cmd="ipython$version"
    local new_args=("$@")

    local i=1
    for arg in "$@"; do
        i=$((i+1))
        if [[ $arg != -* && -f $arg ]]; then
            # if arg doesn't start with a dash and the arg is a file
            # then consider this the script passed to ipython and
            # all args after this are args to the script
            new_args=("${@:0:$i}" "--" "${@:$i}")
            break
        fi
    done
    command $cmd "${new_args[@]}"
}

# source a file or a directory of files
function _source {
    if [[ -d "$1" ]]; then
        # if it's a directory, source everything in the directory
        for I in "$1"/*; do
            source "$I" 2>/dev/null
        done
    elif [[ -f "$1" ]]; then
        # else source the file if it exists
        source "$1" 2>/dev/null
    fi
}

# set the window title
function set_title {
    echo -ne "\033]0;$1\007"
}
alias settitle=set_title

# mkdir + cd
function mcd {
    if [[ -z "$1" ]]; then
        echo "missing argument"
        return 1
    fi
    mkdir -p "$1" && cd "$1";
}

# cd + ls
function cl {
    cd "$1"
    shift
    ls "${@}"
}

# SHOPTS
shopt -s histappend
shopt -s dotglob
shopt -s globstar 2>/dev/null  # not supported in bash 3
shopt -s autocd 2>/dev/null  # not supported in bash 3

# BEGIN su hack

# brilliant hack below derived from http://superuser.com/a/636475
# causes your own bash_profile to be sourced even when su-ing around
if [[ $USER == "$(logname)" ]]; then
    export _LOGIN_BASH_PROFILE="$HOME/.bash_profile"
fi

alias su="export PROMPT_COMMAND='source $_LOGIN_BASH_PROFILE; $PROMPT_COMMAND' && su"

# note: this doesn't work if the user you SU to has their own PROMPT_COMMAND set
# todo: figure out how to get around this...

# END su hack

# SOURCES
_source "$HOME/bin/shell_sources"

# COMPLETIONS
# note, completions must be at the end because 'z' modifies
# your PROMPT_COMMAND, so it has to come after you set yours
_source /usr/local/etc/bash_completion.d
complete -cf sudo  # allow autocompletions after sudo.

# machine-specific bash config
_source .bash_profile_machine_specific
