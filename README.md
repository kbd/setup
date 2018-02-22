# setup

My config, system settings, utilities, and so on, and tools for
syncing them between machines.

## Usage

To run, clone into `~/setup` (though location of the repository doesn't
matter), and run `~/setup/HOME/bin/setup`. It'll automatically rename any
existing files and create symlinks pointing to the repository.

## Bootstrap

You can bootstrap this onto a new system with:

```python -c "$(curl -s https://raw.githubusercontent.com/kbd/setup/master/bootstrap.py)"```
