#!/usr/bin/env bash
# shellcheck disable=SC2139
export XDG_CONFIG_HOME=~/.config
export LANG=en_US.UTF-8
export OS="$(uname)"

# homebrew
export HOMEBREW_NO_AUTO_UPDATE=1
export HOMEBREW_NO_INSTALL_CLEANUP=1
export HOMEBREW_NO_INSTALLED_DEPENDENTS_CHECK=1

# fzf
export FZF_DEFAULT_COMMAND='fd -tf -HL'
export FZF_DEFAULT_OPTS='--height 30% --reverse --multi --bind=ctrl-r:toggle-sort'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd -td -HL'
export FZF_ALT_C_OPTS="--preview 'tree -C {} | head -200'"
_fzf_compgen_path() { fd -tf -HL . "$1"; }
_fzf_compgen_dir() { fd -td -HL . "$1"; }

# PLATFORM SPECIFIC
if [[ $OS == Darwin ]]; then
  # prefer GNU versions of common utils
  alias awk=gawk
  alias sed=gsed
  alias tar=gtar
  LS_PATH="$HOMEBREW_PREFIX/bin/gls"

  alias lock='pmset displaysleepnow'
  alias locks='pmset sleepnow' # locks = "lock+sleep". 'sleep' is a unix command

  alias switch-output="SwitchAudioSource -a -t output | f ' (' 0 | fzf | xargs -I% SwitchAudioSource -t output -s '%'"
  alias switch-input="SwitchAudioSource -a -t input | f ' (' 0 | fzf | xargs -I% SwitchAudioSource -t input -s '%'"
fi

# SHELL SPECIFIC
if [[ $ZSH_VERSION ]]; then
  # global aliases
  alias -g L='| $PAGER'
  alias -g H='| head'
  alias -g C='| grcat log'

  # suffix aliases
  alias -s txt='$EDITOR'
  alias -s md='a Typora'

  alias rlh='fc -R && echo history reloaded'
fi

# TERMINAL SPECIFIC
alias is-kitty='[[ $TERM == xterm-kitty ]]'
if is-kitty; then
  alias icat="kitten icat --align=left"
  alias notify="kitten notify"
fi

# find/pag{ers,ing}/editors
export PAGER=less
export LESS='-iMFx4 --mouse --incsearch --exit-follow-on-close' # smart-case, status bar, quit 1 screen, 4sp tabs
export LESSEDIT='code -ng %f:%l'
export EDITOR=hx
export VISUAL='code -nw'
export GIT_EDITOR='kitty-launch-and-wait "$EDITOR"'
export JJ_EDITOR="kitty-launch-and-wait $EDITOR" # jj won't expand $EDITOR so capture at definition time
export IGREP_EDITOR=code
export DELTA_PAGER="less $LESS -R"
export JQ_COLORS='4;36:0;37:0;37:0;37:0;32:1;37:1;37'
export RIPGREP_CONFIG_PATH=$XDG_CONFIG_HOME/ripgrep/rc
export GREP_COLORS='ms=01;32:ln=34:fn=33' # bold green matches, blue line numbers, yellow filenames. Match ripgrep.
alias http='autopager http --pretty=all'
alias https='autopager https --pretty=all'
alias jq='autopager jq -C'
alias curl='autopager curl "" -L'
alias curlie='autopager curlie --pretty -L'
alias xh='autopager xh --pretty=all'
alias yq='autopager yq -C'
alias gh='PAGER= gh' # use gh default pager; gh needs 'less -R' for colors
alias glab='PAGER= glab' # ...

# edit/open
alias edit='$EDITOR'
alias e=edit
alias E='code'
alias e.='e .'
alias E.='E .'
alias e-='e' # edit from stdin
alias E-='E -' # edit from stdin
alias eg='e' # edit (go to line)
alias Eg='E -g' # edit (go to line)
alias o=open
alias o.='o .'
alias a='o -a'
alias x='chmod +x'
alias c='bat --style=header,numbers'
te(){ t "$@" && e "$@"; }
tE(){ EDITOR="code" te "$@"; }
tex(){ te "$@" && x "$@"; }
tEx(){ EDITOR="code" tex "$@"; }
ze(){ z "$@" && e .; } # z to dir then edit
zE(){ EDITOR="code" ze "$@"; }

# directory/navigation
alias   -- -='cd -'
alias  -- --='cd -2'
alias -- ---='cd -3'
alias     ..='cd ..'
alias    ...='cd ../..'
alias   ....='cd ../../..'
alias  .....='cd ../../../..'
alias ......='cd ../../../../..'
alias ls="${LS_PATH:-ls} -F --color=auto --group-directories-first --hyperlink"
alias l=ls
alias la='ls -A'
alias lt='ls -t'
alias ll='ls -lh'
alias lla='ll -A'
alias llt='ll -t'
alias llat='ll -At'
lsd() { ls -d --indicator-style=none "$@" -- */; }
lld() { ll -d --indicator-style=none "$@" -- */; }
cl() { cd -- "${1-$HOME}" && l "${@:2}"; }
cll() { cd -- "${1-$HOME}" && ll "${@:2}"; }
et() { eza -alT --git --git-ignore --color=always "$@" | less -R; }
alias et1='et -L1'
alias et2='et -L2'
alias et3='et -L3'
mcd() {
  # mkdir + cd
  [[ -z "$1" ]] && echo >&2 "missing argument" && return 1
  mkdir -p -- "$1" && cl "$@" -A
}

# git
alias g=git
alias s='gs' # status
alias d='gd' # diff
alias p='gpg' # pull and show graph of recent changes
alias g-='gco -' # switch to most recent branch (can't alias '-' directly in git)
# alias short git aliases
for a in $(git alias 2>/dev/null | grep -E '^.{0,4}$'); do
  alias "g$a=g $a"
done
# use fuzzy-find versions of these aliases
for a in a b br; do
  alias "g$a=g${a}f"
done
gccb() {
  # check out a repository from the url in the clipboard and cd into it
  local url="$(cb)"
  local dir="${1:-$(basename "$url" .git)}"
  git clone -- "$url" "$dir" && cd "$dir" || return
}

# python
export PTPYTHON_CONFIG_HOME=$XDG_CONFIG_HOME/ptpython  # defaults to ~/Library/Application Support/... on Mac
export PYTHONBREAKPOINT=pudb.set_trace
export PYTHONDONTWRITEBYTECODE=1
export VIRTUAL_ENV_DISABLE_PROMPT=1
alias da='django-admin'
alias dm='python3 manage.py' # "django manage"
alias ds='dm shell_plus --ptpython'
alias py='pyt'
alias pyb='bpython'
alias pyc='python3 -c'
alias pyi='ptipython'
alias pym='PYTHONSTARTUP=~/bin/pythonstartup.py py'
alias pyt='ptpython'
alias pytest-d='pytest --pdb --pdbcls=pudb.debugger:Debugger'

# shortcuts/defaults/config
export ERL_AFLAGS="-kernel shell_history enabled" # remember Elixir iex history across sessions
export DENO_INSTALL_ROOT="$HOME/.local"
alias 1p='eval $(op signin)'
alias battery='pmset -g batt'
alias cbf='fzf | teerr | cb'
alias dp='cd "$(dirs -pl | tail -n+2 | fzf)"'
alias dtrx='dtrx --one=inside'
alias du='du -h'
alias dud='du -d0 .'
alias emoji='uni emoji all | fzf | f 0 | trim | cb'
alias ercho='>&2 echo' # echo to stderr
alias exists='type &>/dev/null' # check if a program exists
alias fennel='rlwrap fennel'
alias fm='yazi'
alias fu='fd -uu' # fd, but don't ignore any files
alias grep='grep --color=auto'
alias hex='hexyl'
alias histogram='sort | uniq -c | sort -nr'
alias hj=hjson-cli
alias hjj='hjson-cli -j'
alias ieX='iex -S mix'
alias is-docker='[[ -f "/.dockerenv" ]]'
alias is-local='! is-not-local'
alias is-not-local='is-remote || is-docker'
alias is-remote='[[ $SSH_TTY || $SSH_CLIENT ]]'
alias is-root='[[ $EUID == 0 ]]'
alias is-su='[[ $(whoami) != $(logname) ]]' # if current user != login user
is-absolute(){ [[ "$1" == /* ]]; }
alias j=just
alias janet='rlwrap -Na janet' # just for repl history
alias jax='osascript -l JavaScript -e'
alias jaxi='rlwrap --always-readline --no-children osascript -il JavaScript'
alias jj='LESS="$LESS -R" jj'
alias k=note-tasks
alias map='parallel'
alias my_home='user_home "$(logname)"'
alias ncdu='ncdu --color=dark'
alias node="env NODE_NO_READLINE=1 rlwrap node"
alias printv='printf "%q\n"' # v for verbatim
alias qalc='noglob qalc'
alias q=qalc
alias ssh='sshrc' # always sshrc
alias rgh='rg --no-heading'
alias tcl='rlwrap tclsh'
alias title='printf "\e]0;%s\a"' # https://tldp.org/HOWTO/Xterm-Title-3.html#ss3.1
alias title-tab='printf "\e]1;%s\a"'
alias title-win='printf "\e]2;%s\a"'
alias ug='ug --smart-case'
alias uq='ug -Q --no-confirm -e'
user_home() { eval echo "~$1"; } # http://stackoverflow.com/a/20506895
alias wcl='wc -l'
alias S='~S' # too often I miss the ~ when I ~S. Make it work anyway.
alias ,='~S'
alias zj=zellij
alias zja='zj ls | fzf -0 -1 --ansi --bind "enter:become(echo {1})" | xargs -to zellij a'

create() {
  # since scripts can't cd, need a function to cd after 'create-' scripts
  [[ -z "$1" || -z "$2" ]] && echo >&2 "type and project name required" && return 1
  local cmd="create-$1"
  local project="$2"
  shift 2
  ! exists "$cmd" && echo >&2 "'$cmd' doesn't exist" && return 2
  $cmd "$project" "$@" && cd "$project" || return 3
}
