#!/usr/bin/env zsh
bindplugin() {
  # usage: bindplugin "\e[A" up-line-or-beginning-search
  autoload -Uz "$2"
  zle -N "$2"
  bindkey "$1" "$2"
}

# keybinds
stty -ixon # allow C-s and C-q to be used for things (see .vimrc)
bindkey "\e[A" history-beginning-search-backward # ↑
bindkey "\e[B" history-beginning-search-forward # ↓
bindkey "\e[1;5D" backward-word # ⌃←
bindkey "\e[1;5C" forward-word # ⌃→
bindkey "\e[1;3D" backward-word # ⌥← kitty
bindkey "\e[1;3C" forward-word # ⌥→
bindkey "\eb" backward-word # ⌥← vscode
bindkey "\ef" forward-word # ⌥→
bindkey "\e[H" beginning-of-line # home
bindkey "\e[F" end-of-line # end
bindkey "\e[3~" delete-char # delete
bindkey "\e[3;3~" kill-word # ⌥del (kitty only, iterm ⌥del==del)
bindplugin "^[e" edit-command-line # ⌥e
