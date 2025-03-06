#!/usr/bin/env bash
alias today="gdate '+%Y-%m-%d'"
alias yesterday="gdate -d '-1day' '+%Y-%m-%d'"
alias tomorrow="gdate -d '+1day' '+%Y-%m-%d'"
alias date-full="ts -f"
alias tss="gdate +'%a %b %d %Y %H:%M:%S'"
alias daily=note-daily
alias dear=diary
alias diary=daily
export NOTES_DIR=~/notes
note-tmpl() {
  "$NOTES_DIR/templates/${1:-_}".sh "${@:2}"
}
note-daily() {
  local dt="${1:-$(today)}"
  note "diary/$dt" "$(note-tmpl daily "$(date-full "$dt")")";
}
note() {
  if [[ -z "$1" ]]; then
    a Typora $NOTES_DIR
  else
    local name="${1%.md}"
    local f="$name.md"
    if ! is-absolute "$f"; then
      f="$NOTES_DIR/$f"
    fi
    if [[ ! -f "$f" ]]; then
      echo "${2:-$(note-tmpl _ "$name")}" > "$f"
    fi
    a Typora "$f"
  fi
}
if [[ $ZSH_VERSION ]]; then
  compdef "_files -W \"$NOTES_DIR/\"" note
  compdef "_files -W \"$NOTES_DIR/diary/\"" note-daily
  zstyle ':fzf-tab:complete:note:*' fzf-preview 'CLICOLOR_FORCE=1 glow --style=dark "$NOTES_DIR/$realpath"'
  zstyle ':fzf-tab:complete:note-daily:*' fzf-preview 'CLICOLOR_FORCE=1 glow --style=dark "$NOTES_DIR/diary/$realpath"'
  zstyle ':completion:*:note-daily:*' sort false # fzf-tab respect provided order
  zstyle ':completion:*:note-daily:*' file-sort reverse
fi
