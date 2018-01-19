#!/usr/bin/env bash
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
    echo -n "\\[$COLOR_GREY\\]\\D{%m/%d@%H:%M}\\[$COLOR_RESET\\]:"
}

_prompt_user() {
    local color="\\[$COLOR_GREEN\\]"
    if is_root; then
        color="\\[$COLOR_RED\\]"
    elif is_su; then
        color="\\[$COLOR_YELLOW\\]\\[$COLOR_BOLD\\]"
    fi
    echo -n "$color\\u\\[$COLOR_RESET\\]"
}

_prompt_at() {
    # show the @ in red if not local
    local at='@'
    if is_remote; then
        at="\\[$COLOR_RED\\]\\[$COLOR_BOLD\\]$at\\[$COLOR_RESET\\]"
    fi
    echo -n "$at"
}

# a function so that it can do more logic later if desired
# such as showing the full host by default if you're not local
_prompt_show_full_host() { [[ -n "$PROMPT_FULL_HOST" ]]; }

_prompt_host() {
    local host
    _prompt_show_full_host && host='\H' || host='\h'
    echo -n "\\[$COLOR_BLUE\\]$host\\[$COLOR_RESET\\]"
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
        echo -n "[\\[$COLOR_GREEN\\]$screen\\[$COLOR_DEFAULT\\]"
        echo -n ":\\[$COLOR_BLUE\\]$name\\[$COLOR_DEFAULT\\]"
        echo -n ":\\[$COLOR_PURPLE\\]$window\\[$COLOR_RESET\\]]"
    fi
}

_prompt_sep() {
    # separator - red if cwd unwritable
    local sep=':';
    if [[ ! -w "${PWD}" ]]; then
        sep="\\[$COLOR_RED\\]\\[$COLOR_BOLD\\]$sep\\[$COLOR_RESET\\]"
    fi
    echo -n "$sep"
}

_prompt_path() {
    echo -n "\\[$COLOR_PURPLE\\]\\[$COLOR_BOLD\\]\\w\\[$COLOR_RESET\\]"
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
            vcs="\\[$COLOR_CYAN\\]$vcs\\[$COLOR_RESET\\]:\\[$COLOR_YELLOW\\]$branch\\[$COLOR_RESET\\]"
        fi
        echo -n "[$vcs]"
    fi
}

# running and stopped jobs
_prompt_jobs() {
    local running=$(( $(jobs -rp | wc -l) ))  # convert to numeric
    local stopped=$(( $(jobs -sp | wc -l) ))  # convert to numeric

    local jobs=''
    if [[ $running -ne 0 ]]; then
        jobs="\\[$COLOR_GREEN\\]$running&\\[$COLOR_RESET\\]"  # '&' for 'background'
    fi

    if [[ $stopped -ne 0 ]]; then
        if [[ $jobs ]]; then
            jobs="$jobs:"  # separate running and stopped job count with a colon
        fi
        jobs="$jobs\\[$COLOR_RED\\]${stopped}z\\[$COLOR_RESET\\]"  # 'z' for 'ctrl+z' to stop
    fi

    if [[ $jobs ]]; then
        echo -n "[$jobs]"
    fi
}

_prompt_char() {
    # prompt char, with info about last return code
    local pchar='\\$'
    if [[ $_LAST_RETURN_CODE -eq 0 ]]; then
        local prompt="\\[$COLOR_GREEN\\]$pchar"
    else
        local prompt="\\[$COLOR_RED\\]$pchar:$_LAST_RETURN_CODE"
    fi
    echo -n "$prompt\\[$COLOR_RESET\\] "
}

_prompt_precmd() {
    # do nothing and allow this to be overridden in clients
    true
}

_prompt_prefix() {
    echo -n "${PROMPT_PREFIX-⚡ }"
}

_prompt_filter() {
    local funcs="$1"
    if [[ $PROMPT_SHORT_DISPLAY ]]; then
        # if host is localhost, showing the host is unnecessary
        if ! is_remote; then
            funcs=$(filter "$funcs" "at|host")
        fi

        # if the user is your login user (except root), showing it is unnecessary
        if [[ ! ($(is_su) || $(is_root)) ]]; then
            funcs=$(filter "$funcs" "user")
        fi

        # if no user or host, remove sep too
        if ! echo "$funcs" | grep -Eqw "user|host"; then
            funcs=$(filter "$funcs" "sep")
        fi
    fi
    if [[ $PROMPT_SHORT_DISPLAY || $PROMPT_HIDE_DATE ]]; then
        # don't show the date on short mode or if explicitly hidden
        funcs=$(filter "$funcs" "date")
    fi
    echo "$funcs"
}

prompt_ensure_save_return_code() {
    # run this after all PROMPT_COMMAND modifications have been run to ensure
    # the previous retun code is recorded and can be displayed in the prompt
    PROMPT_COMMAND='export _LAST_RETURN_CODE=$?;'"$PROMPT_COMMAND";
}

generate_ps1() {
    local funcs="precmd prefix date user at host screen sep path repo jobs char"
    for f in $(_prompt_filter "$funcs"); do
        "_prompt_$f"
    done
}

prompt_command_is_readonly() {
    readonly -p | awk -F' |=' '{print $3}' | grep -Fqx 'PROMPT_COMMAND'
}

register_prompt(){
    # work around the PROMPT_COMMAND being read-only and use basic prompt
    if prompt_command_is_readonly; then
        ercho "PROMPT_COMMAND is readonly"
        PS1='\u@\h:\w$ '
    else
        PROMPT_COMMAND='PS1=$(generate_ps1)'
    fi
}

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
