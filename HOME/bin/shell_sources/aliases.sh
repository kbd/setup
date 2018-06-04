#!/usr/bin/env bash

# VARS
if [[ -z "$PATH_SET" ]]; then
    export PATH="$HOME/bin:$HOME/bin/scripts:$PATH"
    export PATH_SET=1
fi
export PLATFORM=$(uname)
export PAGER=less
export LESS='-iM'  # smart-case searches and status bar
export EDITOR=vim
export SVN_EDITOR=vim
export GIT_EDITOR=vim
export PYTHONDONTWRITEBYTECODE=1
export ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern cursor)
export PIPENV_SHELL_FANCY=1
export ERL_AFLAGS="-kernel shell_history enabled"  # remember Elixir iex history across sessions
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export FZF_DEFAULT_COMMAND='fd -tf -HL'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_DEFAULT_OPTS="--ansi"
_fzf_compgen_path() { $FZF_DEFAULT_COMMAND "$1"; }
_fzf_compgen_dir() { fd -td -HL "$1"; }

# ALIASES
alias   -- -='cd -'
alias     ..='cd ..'
alias    ...='cd ../..'
alias   ....='cd ../../..'
alias  .....='cd ../../../..'
alias ......='cd ../../../../..'

alias l=ls
alias la='ls -a'
alias ll='ls -l'
alias lla='ls -la'

alias wcl='wc -l'
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
alias v='f -e vim'  # from https://github.com/clvv/fasd#examples
alias vi=vim
alias vless=vimpager
alias py=ipython
alias tcl='rlwrap tclsh'
alias curl='curl -L'  # follow redirects by default
alias s='git st'
alias goog='googler -n3 --np'

alias ercho='>&2 echo'  # echo to stderr
# "ps -p $$ -ocomm=" gives things like '-zsh', 'zsh', or '/usr/local/bin/zsh'
# so get the basename, then strip non-alphanumeric characters
alias last_command='fc -nl -1'
alias map='xargs -n1'  # splits on spaces
alias mapl='xargs -L1'  # map by line
alias history_unique="history | sed 's/.*\\] //' | sort | uniq"  # because bash's history is abominable

case $(current_shell) in
    zsh)
        alias history='history -i'  # always include timestamp
        alias hs='h 0 | rg'  # 'history search'

        # global aliases (zsh-only)
        alias -g FZF='$(!! | fzf)'
        alias -g L='| $PAGER'  # would be nice to map ↑ +this to ⌘l
    ;;
    bash)
        alias hs='h | rg'
    ;;
esac

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

    alias lock='/System/Library/CoreServices/"Menu Extras"/User.menu/Contents/Resources/CGSession -suspend'
else
    # gnu ls
    alias ls='ls -F --color'
    # '--' necessary to correctly handle filenames beginning with -
    # bsd ls handles this correctly by default and doesn't allow --
    # indicator-style=none so you don't get directories with // at the end
    alias lsd='ls -d --indicator-style=none -- */'
    alias lld='ll -d --indicator-style=none -- */'
fi
