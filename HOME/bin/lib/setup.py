from pathlib import Path

SETTINGS_PATH = 'conf/settings.py'


def load_config(path=SETTINGS_PATH):
    settings = eval(open(path).read())
    return settings


def root():
    # this program lives in $repo/HOME/bin/lib, so $repo/HOME/bin/../../.. will
    # get the root of the repository. Use resolve() to resolve symlink since
    # $repo/HOME/bin is symlinked to ~/bin.
    return Path(__file__).resolve().parents[3]


def home():
    return root() / 'HOME'


def home_path(path):
    """Get the path within setup's HOME for the given path

    Note: no valid setup path for anything outside of $HOME, so throws exception
    """
    return home() / Path(path).resolve().relative_to(Path.home())
