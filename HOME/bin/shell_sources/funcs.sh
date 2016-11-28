ipython_func() {
    # fix ipython to handle arguments like python
    # https://twitter.com/keithdevens/status/595294880533876736
    # this is an imperfect hack because you could do "-c 'command'" and have command
    # actually be a file in contrived cases, but this shouldn't cause problems normally
    # to show why this is necessary, use ipython -i python print_sysargv.py -i
    local version=$1
    shift
    local cmd="ipython$version"
    local new_args=("$@")

    local i=1
    local arg
    for arg in "$@"; do
        i=$((i+1))
        if [[ $arg != -* && -f $arg ]]; then
            # if arg doesn't start with a dash and the arg is a file
            # then consider this the script passed to ipython and
            # all args after this are args to the script
            new_args=("${@:0:$i}" "--" "${@:$i}")
            break
        fi
    done
    command $cmd "${new_args[@]}"
}

printv() {  # v for verbatim
    printf '%s\n' "$1"
}

# 'less' using vim
vless() {
    # http://vimdoc.sourceforge.net/htmldoc/starting.html#$VIMRUNTIME
    # http://vimdoc.sourceforge.net/htmldoc/various.html#less
    # maybe use https://github.com/rkitover/vimpager instead?
    local vimruntime=`vim -e -T dumb --cmd 'exe "set t_cm=\<C-M>"|echo $VIMRUNTIME|quit' | tr -d '\015' `
    local lessvim="$vimruntime/macros/less.vim"
    vim -u "$lessvim" "$@"
}

# mkdir + cd
mcd() {
    if [[ -z "$1" ]]; then
        ercho "missing argument"
        return 1
    fi
    mkdir -p "$1" && cd "$1";
}

# cd + ls
cl() {
    cd "$1" && ls "${@:2}"
}

# download
dl() {
    local url="$(cb)"  # get from clipboard
    echo "${COLOR_BOLD}${COLOR_BLUE}Downloading: ${COLOR_YELLOW}$url${COLOR_RESET}"
    youtube-dl "$@" "$url"
}

# get the homedir of another user. Be careful cause of eval.
# http://stackoverflow.com/a/20506895
user_home() {
    eval echo "~$1"
}

my_home() {
    user_home $(logname)
}
