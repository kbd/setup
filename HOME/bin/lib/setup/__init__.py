from pathlib import Path

SETTINGS_PATH = 'conf/settings.py'
PARTIALS_PATH = 'conf/partials.txt'
HOME_DIR = 'HOME'


def load_config(path=SETTINGS_PATH):
    settings = eval(open(path).read())
    return settings


def root():
    # this file is under HOME_DIR, which is directly under the repo root
    path = Path(__file__).resolve()  # resolve symlinks (~/bin=setup/HOME/bin)
    return path.parents[path.parts[::-1].index(HOME_DIR)]


def home():
    return root() / HOME_DIR


def home_path(path):
    """Get the path within setup's HOME for the given path

    Note: no valid setup path for anything outside of $HOME, so throws exception
    """
    return home() / Path(path).resolve().relative_to(Path.home())
