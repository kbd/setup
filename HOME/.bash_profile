#!/usr/bin/env bash
export PLATFORM=$(uname)
export PATH="$HOME/bin:$PATH"
export EDITOR=vi
export SVN_EDITOR=vi
export GIT_EDITOR=vi
export GIT_PS1_SHOWCOLORHINTS=1
export GIT_PS1_SHOWDIRTYSTATE=1
export GIT_PS1_SHOWSTASHSTATE=1
export GIT_PS1_SHOWUNTRACKEDFILES=1
export GIT_PS1_SHOWUPSTREAM='auto'
export _Z_NO_RESOLVE_SYMLINKS=1
export VERTICAINI=/etc/vertica.ini
# ls colors I expect: exe=red, dir=blue, symlink=pink, pipe=yellow
export LS_COLORS="ex=31"  # set executables to red (gnu ls)
export HISTCONTROL='ignoredups'  # I'd prefer to ignore dups on autocomplete instead of eliminating
                                 # them from history, but that seems not possible
export HISTTIMEFORMAT="[%F %T %z] "

# configure prompt
export PROMPT_SHORT_DISPLAY=1

# SHOPTS
shopt -s histappend
shopt -s dotglob
shopt -s globstar 2>/dev/null  # not supported in bash 3
shopt -s autocd 2>/dev/null  # not supported in bash 3

# ALIASES
alias   -- -="cd -"
alias     ..="cd .."
alias    ...="cd ../.."
alias   ....="cd ../../.."
alias  .....="cd ../../../.."
alias ......="cd ../../../../.."

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

alias v=vim
alias vi=vim

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

# ipython_func is in funcs.sh
alias ipython="ipython_func '' --no-banner --no-confirm-exit"
alias ipython3="ipython_func 3 --no-banner --no-confirm-exit"

# PLATFORM SPECIFIC
if [[ $PLATFORM == 'Darwin' ]]; then
    export EDITOR='open -t'
    alias subl='open -a "Sublime Text"'

    # bsd ls
    alias ls="ls -FG"
    # escape ls to ignore -F so you don't get directories with // at the end
    alias lsd="\ls -dG */"
    alias lld="\ls -ldG */"
else
    # gnu ls
    alias ls="ls -F --color"
    # '--' necessary to correctly handle filenames beginning with -
    # bsd ls handles this correctly by default and doesn't allow --
    # indicator-style=none so you don't get directories with // at the end
    alias lsd="ls -d --indicator-style=none -- */"
    alias lld="ll -d --indicator-style=none -- */"
fi

# FUNCTIONS
# source a file or a directory of files
_source() {
    if [[ -d "$1" ]]; then
        # if it's a directory, source everything in the directory
        local file
        for file in "$1"/*; do
            source "$file" 2>/dev/null
        done
    elif [[ -f "$1" ]]; then
        # else source the file if it exists
        source "$1" 2>/dev/null
    fi
}

# SOURCES
_source "$HOME/bin/shell_sources"

# bind my keyboard shortcuts even when su-d
if [[ $USER != "$(logname)" ]]; then
    bind -f "$(my_home)/.inputrc"
fi

# source my bash_profile even when su-ing, derived from http://superuser.com/a/636475
# note: doesn't work if user you su to has PROMPT_COMMAND set. Not sure of workaround
alias su="export PROMPT_COMMAND='source $(my_home)/.bash_profile; $PROMPT_COMMAND' && su"

# COMPLETIONS
_source /usr/local/etc/bash_completion.d
complete -cf sudo  # allow autocompletions after sudo.

# 3rd party software config
eval "$(thefuck --alias)"
eval "$(fasd --init auto)"

# machine-specific bash config
_source .config/machine_specific/.bash_profile
