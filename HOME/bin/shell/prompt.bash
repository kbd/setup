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
# $PROMPT_BARE
#   set to enable a very minimal prompt, useful for copying exmaples
#

# http://linuxcommand.org/lc3_adv_tput.php
# http://unix.stackexchange.com/questions/269077/tput-setaf-color-table-how-to-determine-color-codes
# http://misc.flogisoft.com/bash/tip_colors_and_formatting
# https://en.wikipedia.org/wiki/ANSI_escape_code
typeset -A COL  # declare associative array, works both in bash and zsh
export COL

COL[reset]="$(tput sgr0)"
COL[bold]="$(tput bold)"
COL[dim]="$(tput dim)"
COL[uline]="$(tput smul)"
COL[no_uline]="$(tput rmul)"
COL[blink]="$(tput blink)"

COL[black]="$(tput setaf 0)"
COL[red]="$(tput setaf 1)"
COL[green]="$(tput setaf 2)"
COL[yellow]="$(tput setaf 3)"
COL[blue]="$(tput setaf 4)"
COL[magenta]="$(tput setaf 5)"
COL[cyan]="$(tput setaf 6)"
COL[white]="$(tput setaf 7)"
# setaf 9 is wrong on mac, but right in screen and tmux ¯\_(ツ)_/¯
COL[default]="$(tput setaf 9)"

COL[b_black]="$(tput setab 0)"
COL[b_red]="$(tput setab 1)"
COL[b_green]="$(tput setab 2)"
COL[b_yellow]="$(tput setab 3)"
COL[b_blue]="$(tput setab 4)"
COL[b_magenta]="$(tput setab 5)"
COL[b_cyan]="$(tput setab 6)"
COL[b_white]="$(tput setab 7)"
# see comment for setaf 9
COL[b_default]="$(tput setab 9)"

filter() {
  echo "$1" | tr ' ' '\n' | grep -Ewv "$2" | tr '\n' ' '
}

_prompt_date() {
  echo -n "$eo${COL[white]}$ec$dt$eo${COL[reset]}$ec:"
}

_prompt_user() {
  local color="${COL[green]}"
  if is-root; then
    color="${COL[red]}"
  elif is-su; then
    color="${COL[yellow]}${COL[bold]}"
  fi
  echo -n "$eo$color$ec$user$eo${COL[reset]}$ec"
}

_prompt_at() {
  # show the @ in red if not local
  local at='@'
  if is-remote; then
    at="$eo${COL[red]}${COL[bold]}$ec$at$eo${COL[reset]}$ec"
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

# tab - https://github.com/austinjones/tab-rs
_prompt_tab() {
  if [[ -n "$TAB" ]]; then
    echo -n "[$TAB]"
  fi
}

# screen/tmux status in prompt
_prompt_screen() {
  if [[ $TERM == screen* ]]; then
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
    echo -n "[$eo${COL[green]}$ec$screen$eo${COL[reset]}$ec"
    echo -n ":$eo${COL[blue]}$ec$name$eo${COL[reset]}$ec"
    echo -n ":$eo${COL[magenta]}$ec$window$eo${COL[reset]}$ec]"
  fi
}

_prompt_sep() {
  # separator - red if cwd unwritable
  local sep=':';
  if [[ ! -w "${PWD}" ]]; then
    sep="$eo${COL[red]}${COL[bold]}$ec$sep$eo${COL[reset]}$ec"
  fi
  echo -n "$sep"
}

_prompt_path() {
  echo -n "$eo${COL[magenta]}${COL[bold]}$ec$ppath$eo${COL[reset]}$ec"
}

# source control information in prompt
_prompt_repo() {
  if is-not-local; then
    # skip repo support because repo_status won't be able to run
    return 0
  fi
  local repostr="$(repo_status)"
  if [[ -n "$repostr" ]]; then
    echo -n "[$repostr]"
  fi
}

running_suspended() {
  jobs | PERL_SKIP_LOCALE_INIT=1 perl -ne 'BEGIN{%c=qw(r 0 s 0)}$c{lc $1}++ if /^\[\d+\]\s*[+-]?\s*(\w)/i;END{print "@c{qw(r s)}"}'
}

# running and stopped jobs
_prompt_jobs() {
  read -r running stopped <<<"$(running_suspended)"

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

_prompt_prefix() {
  echo -n "${PROMPT_PREFIX-⚡}"
}

_prompt_script() {
  # report if the session is being recorded
  if [[ -n "$SCRIPT" ]]; then
    echo -n "$eo${COL[white]}$ec{$SCRIPT}$eo${COL[reset]}$ec"
  fi
}

# virtual env
_prompt_venv() {
  # example environment variable set in a venv:
  # VIRTUAL_ENV=/Users/kbd/.local/share/virtualenvs/pipenvtest-vxNzUMMM
  if [[ -n "$VIRTUAL_ENV" ]]; then
    local venv_id=$(basename -- "$VIRTUAL_ENV")
    echo -n "[$eo${COL[green]}$ec🐍$venv_id$eo${COL[reset]}$ec]"
  fi
}

_prompt_direnv() {
  if [[ -n "$DIRENV_DIR" ]]; then
    echo -n "$eo${COL[blue]}$ec‡$eo${COL[reset]}$ec"
  fi
}

_prompt_filter() {
  local funcs="$1"
  if [[ $PROMPT_SHORT_DISPLAY ]]; then
    # showing the host (and user, if not su/root) is unnecessary if local
    if is-local; then
      funcs=$(filter "$funcs" "at|host")

      if ! (is-su || is-root); then
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
  if [[ $PROMPT_BARE ]]; then
    funcs=$(filter "$funcs" "prefix|script|venv|user|at|host|screen|sep|path|repo|jobs|direnv|tab")
  fi
  echo -n "$funcs"
}

generate_ps1() {
  _LAST_RETURN_CODE=$?
  local funcs="precmd prefix script tab screen venv date user at host sep path repo jobs direnv char"
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
  case $1 in
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
  prompt_initialize_vars "$1"

  case $1 in
    bash)
      # work around the PROMPT_COMMAND being read-only and use basic prompt
      if prompt_command_is_readonly; then
        echo >&2 "Prompt command is readonly"
        PS1="$user@$short_host:$ppath$ "
      else
        PROMPT_COMMAND='PS1="$(generate_ps1)"'
      fi
    ;;
    zsh)
      # shellcheck disable=SC2016 disable=SC2034
      # 2016 = unexpanded in single quotes = intended bc prompt_subst
      # 2034 = 'PROMPT unused'. Shellcheck doesn't support zsh.
      PROMPT='$(generate_ps1)'
    ;;
  esac
}
