#!/usr/bin/env zsh
# use autocomplete on nothing
empty-tab() {
  if [[ $#BUFFER == 0 ]]; then
    BUFFER="br" # broot
    zle accept-line
  else
    zle expand-or-complete
  fi
}
zle -N empty-tab
bindkey '^I' empty-tab
