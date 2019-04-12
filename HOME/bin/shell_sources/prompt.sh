#!/usr/bin/env bash
# configuration variables exposed:
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
#
# note: this code depends on colors.sh and funcs.sh already being loaded.
# they only happen to be becase c < f < p alphabetically, but ¯\_(ツ)_/¯
_prompt_date() {
    echo -n "$eo${COL[grey]}$dt$eo${COL[reset]}$ec:"
}

_prompt_user() {
    local color="$eo${COL[green]}$ec"
    if is_root; then
        color="$eo${COL[red]}$ec"
    elif is_su; then
        color="$eo${COL[yellow]}$ec$eo${COL[bold]}$ec"
    fi
    echo -n "$color$user$eo${COL[reset]}$ec"
}

_prompt_at() {
    # show the @ in red if not local
    local at='@'
    if is_remote; then
        at="$eo${COL[red]}$ec$eo${COL[bold]}$ec$at$eo${COL[reset]}$ec"
    fi
    echo -n "$at"
}

# a function so that it can do more logic later if desired
# such as showing the full host by default if you're not local
_prompt_show_full_host() { [[ -n "$PROMPT_FULL_HOST" ]]; }

_prompt_host() {
    local host
    _prompt_show_full_host && host=$full_host || host=$short_host
    echo -n "$eo${COL[blue]}$ec$host$eo${COL[reset]}$ec"
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
        echo -n "[$eo${COL[green]}$ec$screen$eo${COL[default]}$ec"
        echo -n ":$eo${COL[blue]}$ec$name$eo${COL[default]}$ec"
        echo -n ":$eo${COL[purple]}$ec$window$eo${COL[reset]}$ec]"
    fi
}

_prompt_sep() {
    # separator - red if cwd unwritable
    local sep=':';
    if [[ ! -w "${PWD}" ]]; then
        sep="$eo${COL[red]}$ec$eo${COL[bold]}$ec$sep$eo${COL[reset]}$ec"
    fi
    echo -n "$sep"
}

_prompt_path() {
    echo -n "$eo${COL[purple]}$ec$eo${COL[bold]}$ec$ppath$eo${COL[reset]}$ec"
}

# source control information in prompt
_prompt_repo() {
    if [[ -n "$SSHHOME" ]]; then
        # skip repo support over ssh(rc) because repo.py won't be able to run
        return 0
    fi
    local repostr="$(repo.py)"
    if [[ -n "$repostr" ]]; then
        echo -n "[$repostr]"
    fi
}

running_suspended() {
    jobs | perl -ne 'BEGIN{%c=qw(r 0 s 0)}$c{lc $1}++ if /^\[\d+\]\s*[+-]?\s*(\w)/i;END{print "@c{qw(r s)}"}'
}

# running and stopped jobs
_prompt_jobs() {
    # shellcheck disable=SC2046
    set -- $(running_suspended)
    local running=$1
    local stopped=$2

    local jobs=''
    if [[ $running -ne 0 ]]; then
        jobs="$eo${COL[green]}$ec$running&$eo${COL[reset]}$ec"  # '&' for 'background'
    fi

    if [[ $stopped -ne 0 ]]; then
        if [[ $jobs ]]; then
            jobs="$jobs:"  # separate running and stopped job count with a colon
        fi
        jobs="$jobs$eo${COL[red]}$ec${stopped}z$eo${COL[reset]}$ec"  # 'z' for 'ctrl+z' to stop
    fi

    if [[ $jobs ]]; then
        echo -n "[$jobs]"
    fi
}

_prompt_char() {
    # prompt char, with info about last return code
    # ercho "   Last return code is $_LAST_RETURN_CODE"
    if [[ $_LAST_RETURN_CODE -eq 0 ]]; then
        local prompt="$eo${COL[green]}$ec$pchar"
    else
        local prompt="$eo${COL[red]}$ec$pchar:$_LAST_RETURN_CODE"
    fi
    echo -n "$prompt$eo${COL[reset]}$ec "
}

_prompt_precmd() {
    # do nothing and allow this to be overridden in clients.
    # only useful in Bash, in Zsh use 'precmd'
    true
}

_prompt_pad_unicode_width() {
    # https://stackoverflow.com/a/7123564
    # $1 = string $2 = width
    echo -n "$eo$(tput sc)$ec$(rep ' ' $2)$eo$(tput rc)$1$ec"
}

_prompt_prefix() {
    local c="$(_prompt_pad_unicode_width $'\u26a1' 2)"  # lightning bolt, width of 2
    echo -n "${PROMPT_PREFIX-$c}"  # user-specified prefix, or default of $c
}

_prompt_script() {
    # report if the session is being recorded
    if [[ -n "$SCRIPT" ]]; then
        echo -n "$eo${COL[grey]}$ec{$SCRIPT}$eo${COL[reset]}$ec"
    fi
}

# virtual env
_prompt_venv() {
    # example environment variable set in a venv:
    # VIRTUAL_ENV=/Users/kbd/.local/share/virtualenvs/pipenvtest-vxNzUMMM
    if [[ -n "$VIRTUAL_ENV" ]]; then
        local venv_id=$(basename -- "$VIRTUAL_ENV")
        echo -n "[$venv_id]"
    fi
}

_prompt_filter() {
    local funcs="$1"
    if [[ $PROMPT_SHORT_DISPLAY ]]; then
        # showing the host (and user, if not su/root) is unnecessary if local
        if ! is_remote; then
            funcs=$(filter "$funcs" "at|host")

            if ! (is_su || is_root); then
                funcs=$(filter "$funcs" "user")
            fi
        fi

        # if no user or host, remove sep too
        if ! echo -n "$funcs" | grep -Eqw "user|host"; then
            funcs=$(filter "$funcs" "sep")
        fi
    fi
    if [[ $PROMPT_SHORT_DISPLAY || $PROMPT_HIDE_DATE ]]; then
        # don't show the date on short mode or if explicitly hidden
        funcs=$(filter "$funcs" "date")
    fi
    echo -n "$funcs"
}

generate_ps1() {
    _LAST_RETURN_CODE=$?
    local funcs="precmd prefix script venv date user at host screen sep path repo jobs char"
    for f in $(_prompt_filter "$funcs"); do
        "_prompt_$f"
    done
}

prompt_command_is_readonly() {
    readonly -p | awk -F' |=' '{print $3}' | grep -Fqx 'PROMPT_COMMAND'
}

prompt_initialize_vars() {
    dt='D{%m/%d@%H:%M}'
    _LAST_RETURN_CODE=0  # initialize
    case $(current_shell) in  # current_shell defined in funcs.sh
        bash)
            eo='\['  # 'escape open'
            ec='\]'  # 'escape close'
            dt="\\$dt"
            user='\u'
            full_host='\H'
            short_host='\h'
            ppath='\w'
            pchar='\$'
        ;;
        zsh)
            eo="%{"
            ec="%}"
            dt="%$dt"
            user='%n'
            full_host='%M'
            short_host='%m'
            ppath='%~'
            # pchar='%#'
            # http://zsh.sourceforge.net/Doc/Release/Prompt-Expansion.html#Shell-state
            pchar='%(!.#.$)'  # equivalent to bash's pchar
        ;;
    esac
}

register_prompt(){
    prompt_initialize_vars

    # work around the PROMPT_COMMAND being read-only and use basic prompt
    if prompt_command_is_readonly; then
        ercho "Prompt command is readonly"
        PS1="$user@$short_host:$ppath$ "
    else
        case $(current_shell) in
            bash)
                PROMPT_COMMAND='PS1="$(generate_ps1)"'
            ;;
            zsh)
                # shellcheck disable=SC2016 disable=SC2034
                # 2016 = unexpanded in single quotes = intended bc prompt_subst
                # 2034 = 'PROMPT unused'. Shellcheck doesn't support zsh.
                PROMPT='$(generate_ps1)'
            ;;
        esac
    fi
}

# http://www.faqs.org/docs/Linux-mini/Xterm-Title.html#s3
alias title='printf "\e]0;%s\a"'  # both window and tab
alias tabtitle='printf "\e]1;%s\a"'
alias wintitle='printf "\e]2;%s\a"'

# http://invisible-island.net/xterm/xterm.faq.html
# http://www.opensource.apple.com/source/X11apps/X11apps-30.1/xterm/xterm-251/ctlseqs.txt
# http://stackoverflow.com/questions/4471278/how-to-capture-the-title-of-a-terminal-window-in-bash-using-ansi-escape-sequence
# I think these only work on linux, can't test atm
alias getwintitle='printf "\e[21t"'
alias gettabtitle='printf "\e[20t"'
