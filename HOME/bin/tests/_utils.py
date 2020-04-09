"""Utility functions to aid in testing."""

import sys
from imp import load_source
from os.path import abspath, dirname, join


def get_bin_path():
    """Get the path to the HOME/bin directory."""
    return abspath(join(dirname(__file__), '..'))


def add_bin_to_path():
    """Add the HOME/bin directory to the PATH."""
    binpath = get_bin_path()
    sys.path.append(binpath)


def import_executable(name):
    """Import the executable named 'name' as a Python module.

    example: "import setup" doesn't work because 'setup' needs a .py extension

    a few options to test python "executables":

    1. put all testable code in a lib so you can import them safely and the exe is
       just a thin wrapper (main still not testable, damages your code)
    2. just make the 'executable' a symlink to the .py file (clutters ls)
    3. do an import like this for the tests on executables

    """
    exe_path = join(get_bin_path(), name)
    return load_source(name, exe_path)
