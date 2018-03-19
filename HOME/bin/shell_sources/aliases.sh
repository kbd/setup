#!/usr/bin/env bash

# VARS
export PLATFORM=$(uname)
export PATH="$HOME/bin:$HOME/bin/scripts:$PATH"
export PAGER=less
export EDITOR=vim
export SVN_EDITOR=vim
export GIT_EDITOR=vim
export GIT_PS1_SHOWCOLORHINTS=1
export GIT_PS1_SHOWDIRTYSTATE=1
export GIT_PS1_SHOWSTASHSTATE=1
export GIT_PS1_SHOWUNTRACKEDFILES=1
export GIT_PS1_SHOWUPSTREAM='auto'
export PYTHONDONTWRITEBYTECODE=1

# ALIASES
alias   -- -='cd -'
alias     ..='cd ..'
alias    ...='cd ../..'
alias   ....='cd ../../..'
alias  .....='cd ../../../..'
alias ......='cd ../../../../..'

alias ls='ls -h'
alias l=ls
alias la='ls -a'
alias ll='ls -l'
alias lla='ls -la'

alias wcl='wc -l'
alias less='less -i'  # always do "smart"-case searches
alias du='du -h'
alias grep='grep --color=auto'
alias g=grep
alias h=history

alias edit=\$EDITOR "$@"
alias e=edit
alias e.='e .'
alias o=open
alias o.='o .'

alias pe=path-extractor
alias v=vim
alias vi=vim
alias py=ipython
alias tcl='rlwrap tclsh'
alias curl='curl -L'  # follow redirects by default

alias uc="tr '[:lower:]' '[:upper:]'"  # 'uppercase'
alias lc="tr '[:upper:]' '[:lower:]'"  # 'lowercase'

alias ercho='>&2 echo'  # echo to stderr
# "ps o command= $$" gives things like '-zsh' or '/usr/local/bin/zsh -l'
# so get the basename, then get the first 'word' remaining
alias fw='rg -o \\w+ | head -1'  # fw = 'first word'
alias current_shell='basename -- $(ps o command= $$) | fw'
alias last_command='fc -nl -1'
alias map='xargs -n1'  # splits on spaces
alias mapl='xargs -L1'  # map by line
alias history_unique="history | sed 's/.*\\] //' | sort | uniq"  # because bash's history is abominable

# GLOBAL ALIASES (Zsh)
alias -g FZF='$(!! | fzf)'

# PLATFORM SPECIFIC
if [[ $PLATFORM == 'Darwin' ]]; then
    export EDITOR='open -t'
    # PATH="/usr/local/opt/coreutils/libexec/gnubin:$PATH"
    # MANPATH="/usr/local/opt/coreutils/libexec/gnuman:$MANPATH"

    alias awk=gawk
    alias sed=gsed
    alias tar=gtar

    # bsd ls
    alias ls='ls -FG'
    # escape ls to ignore -F so you don't get directories with // at the end
    alias lsd='\ls -dG */'
    alias lld='\ls -hldG */'
else
    # gnu ls
    alias ls='ls -F --color'
    # '--' necessary to correctly handle filenames beginning with -
    # bsd ls handles this correctly by default and doesn't allow --
    # indicator-style=none so you don't get directories with // at the end
    alias lsd='ls -d --indicator-style=none -- */'
    alias lld='ll -d --indicator-style=none -- */'
fi
