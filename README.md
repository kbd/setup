# setup

My config, system settings, dotfiles, utilities, etc.

## Usage

To run, clone into `~/setup` (though location of the repository doesn't
matter), and run `~/setup/HOME/bin/setup`.

## Bootstrap

You can bootstrap this onto a new system with:

```python3 -c "$(curl -fsSL https://raw.githubusercontent.com/kbd/setup/master/bootstrap.py)"```

## Details

All "config" (what programs/libraries get installed, OS settings, etc.) go in
`conf/`, and everything in `HOME/` (dotfiles and so on) gets symlinked into
`$HOME`.

The `setup` program manages everything and reads `conf/settings.py` to know
what's possible to do.
