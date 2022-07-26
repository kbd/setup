export ARCH="$(uname -p)"
# /usr/local/bin already in path on intel (and brew shellenv adds it again...)
brewpath="$([[ $ARCH == arm ]] && echo -n "/opt/homebrew/bin/"; echo "brew")"
eval "$($brewpath shellenv)"

# add my bin first and language-specific paths after
PATH="$HOME/bin:$PATH:$HOME/.cargo/bin:$HOME/go/bin:$HOME/.local/bin:$HOME/.nimble/bin"
