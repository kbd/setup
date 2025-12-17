# cache brew shellenv
[[ -f "$BREW_SHELLENV_PATH" ]] || /opt/homebrew/bin/brew shellenv > "$BREW_SHELLENV_PATH"
source "$BREW_SHELLENV_PATH"

# add my bin first and language-specific paths after
PATH="$HOME/bin:$HOME/bin/.venv/bin:$PATH:$HOME/.local/bin:$HOME/.cargo/bin:$HOME/go/bin:$HOME/.bun/bin"

# https://apple.stackexchange.com/questions/414622/installing-a-c-c-library-with-homebrew-on-m1-macs
export LIBRARY_PATH=/opt/homebrew/lib
export CPATH=/opt/homebrew/include
