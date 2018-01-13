#!/usr/bin/env bash
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
export HISTCONTROL='ignoredups'
export HISTTIMEFORMAT="[%F %T %z] "
export HISTSIZE=100000
export HISTIGNORE=" *"

# configure prompt
export PROMPT_SHORT_DISPLAY=1

# SHOPTS
shopt -s histappend
shopt -s dotglob
shopt -s globstar
shopt -s autocd

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

alias grep="grep -E --color=auto"
alias fgrep="grep -F"
alias g=grep

alias h=history

alias du="du -h"

alias v=vim
alias vi=vim

alias py=ipython

alias tcl="rlwrap tclsh"

alias ercho='>&2 echo'  # echo to stderr

# http://www.faqs.org/docs/Linux-mini/Xterm-Title.html#s3
alias title='printf "\e]0;%s\a"'
alias tabtitle='printf "\e]1;%s\a"'
alias wintitle='printf "\e]2;%s\a"'

# http://invisible-island.net/xterm/xterm.faq.html
# http://www.opensource.apple.com/source/X11apps/X11apps-30.1/xterm/xterm-251/ctlseqs.txt
# http://stackoverflow.com/questions/4471278/how-to-capture-the-title-of-a-terminal-window-in-bash-using-ansi-escape-sequence
# I think these only work on linux, can't test atm
alias getwintitle='printf "\e[21t"'
alias gettabtitle='printf "\e[20t"'

# FUNCTIONS
# source a file or a directory of files
_source() {
    if [[ -d "$1" ]]; then
        # if it's a directory, source everything in the directory, recursively
        local file
        for file in "$1"/**/*.sh; do  # requires bash 4 and shopt -s globstar
            source "$file" 2>/dev/null
        done
    elif [[ -f "$1" ]]; then
        # If it's a file, source it
        source "$1" 2>/dev/null
    fi
}

su_hacks(){
    # source my bash_profile even when su-ing, derived from http://superuser.com/a/636475
    # note: doesn't work if user you su to has PROMPT_COMMAND set. Not sure of workaround
    alias su="export PROMPT_COMMAND='source $(my_home)/.bash_profile; $PROMPT_COMMAND' && su"

    # bind my keyboard shortcuts even when su-d
    if [[ $USER != "$(logname)" ]]; then
        bind -f "$(my_home)/.inputrc"
    fi
}

# COMPLETIONS
_source /usr/local/etc/bash_completion
complete -cf sudo  # allow autocompletions after sudo.

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
    alias lsd="\ls -dG */"
    alias lld="\ls -hldG */"
else
    # gnu ls
    alias ls="ls -F --color"
    # '--' necessary to correctly handle filenames beginning with -
    # bsd ls handles this correctly by default and doesn't allow --
    # indicator-style=none so you don't get directories with // at the end
    alias lsd="ls -d --indicator-style=none -- */"
    alias lld="ll -d --indicator-style=none -- */"
fi

# 3rd party software config
eval "$(thefuck --alias)"
eval "$(fasd --init auto)"
export FZF_DEFAULT_COMMAND='fd --type f --hidden'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
source ~/.fzf.bash

# SOURCES
_source "$HOME/bin/shell_sources"

# override prompt precmd (see prompt.sh)
_prompt_precmd() {
    # append to history after each command. You can get other consoles'
    # histories with history -n, and a new console immediately has the history
    # you were just using, but each maintains its independence otherwise
    history -a

    # set tab title to the current directory
    # http://tldp.org/HOWTO/Xterm-Title-4.html
    echo "\[$(tabtitle '\w')\]"
}

# register command prompt (prompt.sh)
register_prompt

# must be run after prompt is registered
su_hacks

# machine-specific bash config
_source .config/machine_specific/.bash_profile
