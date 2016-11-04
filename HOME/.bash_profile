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
export _Z_NO_RESOLVE_SYMLINKS=1
export VERTICAINI=/etc/vertica.ini
# ls colors I expect: exe=red, dir=blue, symlink=pink, pipe=yellow
export LS_COLORS="ex=31"  # set executables to red (gnu ls)
export HISTCONTROL='ignoredups'  # I'd prefer to ignore dups on autocomplete instead of eliminating
                                 # them from history, but that seems not possible
export HISTTIMEFORMAT="[%F %T %z] "

export    COLOR_RESET="$(tput sgr0)"
export     COLOR_BOLD="$(tput bold)"
export      COLOR_DIM="$(tput dim)"
export    COLOR_ULINE="$(tput smul)"
export COLOR_NO_ULINE="$(tput rmul)"
export    COLOR_BLINK="$(tput blink)"

export    COLOR_BLACK="$(tput setaf 0)"
export      COLOR_RED="$(tput setaf 1)"
export    COLOR_GREEN="$(tput setaf 2)"
export   COLOR_YELLOW="$(tput setaf 3)"
export     COLOR_BLUE="$(tput setaf 4)"
export   COLOR_PURPLE="$(tput setaf 5)"
export     COLOR_CYAN="$(tput setaf 6)"
export     COLOR_GREY="$(tput setaf 7)"

export  BGCOLOR_BLACK="$(tput setab 0)"
export    BGCOLOR_RED="$(tput setab 1)"
export  BGCOLOR_GREEN="$(tput setab 2)"
export BGCOLOR_YELLOW="$(tput setab 3)"
export   BGCOLOR_BLUE="$(tput setab 4)"
export BGCOLOR_PURPLE="$(tput setab 5)"
export   BGCOLOR_CYAN="$(tput setab 6)"
export   BGCOLOR_GREY="$(tput setab 7)"

# BEGIN prompt code

_prompt_date() {
    echo '\[$COLOR_GREY\]\D{%m/%d@%H:%M}\[$COLOR_RESET\]:'
}

_prompt_user() {
    if [[ $EUID -eq 0 ]]; then  # if root
        local user='\[$COLOR_RED\]\u\[$COLOR_RESET\]'
    elif [[ $USER != "$(logname)" ]]; then  # if current user != login user
        local user='\[$COLOR_YELLOW\]\[$COLOR_BOLD\]\u\[$COLOR_RESET\]'
    else
        local user='\[$COLOR_GREEN\]\u\[$COLOR_RESET\]'
    fi
    echo "$user"
}

_prompt_at() {
    # show the @ in red if not local
    local at='@'
    if [[ -n $SSH_TTY ]]; then
        at='\[$COLOR_RED\]\[$COLOR_BOLD\]'$at'\[$COLOR_RESET\]'
    fi
    echo "$at"
}

# a function so that it can do more logic later if desired
# such as showing the full host by default if you're not local
_prompt_show_full_host() { [[ -n $PROMPT_SHOW_FULL_HOST ]]; }

_prompt_host() {
    local host
    _prompt_show_full_host && host='\H' || host='\h'
    echo '\[$COLOR_BLUE\]'$host'\[$COLOR_RESET\]'
}

# screen/tmux status in prompt
_prompt_screen() {
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
        echo -n '[\[$COLOR_ULINE\]\[$COLOR_GREEN\]'"$screen"
        echo -n '\[$COLOR_BLACK\]:\[$COLOR_BLUE\]'"$name"
        echo -n '\[$COLOR_BLACK\]:\[$COLOR_PURPLE\]'"$window"
        echo '\[$COLOR_RESET\]]'
    fi
}

_prompt_sep() {
    # separator - red if cwd unwritable
    local sep=':';
    if [[ ! -w "${PWD}" ]]; then
        sep='\[$COLOR_RED\]\[$COLOR_BOLD\]'$sep'\[$COLOR_RESET\]'
    fi
    echo "$sep"
}

_prompt_path() {
    echo '\[$COLOR_PURPLE\]\w\[$COLOR_RESET\]'
}

# source control information in prompt
_prompt_repo() {
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
            vcs='\[$COLOR_CYAN\]'"$vcs"'\[$COLOR_RESET\]:\[$COLOR_YELLOW\]'"$branch"'\[$COLOR_RESET\]'
        fi
        echo "[$vcs]"
    fi
}

# running and stopped jobs
_prompt_jobs() {
    local running=$(( $(jobs -rp | wc -l) ))  # convert to numeric
    local stopped=$(( $(jobs -sp | wc -l) ))  # convert to numeric

    local jobs=''
    if [[ $running -ne 0 ]]; then
        jobs='\[$COLOR_GREEN\]'$running'&\[$COLOR_RESET\]'  # '&' for 'background'
    fi

    if [[ $stopped -ne 0 ]]; then
        if [[ $jobs ]]; then
            jobs="$jobs:"  # separate running and stopped job count with a colon
        fi
        jobs="$jobs"'\[$COLOR_RED\]'$stopped'z\[$COLOR_RESET\]'  # 'z' for 'ctrl+z' to stop
    fi

    if [[ $jobs ]]; then
        echo "[$jobs]"
    fi
}

_prompt_char() {
    # prompt char, with info about last return code
    local pchar='\$'
    if [[ $_LAST_RETURN_CODE -eq 0 ]]; then
        local prompt='\[$COLOR_GREEN\]'"$pchar"'\[$COLOR_RESET\]'
    else
        local prompt='\[$COLOR_RED\]'"$pchar:$_LAST_RETURN_CODE"'\[$COLOR_RESET\]'
    fi
    echo "$prompt "
}

_prompt_text() {
    # control formatting of what you type. Formatting is reset in trap_debug.
    echo '\[$COLOR_BOLD\]'
}

_save_last_return_code() {
    export _LAST_RETURN_CODE=$?  # save away last command result
}

trap_debug() {
    printf "$COLOR_RESET"
}
trap trap_debug DEBUG

# PROMPT_COMMAND function
generate_ps1() {
    _save_last_return_code
    local ps1=''
    for f in date user at host screen sep path repo jobs char text; do
        ps1+="\$(_prompt_$f)"
    done

    # if provided no argument, set PS1 yourself, else echo it to be used elsewhere
    if [[ -z $1 ]]; then
        eval "PS1=$ps1"
    else
        echo $ps1
    fi
}

# basic prompt
# export PS1="\u@\h:\w$ "

prompt_command_is_readonly() {
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
alias la="ls -a"
alias ll="ls -l"
alias lla="ls -la"

alias edit=\$EDITOR "$@"
alias e=edit
alias e.="e ."

alias o=open
alias o.="o ."

alias grep="grep -E --color=auto"
alias fgrep="grep -F"
alias g=grep

alias h=history

alias v=vim
alias vi=vim

alias ercho='>&2 echo'  # echo to stderr

# http://www.faqs.org/docs/Linux-mini/Xterm-Title.html#s3
alias title='printf "\e]0;%s\a"'
alias tabtitle='printf "\e]1;%s\a"'
alias wintitle='printf "\e]2;%s\a"'

# http://invisible-island.net/xterm/xterm.faq.html
# http://www.opensource.apple.com/source/X11apps/X11apps-30.1/xterm/xterm-251/ctlseqs.txt
# http://stackoverflow.com/questions/4471278/how-to-capture-the-title-of-a-terminal-window-in-bash-using-ansi-escape-sequence
# I think these only work on linux, can't test atm
alias getwintitle='printf "\e[21t"'
alias gettabtitle='printf "\e[20t"'

alias ipython="ipython_func '' --no-banner --no-confirm-exit"
alias ipython3="ipython_func 3 --no-banner --no-confirm-exit"

# PLATFORM SPECIFIC
if [[ $PLATFORM == 'Darwin' ]]; then
    export EDITOR='open -t'

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

ipython_func() {
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
_source() {
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

printv() {  # v for verbatim
    printf '%s\n' "$1"
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

# download
dl() {
    local url="$(cb)"  # get from clipboard
    echo "${COLOR_BOLD}${COLOR_BLUE}Downloading: ${COLOR_YELLOW}$url${COLOR_RESET}"
    youtube-dl "$@" "$url"
}

# get the homedir of another user. Be careful cause of eval.
# http://stackoverflow.com/a/20506895
user_home() {
    eval echo "~$1"
}

my_home() {
    user_home $(logname)
}

# SHOPTS
shopt -s histappend
shopt -s dotglob
shopt -s globstar 2>/dev/null  # not supported in bash 3
shopt -s autocd 2>/dev/null  # not supported in bash 3

# bind my keyboard shortcuts even when su-d
if [[ $USER != "$(logname)" ]]; then
    bind -f "$(my_home)/.inputrc"
fi

# source my bash_profile even when su-ing, derived from http://superuser.com/a/636475
# note: doesn't work if user you su to has PROMPT_COMMAND set. Not sure of workaround
alias su="export PROMPT_COMMAND='source $(my_home)/.bash_profile; $PROMPT_COMMAND' && su"

# SOURCES
_source "$HOME/bin/shell_sources"

# COMPLETIONS
# note, completions must be at the end because 'z' modifies
# your PROMPT_COMMAND, so it has to come after you set yours
_source /usr/local/etc/bash_completion.d
complete -cf sudo  # allow autocompletions after sudo.

# machine-specific bash config
_source .config/machine_specific/.bash_profile
