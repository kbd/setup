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
# ls colors I expect: exe=red, dir=blue, symlink=pink, pipe=yellow
export LS_COLORS="ex=31:di=34:ln=35:pi=33"

# ALIASES
alias   -- -="cd -"
alias     ..="cd .."
alias    ...="cd ../.."
alias   ....="cd ../../.."
alias  .....="cd ../../../.."
alias ......="cd ../../../../.."

alias ls="ls -h"
alias l=ls
alias la="ls -a"
alias ll="ls -l"
alias lla="ls -la"

alias edit=\$EDITOR "$@"
alias e=edit
alias e.="e ."

alias o=open
alias o.="o ."

alias grep="grep --color=auto"
alias g=grep

alias h=history

alias du="du -h"

alias v=vim
alias vi=vim

alias py=ipython

alias tcl="rlwrap tclsh"

# PLATFORM SPECIFIC
if [[ $PLATFORM == 'Darwin' ]]; then
    export EDITOR='open -t'
    alias subl='open -a "Sublime Text"'
    # PATH="/usr/local/opt/coreutils/libexec/gnubin:$PATH"
    # MANPATH="/usr/local/opt/coreutils/libexec/gnuman:$MANPATH"

    alias awk=gawk
    alias sed=gsed
    alias tar=gtar

    # bsd ls
    alias ls="ls -FG"
    # escape ls to ignore -F so you don't get directories with // at the end
    alias lsd="\\ls -dG */"
    alias lld="\\ls -hldG */"
else
    # gnu ls
    alias ls="ls -F --color"
    # '--' necessary to correctly handle filenames beginning with -
    # bsd ls handles this correctly by default and doesn't allow --
    # indicator-style=none so you don't get directories with // at the end
    alias lsd="ls -d --indicator-style=none -- */"
    alias lld="ll -d --indicator-style=none -- */"
fi
