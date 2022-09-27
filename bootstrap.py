#!/usr/bin/env python3
"""Bootstrap the setup tool.

What this does (only intended for Mac atm):

* git check out the project into ~/setup
* run setup init

You should be able to run this with curl | python shenanigans.

"""

import os
import subprocess
from pathlib import Path

REPO_URL = 'https://github.com/kbd/setup.git'
SETUP_PATH = Path('~/setup').expanduser()


def run(cmd, **kwargs):
    print(f"Executing: {cmd}")
    subprocess.run(cmd, check=True, **kwargs)


def main():
    if SETUP_PATH.exists():
        print("Setup location exists, updating")
        run(['git', 'pull'], cwd=SETUP_PATH)
    else:
        print("Checking out setup repo")
        run(['git', 'clone', REPO_URL], cwd=SETUP_PATH.parent)

    os.environ['PATH'] = ':'.join([
        str(Path("~/bin").expanduser()),
        str(Path("~/.cargo/bin").expanduser()),
        '/opt/homebrew/bin', # M1 homebrew path
        os.environ["PATH"],
    ])
    print("Installing all the things")
    run(['brew', 'install', 'just'])
    run(['just', '--justfile', SETUP_PATH/'justfile', 'init'])
    print("Done installing all the things.")


if __name__ == '__main__':
    main()
