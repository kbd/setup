import os
import sys


def add_bin_to_path():
    binpath = os.path.abspath(
        os.path.join(os.path.dirname(__file__), '../HOME/bin'))
    sys.path.append(binpath)
