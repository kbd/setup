import os
import sys


def add_bin_to_path():
    BINPATH = os.path.abspath(
        os.path.join(os.path.dirname(__file__), '../HOME/bin'))
    sys.path.append(BINPATH)
