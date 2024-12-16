#!/usr/bin/env zsh
# options
setopt prompt_subst # execute the contents of PROMPT
setopt interactive_comments # allow a comment after a command
unsetopt beep # don't beep at me

# directories - http://zsh.sourceforge.net/Intro/intro_6.html
setopt auto_cd # cd to the directory by executing its name
setopt auto_pushd # automatically pushd when cd-ing
setopt pushd_silent # don't print out 'dirs' after pushd
setopt pushd_ignore_dups
setopt pushd_minus # sensible direction for cd using the dir stack
setopt pushd_to_home # pushd with no args behaves like cd with no args

# history
setopt extended_history
setopt hist_ignore_dups
setopt hist_find_no_dups
setopt hist_ignore_space
setopt inc_append_history_time
export HISTSIZE=50000
export SAVEHIST=$HISTSIZE

# https://zsh.sourceforge.io/Doc/Release/Parameters.html
TMPSUFFIX='.zsh' # for syntax highlighting
TIMEFMT=$'user\t%*Us\nsys\t%*Ss\nreal\t%*Es\ncpu/mem\t%P/%Mk\nfaults\t%F'
ZLE_REMOVE_SUFFIX_CHARS='' # https://superuser.com/a/613817/
WORDCHARS=${WORDCHARS/\/} # don't consider slash a word char - https://stackoverflow.com/questions/444951/

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

# prompt
PROMPT='$(prompt zsh)'
RPROMPT='$([[ ! $PROMPT_BARE ]] && echo $(date +"%m/%d %H:%M:%S"))'
export PROMPT_PREFIX='⚡'
alias title='printf "\e]0;%s\a"' # https://tldp.org/HOWTO/Xterm-Title-3.html#ss3.1
precmd() {
  export PROMPT_RETURN_CODE=$?
  export PROMPT_PATH="$(print -P '%~')"
  export PROMPT_JOBS=${(M)#${jobstates%%:*}:#running}\ ${(M)#${jobstates%%:*}:#suspended}
  export PROMPT_HR=$COLUMNS
  title "$PROMPT_PATH${TABTITLE:+" ($TABTITLE)"}"
}
preexec(){
  title "$PROMPT_PATH ($1)"
  unset PROMPT_RETURN_CODE PROMPT_PATH PROMPT_JOBS
}
tt() { TABTITLE="$@"; }
ttl() { tt "⚡$@⚡"; }

# completion
autoload -Uz compinit && compinit
compdef -d mcd # conflicts with my alias: https://github.com/zsh-users/zsh/blob/master/Completion/Unix/Command/_mtools

# ls colors, fzf-tab https://github.com/Aloxaf/fzf-tab?tab=readme-ov-file#configure
eval $(gdircolors -b $HOME/.LS_COLORS) # gdircolors is dircolors in coreutils
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' insert-tab false
zstyle ':completion:*:descriptions' format '[%d]' # enable group support
zstyle ':fzf-tab:*' switch-group ',' '.'
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
zstyle ':fzf-tab:*' fzf-flags '--preview-window=70%'

# zsh syntax highlighting
export ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern cursor) # https://github.com/zsh-users/zsh-syntax-highlighting/blob/master/docs/highlighters.md#how-to-activate-highlighters
typeset -A ZSH_HIGHLIGHT_STYLES=( # https://github.com/zsh-users/zsh-syntax-highlighting/blob/master/docs/highlighters/main.md
  [comment]='fg=green,standout'
  [double-quoted-argument]='fg=magenta,bold'
  [single-quoted-argument]='fg=magenta,bold,bg=black'
)

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

# source all shell config (aliases, 3rd party plugins, etc.)
for file in "$HOME"/bin/shell/**/*.(z|)sh; do
  source "$file";
done
