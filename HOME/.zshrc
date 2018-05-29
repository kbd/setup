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

# LS_COLORS
# ls colors needs to be early because it apparently needs to precede complist
# ls colors I expect: exe=red, dir=blue, symlink=pink, pipe=yellow
export LS_COLORS='ex=31:di=34:ln=35:pi=33'
# todo: update .LS_COLORS with my preferences and see what you'd lose in BSD ls
# by switching to GNU ls (which respects LS_COLORS). IIRC GNU ls doesnt't show
# Mac extended attributes on files.
if type gdircolors &>/dev/null; then  # gdircolors is dircolors in coreutils
    eval $(gdircolors -b $HOME/.LS_COLORS)
fi

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

# key binds
stty -ixon  # allow C-s and C-q to be used for things (see .vimrc)

bindplugin() {
    # usage: bindplugin "\e[A" up-line-or-beginning-search
    autoload -Uz "$2"
    zle -N "$2"
    bindkey "$1" "$2"
}

# up/down-line-or-beginning-search is equivalent to bash's history-search-backward/forward.
# Zsh's functions of the same name leave you at the beginning of the line instead of the end.
bindplugin "\e[A" up-line-or-beginning-search
bindplugin "\e[B" down-line-or-beginning-search

# option/alt + <- / ->
# still can't get ctrl+arrow keys working
# should I use bash-backward/forward-word here?
bindkey "\e\e[C" forward-word
bindkey "\e\e[D" backward-word

# make the home and end keys do the right thing
# bindkey "\e[H": beginning-of-line
# bindkey "\e[F": end-of-line

# 3rd party software config
eval "$(thefuck --alias)"
eval "$(fasd --init auto)"
export FZF_DEFAULT_COMMAND='fd -tf -tl --hidden --color=always'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_DEFAULT_OPTS="--ansi"
_fzf_compgen_path() { eval $FZF_DEFAULT_COMMAND "$1"; }
_fzf_compgen_dir() { fd --type d --hidden --follow --color=always "$1"; }
source "$HOME/.fzf.zsh"

# source after 3rd party config so you can override (eg. aliases) if needed
for file in "$HOME"/bin/shell_sources/**/*.(z|)sh; do
    source "$file";
done

# 1st party software config
export PROMPT_SHORT_DISPLAY=1
register_prompt

precmd() {
    prompt_save_return_code
    tabtitle "$PWD"
}

# syntax highlighting needs to be sourced last
source `brew --prefix`/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
