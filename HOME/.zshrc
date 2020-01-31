#!/usr/bin/env zsh
# options
setopt auto_cd
setopt auto_pushd
setopt pushd_ignore_dups
setopt pushd_minus
setopt pushd_silent
setopt prompt_subst  # execute the contents of PROMPT
setopt sh_word_split  # "open -t" is two words

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

# remove error-causing zsh completion
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
eval "$(thefuck --alias)"
eval "$(fasd --init auto)"
unalias a s sd sf d f zz 2>/dev/null # unalias all fasd aliases but 'z'
# pyenv is badly behaved and will repeatedly add itself to the path on initialization
[[ "$PYENV_SHELL" ]] || eval "$(pyenv init -)"
source "$HOME/.config/fzf/fzf.zsh"

# source after 3rd party config so you can override (eg. aliases) if needed
for file in "$HOME"/bin/shell/**/*.(z|)sh; do
  source "$file";
done

# 1st party software config
export PROMPT_SHORT_DISPLAY=1
register_prompt
TERMS_WITH_BROKEN_UNICODE=('vscode')
# https://unix.stackexchange.com/a/411307
if [[ ${TERMS_WITH_BROKEN_UNICODE[(ie)$TERM_PROGRAM]} -le ${#TERMS_WITH_BROKEN_UNICODE} ]]; then
  PROMPT_PREFIX=''
fi

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

# syntax highlighting needs to be sourced last
source `brew --prefix`/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
