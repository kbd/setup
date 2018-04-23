#!/usr/bin/env bash
# shopts
shopt -s histappend
shopt -s dotglob
shopt -s globstar
shopt -s autocd
shopt -s expand_aliases

#history
export HISTCONTROL='ignoreboth'
export HISTTIMEFORMAT="[%F %T %z] "
export HISTSIZE=100000

if [[ -n "$SSHHOME" ]]; then  # if ssh'd using sshrc
    SOURCE_DIR="$SSHHOME/.sshrc.d/sources/"
    SELF="$SSHHOME/.sshrc"

    export PATH="$SSHHOME/.sshrc.d/bin:$PATH"

    # bind my keyboard shortcuts
    bind -f "$SSHHOME/.sshrc.d/.inputrc"
else
    SOURCE_DIR="$HOME/bin/shell_sources/"
    SELF="$HOME/.bashrc"

    # COMPLETIONS
    source /usr/local/etc/bash_completion
    complete -cf sudo  # allow autocompletions after sudo

    # 3rd party software config (only local)
    eval "$(thefuck --alias)"
    export FZF_DEFAULT_COMMAND='fd --type f --hidden'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    source "$HOME/.fzf.bash"
fi

# 3rd party software config
eval "$(fasd --init auto)"

# SOURCES
for file in "$SOURCE_DIR"/**/*.sh; do
    source "$file";
done

# configure prompt
export PROMPT_SHORT_DISPLAY=1

# register command prompt (prompt.sh)
register_prompt

# source my bashrc even when su-ing, derived from http://superuser.com/a/636475
# note: doesn't work if user you su to has PROMPT_COMMAND set. Not sure of workaround
# must be run after 'register_prompt'
# shellcheck disable=SC2139
alias su="export PROMPT_COMMAND='source $SELF; $PROMPT_COMMAND' && su -p"
# shellcheck disable=SC2139
alias sudosu="export PROMPT_COMMAND='source $SELF; $PROMPT_COMMAND' && sudo -E su"

# override prompt precmd (prompt.sh)
_prompt_precmd() {
    # set tab title to the current directory
    # http://tldp.org/HOWTO/Xterm-Title-4.html
    echo -n "$eo$(tabtitle '\w')$ec"
}

prompt_ensure_save_return_code  # (prompt.sh)
