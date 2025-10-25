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

  set-tab-color
}

set-dir-colors(){
  local keys=(titleBar.{active,inactive}{Background,Foreground})
  local q='."workbench.colorCustomizations"["'"${(j:", ":)keys}"'"] | . // ""'
  DIR_COLOR=("${(@f)$(jq -r <"$1" "$q")}")
}

rgba-to-rgb() {
  local c="${1#\#}"
  [[ ${#c} -ne 8 ]] && { echo "$1"; return; }
  local r=$((16#${c:0:2})) g=$((16#${c:2:2})) b=$((16#${c:4:2})) a=$((16#${c:6:2}))
  printf "#%02x%02x%02x" $((r*a/255)) $((g*a/255)) $((b*a/255))
}

set-tab-color() {
  [[ $TERM != xterm-kitty || $VSCODE_SETTINGS == $OLD_VSCODE_SETTINGS ]] && return
  [[ $VSCODE_SETTINGS ]] && set-dir-colors "$VSCODE_SETTINGS" || unset DIR_COLOR
  local k=({active,inactive}_{bg,fg}) args=() i
  for i in {1..$#k}; do args+="$k[i]=${$(rgba-to-rgb "${DIR_COLOR[i]}"):-NONE}"; done
  kitty @ set-tab-color --self "${args[@]}"
  OLD_VSCODE_SETTINGS=$VSCODE_SETTINGS
}

preexec(){
  title "$PROMPT_PATH ($1)"
  unset PROMPT_RETURN_CODE PROMPT_PATH PROMPT_JOBS PROMPT_HR
}

tt() { TABTITLE="$@"; }
ttl() { tt "⚡$@⚡"; }
