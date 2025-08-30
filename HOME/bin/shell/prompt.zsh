#!/usr/bin/env zsh
PROMPT='$(prompt zsh)'
RPROMPT='$([[ ! $PROMPT_BARE ]] && echo $(date +"%m/%d %H:%M:%S"))'

alias pb='[[ $PROMPT_BARE ]] && unset PROMPT_BARE || export PROMPT_BARE=1'

export PROMPT_PREFIX='⚡'

alias title='printf "\e]0;%s\a"' # https://tldp.org/HOWTO/Xterm-Title-3.html#ss3.1
precmd() {
  export PROMPT_RETURN_CODE=$?
  export PROMPT_PATH="$(print -P '%~')"
  export PROMPT_JOBS=${(M)#${jobstates%%:*}:#running}\ ${(M)#${jobstates%%:*}:#suspended}
  export PROMPT_HR=$COLUMNS
  title "$PROMPT_PATH${TABTITLE:+" ($TABTITLE)"}"

  set_kitty_tab_color
}

set_kitty_tab_color() {
  [[ $TERM != xterm-kitty || $DIR_COLOR == $OLD_DIR_COLOR ]] && return

  local active_fg inactive_fg
  if [[ "$DIR_COLOR" ]]; then
    active_fg=$(pastel textcolor "$DIR_COLOR" | pastel format hex)
    inactive_fg="#333"; [[ "$active_fg" != "#000000" ]] && inactive_fg="#ccc"
  fi

  kitty @ set-tab-color --self \
    active_bg="${DIR_COLOR:-NONE}" inactive_bg="${DIR_COLOR:-NONE}" \
    active_fg="${active_fg:-NONE}" inactive_fg="${inactive_fg:-NONE}"

  OLD_DIR_COLOR=$DIR_COLOR
}

preexec(){
  title "$PROMPT_PATH ($1)"
  unset PROMPT_RETURN_CODE PROMPT_PATH PROMPT_JOBS PROMPT_HR
}

tt() { TABTITLE="$@"; }
ttl() { tt "⚡$@⚡"; }
