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

# completion
autoload -Uz compinit
compinit
zstyle ':completion:*' menu select

# auto-expand global aliases (that are all-caps) inline
# http://blog.patshead.com/2012/11/automatically-expaning-zsh-global-aliases---simplified.html
globalias() {
   if [[ $LBUFFER =~ ' [A-Z0-9]+$' ]]; then
     zle _expand_alias
     zle expand-word
   fi
   zle self-insert
}

zle -N globalias

bindkey " " globalias
bindkey "^ " magic-space           # control-space to bypass completion
bindkey -M isearch " " magic-space # normal space during searches

# key binds (zsh doesn't use readline/inputrc)
bindkey '\e[A' history-search-backward
bindkey '\e[B' history-search-forward
# todo: port over more from inputrc

# initialize path. based on /etc/profile, not run by zsh
if [ -x /usr/libexec/path_helper ]; then
    eval "$(/usr/libexec/path_helper -s)"
fi

# load shell sources
for file in "$HOME"/bin/shell_sources/**/*.sh; do source "$file"; done

# nuke default zshrc because it fails and always starts the shell with an error
if [[ $PLATFORM == 'Darwin' && -f /etc/zshrc ]]; then
  ercho "/etc/zshrc exists but is useless on Mac, moving to /etc/zshrc.backup"
  sudo mv /etc/zshrc /etc/zshrc.backup
fi

# 1st party software config
export PROMPT_SHORT_DISPLAY=1
register_prompt

# 3rd party software config
eval "$(thefuck --alias)"
eval "$(fasd --init auto)"
export FZF_DEFAULT_COMMAND='fd --type f --hidden'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
source "$HOME/.fzf.zsh"

precmd() {
    prompt_save_return_code
    tabtitle "$PWD"
    vcs_info
}
