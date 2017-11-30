# configuration variables exposed
#
# $PROMPT_FULL_HOST
#   shows the full hostname (\H vs \h in ps1)
#
# $PROMPT_SHORT_DISPLAY
#   don't display things like username@host if you're the main user on localhost
#   and the date if you have iTerm's timestamp on. i.e. elide unnecessary info.
#   "use short display" implies "hide date"
#
# $PROMPT_HIDE_DATE
#   don't show date in the prompt. Less necessary thanks to iterm's timestamps
#
# $PROMPT_PREFIX
#   override to control what's displayed at the start of the prompt line

_prompt_date() {
    echo '\[$COLOR_GREY\]\D{%m/%d@%H:%M}\[$COLOR_RESET\]:'
}

_prompt_user() {
    local color='\[$COLOR_GREEN\]'
    if [[ $(is_root) ]]; then
        color='\[$COLOR_RED\]'
    elif [[ $(is_su) ]]; then
        color='\[$COLOR_YELLOW\]\[$COLOR_BOLD\]'
    fi
    echo "$color"'\u\[$COLOR_RESET\]'
}

_prompt_at() {
    # show the @ in red if not local
    local at='@'
    if [[ $(is_remote) ]]; then
        at='\[$COLOR_RED\]\[$COLOR_BOLD\]'$at'\[$COLOR_RESET\]'
    fi
    echo "$at"
}

# a function so that it can do more logic later if desired
# such as showing the full host by default if you're not local
_prompt_show_full_host() { [[ -n "$PROMPT_FULL_HOST" ]]; }

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
        echo -n '[\[$COLOR_GREEN\]'"$screen"'\[$COLOR_DEFAULT\]'
        echo -n ':\[$COLOR_BLUE\]'"$name"'\[$COLOR_DEFAULT\]'
        echo -n ':\[$COLOR_PURPLE\]'"$window"'\[$COLOR_RESET\]]'
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
    local vcs
    local branch
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
        local prompt='\[$COLOR_GREEN\]'"$pchar"
    else
        local prompt='\[$COLOR_RED\]'"$pchar:$_LAST_RETURN_CODE"
    fi
    echo "$prompt"'\[$COLOR_RESET\] '
}

_prompt_text() {
    # control formatting of what you type. Formatting is reset in trap_debug.
    echo '\[$COLOR_BOLD\]'
}

_prompt_precmd() {
    # do nothing and allow this to be overridden in clients
    echo ''
}

_prompt_prefix() {
    echo "${PROMPT_PREFIX-⚡ }"
}

_prompt_filter() {
    local funcs="$1"
    if [[ $PROMPT_SHORT_DISPLAY ]]; then
        # if host is localhost, showing the host is unnecessary
        if [[ ! $(is_remote) ]]; then
            funcs=$(filter "$funcs" "at|host")
        fi

        # if the user is your login user, showing it is unnecessary
        if [[ ! $(is_su) && ! $(is_root) ]]; then
            funcs=$(filter "$funcs" "user")
        fi

        # if no user or host, remove sep too
        if [[ ! $(echo "$funcs" | egrep -w "user|host") ]]; then
            funcs=$(filter "$funcs" "sep")
        fi
    fi
    if [[ $PROMPT_SHORT_DISPLAY || $PROMPT_HIDE_DATE ]]; then
        # don't show the date on short mode or if explicitly hidden
        funcs=$(filter "$funcs" "date")
    fi
    echo "$funcs"
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
    local funcs="precmd prefix date user at host screen sep path repo jobs char text"

    # filter parts of the prompt
    funcs=$(_prompt_filter "$funcs")

    # construct ps1
    local ps1=''
    for f in $funcs; do
        ps1+="\$(_prompt_$f)"
    done

    # if provided no argument, set PS1 yourself, else echo it to be used elsewhere
    if [[ -z "$1" ]]; then
        eval "PS1=$ps1"
    else
        echo "$ps1"
    fi
}

# basic prompt
# export PS1="\u@\h:\w$ "

prompt_command_is_readonly() {
    readonly -p | awk -F' |=' '{print $3}' | fgrep -qx 'PROMPT_COMMAND'
}

register_prompt(){
    # work around the PROMPT_COMMAND being read-only. At least you'll get a basic prompt.
    if prompt_command_is_readonly; then
        echo "PROMPT_COMMAND is readonly"
        eval "PS1=$(generate_ps1 1)"
    else
        # prompt must run first or can't capture $?
        PROMPT_COMMAND="generate_ps1;$PROMPT_COMMAND"
    fi
}
