# setup

My config, system settings, dotfiles, utilities, etc.

## Bootstrap

[Bootstrap](bootstrap.py) this onto a new system with:

```python3 -c "$(curl -fsSL https://raw.githubusercontent.com/kbd/setup/main/bootstrap.py)"```

That clones into `~/setup`, installs and runs [Homebrew](https://brew.sh/) to install core software, and then runs [setup](HOME/bin/setup) to install other packages and create symlinks.

## Details

All "config" (what programs/libraries get installed, OS settings, etc.) go in
`conf/`, and everything in `HOME/` (dotfiles and so on) gets symlinked into
`$HOME`.
