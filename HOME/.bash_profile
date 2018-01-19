#!/usr/bin/env bash
export HISTCONTROL='ignoreboth'
export HISTTIMEFORMAT="[%F %T %z] "
export HISTSIZE=100000

# SHOPTS
shopt -s histappend
shopt -s dotglob
shopt -s globstar
shopt -s autocd

# SOURCES
for file in "$HOME"/bin/shell_sources/**/*.sh; do source "$file"; done

# COMPLETIONS
source /usr/local/etc/bash_completion
complete -cf sudo  # allow autocompletions after sudo.

# configure prompt
export PROMPT_SHORT_DISPLAY=1

# register command prompt (prompt.sh)
register_prompt

# override prompt precmd (prompt.sh)
_prompt_precmd() {
    # append to history after each command. You can get other consoles'
    # histories with history -n, and a new console immediately has the history
    # you were just using, but each maintains its independence otherwise
    #
    # however, this is actually totally broken because history -a appends all
    # your history *since the start of your session*, not since the last time
    # you appended. So your history file quickly grows exponentially.
    # bash appears to have no sane history management.
    # I even tried this: https://unix.stackexchange.com/a/18443
    # finally my first reason to investigate zsh.
    history -a

    # set tab title to the current directory
    # http://tldp.org/HOWTO/Xterm-Title-4.html
    echo -n "\\[$(tabtitle '\w')\\]"
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
su_hacks # must be run after prompt is registered

# 3rd party software config
eval "$(thefuck --alias)"
eval "$(fasd --init auto)"
export FZF_DEFAULT_COMMAND='fd --type f --hidden'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
source "$HOME/.fzf.bash"

_source .config/machine_specific/.bash_profile  # machine-specific bash config, may not exist

prompt_ensure_save_return_code  # (prompt.sh)
