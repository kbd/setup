from pathlib import Path

SETTINGS_PATH = 'conf/settings.py'
PARTIALS_PATH = 'conf/partials.txt'
HOME_DIR = 'HOME'


def load_config(path=SETTINGS_PATH):
    settings = eval(open(path).read())
    return settings


def root():
    """Return the path of the root of this setup repository."""
    # this file is under HOME_DIR. HOME_DIR's parent is the root.
    # So search backwards for HOME_DIR and get its parent.
    path = Path(__file__).resolve()  # resolve symlinks (~/bin=setup/HOME/bin)
    return path.parents[path.parts[::-1].index(HOME_DIR)]


def home():
    return root() / HOME_DIR


def home_path(path):
    """Get the path within setup's HOME for the given path

    Note: no valid setup path for anything outside of $HOME, so throws exception
    """
    return home() / Path(path).resolve().relative_to(Path.home())
