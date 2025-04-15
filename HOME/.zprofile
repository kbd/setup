# cache brew shellenv
[[ -f "$BREW_SHELLENV_PATH" ]] || {
   # /usr/local/bin already in path on intel
   # https://docs.brew.sh/FAQ#why-is-the-default-installation-prefix-opthomebrew-on-apple-silicon
   # https://docs.brew.sh/Tips-N'-Tricks#loading-homebrew-from-the-same-dotfiles-on-different-operating-systems
   p="$([[ "$(uname -p)" == arm ]] && echo /opt/homebrew/bin/)"
   "${p}brew" shellenv > "$BREW_SHELLENV_PATH"
}
source "$BREW_SHELLENV_PATH"

# add my bin first and language-specific paths after
PATH="$HOME/bin:$HOME/bin/.venv/bin:$PATH:$HOME/.local/bin:$HOME/.cargo/bin:$HOME/go/bin"

# https://apple.stackexchange.com/questions/414622/installing-a-c-c-library-with-homebrew-on-m1-macs
export LIBRARY_PATH=/opt/homebrew/lib
export CPATH=/opt/homebrew/include
