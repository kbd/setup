#!/usr/bin/env zsh
PROMPT='$(prompt zsh)'
RPROMPT='$([[ ! $PROMPT_BARE ]] && date +"%m/%d %H:%M:%S")'

alias pb='[[ $PROMPT_BARE ]] && unset PROMPT_BARE || export PROMPT_BARE=1'

export PROMPT_PREFIX='⚡'

alias title='printf "\e]0;%s\a"' # https://tldp.org/HOWTO/Xterm-Title-3.html#ss3.1
precmd() {
  export PROMPT_RETURN_CODE=$?
  export PROMPT_PATH="$(print -P '%~')"
  export PROMPT_JOBS=${(M)#${jobstates%%:*}:#running}\ ${(M)#${jobstates%%:*}:#suspended}
  export PROMPT_HR=$COLUMNS
  title "$PROMPT_PATH${TABTITLE:+" ($TABTITLE)"}"

  set-kitty-tab-color
}

rgba-to-rgb() {
  local c="${1#\#}"
  [[ ${#c} -ne 8 ]] && { echo "$1"; return; }
  local r=$((16#${c:0:2})) g=$((16#${c:2:2})) b=$((16#${c:4:2})) a=$((16#${c:6:2}))
  printf "#%02x%02x%02x" $((r*a/255)) $((g*a/255)) $((b*a/255))
}

set-kitty-tab-color() {
  [[ $TERM != xterm-kitty || $DIR_COLOR == $OLD_DIR_COLOR ]] && return
  local abg="${DIR_COLOR:-NONE}"
  local afg="${DIR_COLOR_FG:-NONE}"
  local ibg="$(rgba-to-rgb "${DIR_COLOR_INACTIVE:-$DIR_COLOR}")"
  local ifg="$(rgba-to-rgb "${DIR_COLOR_INACTIVE_FG:-$DIR_COLOR_FG}")"
  kitty @ set-tab-color --self active_bg=$abg inactive_bg=$ibg active_fg=$afg inactive_fg=$ifg
  OLD_DIR_COLOR=$DIR_COLOR
}

preexec(){
  title "$PROMPT_PATH ($1)"
  unset PROMPT_RETURN_CODE PROMPT_PATH PROMPT_JOBS PROMPT_HR
}

tt() { TABTITLE="$@"; }
ttl() { tt "⚡$@⚡"; }
