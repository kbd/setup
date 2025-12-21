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
bindkey "\e[H" beginning-of-line # home
bindkey "\e[F" end-of-line # end
bindkey "\e[3;3~" kill-word # ⌥del (kitty only, iterm ⌥del==del)
bindplugin "^[E" edit-command-line # ⌥E
.ECL() { VISUAL="$GIT_EDITOR" edit-command-line; }
bindplugin "^[e" .ECL # ⌥e

auto-expand() {
  if [[ $LBUFFER =~ ' [A-Z0-9]+$' ]]; then
    # auto-expand all-caps global aliases inline
    # http://blog.patshead.com/2012/11/automatically-expaning-zsh-global-aliases---simplified.html
    zle _expand_alias
    zle expand-word
  elif [[ $LBUFFER == 'jr' ]]; then
    # don't record journal entries in shell history
    LBUFFER=" jr"
  fi
  zle self-insert
}

zle -N auto-expand

bindkey " " auto-expand
bindkey "^ " magic-space           # control-space to bypass completion
bindkey -M isearch " " magic-space # normal space during searches
