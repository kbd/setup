# setup

My config, system settings, utilities, and so on, and tools for
syncing them between machines.

## Usage

To run, clone into `~/setup` (though location of the repository doesn't
matter), and run `~/setup/HOME/bin/setup`. It'll automatically rename any
existing files and create symlinks pointing to the repository.

## Bootstrap

You can bootstrap this onto a new system with:

```python -c "$(curl -fsSL https://raw.githubusercontent.com/kbd/setup/master/bootstrap.py)"```

## Editor settings

I use Visual Studio Code, which doesn't make it easy to source control your
editor settings without [an extension](https://github.com/shanalikhan/code-settings-sync).

Here's [the gist containing my editor settings](https://gist.github.com/kbd/9c099110598e09bf6ecb597d7b27f4bd).
