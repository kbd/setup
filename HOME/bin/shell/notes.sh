#!/usr/bin/env bash
alias today="gdate +%Y-%m-%d"
alias yesterday="today -d-1day"
alias tomorrow="today -d+1day"
alias date-full="ts -f"
alias tss="gdate +'%a %b %d %Y %H:%M:%S'" # Tue Sep 02 2025 15:53:09
alias typora="/Applications/Typora.app/Contents/MacOS/Typora"
export NOTES_DIR=~/notes

note-tmpl() {
  "$NOTES_DIR/templates/${1:-_}.sh" "${@:2}"
}

note-daily() {
  local dt="${1:-$(today)}"
  note "$(note-daily-file "$dt")" "$(note-tmpl daily "$(date-full "$dt")")";
}

dear() {
  local dt="${1:-$(kpd)}"
  [[ "$dt" ]] && note-daily "$dt"
}

note-daily-file() {
  note-file "diary/${1:-$(today)}"
}

note-file() {
  local f="${1%.md}.md"
  is-absolute "$f" || f="$NOTES_DIR/$f"
  echo "$f"
}

note-create() {
  local name="${1%.md}"
  local f="$(note-file "$name")"
  [[ -f "$f" ]] || echo "${2:-$(note-tmpl _ "$name")}" > "$f"
  echo "$f"
}

note() {
  [[ -z "$1" ]] && exec a Typora $NOTES_DIR
  a Typora "$(note-create "$@")"
}

mdf () {
  glow | less -R
}

note-tasks() {
  kmd @- "$(note-daily-file "$1")" "${@:2}" --tags --color=always | mdf
}

jr() {
  kmd -i 'journal | append*({})' "<u>$(ts -t)</u> $*" -- "$(note-daily-file)"
}
alias jr='noglob jr'

ta() {
  kmd -i 'tasks | prepend({})' "$*" -- "$(note-daily-file)"
}
alias ta='noglob ta'

# date pickers
alias pd='pickdate --format=yyyy-mm-dd'
kpd() {
  local tmp=$(mktemp)
  local ret=$(kitty @ launch --wait-for-child-to-exit --copy-env sh -c "pickdate --format=yyyy-mm-dd > $tmp")
  if [[ $ret -ne 0 ]]; then
    rm "$tmp"
    return $ret
  fi
  cat "$tmp" && rm "$tmp"
}

if [[ $ZSH_VERSION ]]; then
  compdef '_files -W "$NOTES_DIR" -g "**/*.md~*(Library|diary|templates)/**/*.md"' note
  compdef "_files -W \"$NOTES_DIR/diary/\"" note-daily
  zstyle ':fzf-tab:complete:note:*' fzf-preview 'CLICOLOR_FORCE=1 glow --style=dark "$NOTES_DIR/$realpath"'
  zstyle ':fzf-tab:complete:note-daily:*' fzf-preview 'CLICOLOR_FORCE=1 glow --style=dark "$NOTES_DIR/diary/$realpath"'
  zstyle ':completion:*:note-daily:*' sort false # fzf-tab respect provided order
  zstyle ':completion:*:note-daily:*' file-sort reverse
fi
