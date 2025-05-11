#!/usr/bin/env zsh
# use autocomplete on nothing
TABATPROMPT="${TABATPROMPT:-br}" # broot
empty-tab() {
  if [[ -z $BUFFER ]]; then
    BUFFER="$TABATPROMPT"
    zle accept-line
  else
    zle expand-or-complete
  fi
}
zle -N empty-tab
bindkey '^I' empty-tab
