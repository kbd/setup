export ARCH="$(uname -p)"
# /usr/local/bin already in path on intel (and brew shellenv adds it again...)
brewpath="$([[ $ARCH == arm ]] && echo -n "/opt/homebrew/bin/"; echo "brew")"
eval "$($brewpath shellenv)"

# add my bin first and language-specific paths after
PATH="$HOME/bin:$HOME/bin/.venv/bin:$PATH:$HOME/.cargo/bin:$HOME/go/bin:$HOME/.local/bin:$HOME/.nimble/bin"

if [[ $ARCH == arm ]]; then
  # https://apple.stackexchange.com/questions/414622/installing-a-c-c-library-with-homebrew-on-m1-macs
  export LIBRARY_PATH=/opt/homebrew/lib
  export CPATH=/opt/homebrew/include
fi
