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
export HISTFILE="$HOME/.history"

# load LS_COLORS. Needs to precede zsh completion so it can use the same colors.
eval $(gdircolors -b $HOME/.LS_COLORS) # gdircolors is dircolors in coreutils

# completion
autoload -Uz compinit
zmodload zsh/complist
compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
bindkey -M menuselect '\e[Z' reverse-menu-complete # shift tab to go backwards

# turn off bad Zsh defaults
compdef -d mcd # conflicts with my alias: https://github.com/zsh-users/zsh/blob/master/Completion/Unix/Command/_mtools
ZLE_REMOVE_SUFFIX_CHARS='' # https://superuser.com/a/613817/
WORDCHARS=${WORDCHARS/\/} # don't consider slash a word char - https://stackoverflow.com/questions/444951/

# key binds
stty -ixon # allow C-s and C-q to be used for things (see .vimrc)

bindplugin() {
  # usage: bindplugin "\e[A" up-line-or-beginning-search
  autoload -Uz "$2"
  zle -N "$2"
  bindkey "$1" "$2"
}

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
TMPSUFFIX='.zsh' # for syntax highlighting

# 3rd party config
eval "$(direnv hook zsh)"
eval "$(zoxide init zsh)"
[[ ! "$PATH" == */usr/local/opt/fzf/bin* ]] && source "$HOME/.config/fzf/fzf.zsh"

# fzf-tab
zstyle ':completion:*:descriptions' format '[%d]' # enable group support
zstyle ':fzf-tab:*' switch-group ',' '.'
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'exa -1 --color=always $realpath'
# fzf-tab misbehaves if zsh config is reloaded; guard against repeated source
[[ "$FZF_TAB_HOME" ]] || source ~/setup/3rdparty/fzf-tab/fzf-tab.plugin.zsh

# source after 3rd party config so you can override (eg. aliases) if needed
for file in "$HOME"/bin/shell/**/*.(z|)sh; do
  source "$file";
done

# 1st party config
PROMPT='$(prompt zsh)'
RPROMPT='$([[ ! $PROMPT_BARE ]] && echo $(date +"%m/%d %H:%M:%S"))'
export PROMPT_PREFIX='⚡'

kitty_chpwd(){
  kitty @ set-tab-color --self \
    active_fg=${KITTY_TAB_AFG:-NONE} \
    active_bg=${KITTY_TAB_ABG:-NONE} \
    inactive_fg=${KITTY_TAB_IFG:-NONE} \
    inactive_bg=${KITTY_TAB_IBG:-NONE}
}
if [[ ${chpwd_functions[(Ie)kitty_chpwd]} == 0 ]] && is_kitty &&
  exists kitty-tab-color; then
  chpwd_functions+=(kitty_chpwd)
fi
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

# zsh syntax highlighting
# https://github.com/zsh-users/zsh-syntax-highlighting/blob/master/docs/highlighters.md#how-to-activate-highlighters
export ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern cursor)
# https://github.com/zsh-users/zsh-syntax-highlighting/blob/master/docs/highlighters/main.md
typeset -A ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[comment]='fg=green,standout'
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=magenta,bold'
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=magenta,bold,bg=black'

# machine-specific config
[[ -f ~/.config/.machine/.zshrc ]] && source ~/.config/.machine/.zshrc

# source zsh plugins. syntax highlighting must be sourced last.
brew_share="$(brew --prefix)/share"
source "$brew_share/zsh-autosuggestions/zsh-autosuggestions.zsh"
source "$brew_share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
