#!/usr/bin/env zsh
# options
setopt auto_cd # cd to the directory by executing its name
setopt prompt_subst # execute the contents of PROMPT

# directory stacks
# http://zsh.sourceforge.net/Intro/intro_6.html
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

# this behavior of zsh is annoying: https://superuser.com/a/613817/
ZLE_REMOVE_SUFFIX_CHARS=''

# load LS_COLORS. Needs to precede zsh completion so it can use the same colors.
eval $(gdircolors -b $HOME/.LS_COLORS) # gdircolors is dircolors in coreutils

# completion
autoload -Uz compinit
zmodload zsh/complist
compinit

# remove zsh completion that conflicts with my alias
# https://github.com/zsh-users/zsh/blob/master/Completion/Unix/Command/_mtools
compdef -d mcd

zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
bindkey -M menuselect '\e[Z' reverse-menu-complete  # menuselect from complist

# key binds
stty -ixon # allow C-s and C-q to be used for things (see .vimrc)

bindplugin() {
  # usage: bindplugin "\e[A" up-line-or-beginning-search
  autoload -Uz "$2"
  zle -N "$2"
  bindkey "$1" "$2"
}

# Zsh's built-in ↑ and ↓ leave you at the start of the line instead of the end
bindplugin "\e[A" up-line-or-beginning-search # ↑ (bash:history-search-backward)
bindplugin "\e[B" down-line-or-beginning-search # ↓ (bash:history-search-forward)
bindkey "\e[1;5D" backward-word # ⌃←
bindkey "\e[1;5C" forward-word # ⌃→
bindkey "\e\e[D" backward-word # ⌥←
bindkey "\e\e[C" forward-word # ⌥→
bindkey "\e[H" beginning-of-line # home
bindkey "\e[F" end-of-line # end
bindkey "\e[3~" delete-char # delete

# 3rd party software config
eval "$(direnv hook zsh)"
eval "$(thefuck --alias)"
eval "$(zoxide init zsh)"
# pyenv is badly behaved and will repeatedly add itself to the path on initialization
[[ "$PYENV_SHELL" ]] || eval "$(pyenv init -)"
source "$HOME/.config/fzf/fzf.zsh"

# source after 3rd party config so you can override (eg. aliases) if needed
for file in "$HOME"/bin/shell/**/*.(z|)sh; do
  source "$file";
done

# 1st party software config
zigprompt() {
  export PROMPT_RETURN_CODE=$?
  export PROMPT_JOBS=${(M)#${jobstates%%:*}:#running} ${(M)#${jobstates%%:*}:#suspended}
  export PROMPT_PATH="$(print -P '%~')"
  prompt
}
PROMPT='$(zigprompt)'

precmd() {
  local s="$TABTITLE"
  if [[ "$s" ]]; then s=" — $s"; fi
  tabtitle "$(print -P '%~')$s";
}
tt() { TABTITLE="$@"; }
ttl() { TABTITLE="⚡$@⚡"; }

# hashed directories
hash -d P=~/proj
hash -d S=~/setup
hash -d H=~S/HOME

# machine-specific config
[[ -f ~/.config/.machine/.zshrc ]] && source ~/.config/.machine/.zshrc

# source zsh plugins. syntax highlighting must be sourced last.
brew_share="$(brew --prefix)/share"
source "$brew_share/zsh-autosuggestions/zsh-autosuggestions.zsh"
source "$brew_share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
