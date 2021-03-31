#!/usr/bin/env bash
# shopts
shopt -s histappend
shopt -s dotglob
shopt -s globstar
shopt -s autocd
shopt -s expand_aliases

# history
export HISTCONTROL='ignoreboth'
export HISTTIMEFORMAT="[%F %T %z] "
export HISTSIZE=100000
export HISTFILE=~/.bash_history

# key binds
stty -ixon  # allow C-s and C-q to be used for things (see .vimrc)

if ! declare -f is_remote > /dev/null; then
  # source files if running locally, otherwise everything is sourced in a bundle
  for file in "$HOME/bin/shell"/**/*.{sh,bash}; do
    source "$file"
  done
else
  unalias cat  # locally aliased to bat
fi

if is_remote; then
  # unicode character prompt prefix works fine locally but
  # always seems to cause problems on servers, so disable it
  export PROMPT_PREFIX=''
fi

# configure prompt
export PROMPT_SHORT_DISPLAY=1

# register command prompt (prompt.sh)
register_prompt bash

# source my bashrc even when su-ing, derived from http://superuser.com/a/636475
# note: doesn't work if user you su to has PROMPT_COMMAND set. Not sure of workaround
# must be run after 'register_prompt'
# shellcheck disable=SC2139
alias su="export PROMPT_COMMAND='source $SELF; $PROMPT_COMMAND' && su -p"
# shellcheck disable=SC2139
alias sudosu="export PROMPT_COMMAND='source $SELF; $PROMPT_COMMAND' && sudo -E su"

# override prompt precmd (prompt.sh)
_prompt_precmd() {
  echo -n "$eo$(title '\w')$ec"
}
