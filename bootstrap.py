#!/usr/bin/env python3
"""Bootstrap the setup tool.

What this does (only intended for Mac atm):

* install Homebrew
* using Homebrew, install a core set of packages
* git check out the project into ~/setup
* run setup init

You should be able to run this with curl | python shenanigans.

"""

import os
import subprocess
from pathlib import Path

REPO_URL = 'https://github.com/kbd/setup.git'
HOMEBREW_INSTALL_CMD = '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
SETUP_PATH = Path('~/setup').expanduser()
SETUP_EXE = SETUP_PATH / 'HOME/bin/setup'

def run(*args, **kwargs):
    print(f"Executing: {args}")
    subprocess.run(*args, check=True, **kwargs)

def main():
    print("Installing Homebrew")
    if not subprocess.run(['which', 'brew']).returncode:
        print("Homebrew is installed")
    else:
        run(HOMEBREW_INSTALL_CMD, shell=True, executable='/bin/bash')

    print("Installing dependencies")
    run(['brew', 'install', 'git'])
    run(['pip3', 'install', '--upgrade', 'click'])  # required for 'setup'

    if SETUP_PATH.exists():
        print("Setup location already exists, updating")
        run(['git', 'pull'], cwd=SETUP_PATH)
    else:
        print("Checking out setup repo")
        run(['git', 'clone', REPO_URL], cwd=SETUP_PATH.parent)

    print("Installing all the things")
    # add to path because bootstrapping
    os.environ['PATH'] = ':'.join([
        str(SETUP_EXE.parent),  # add repo bin dir to path, symlinks not yet run
        str(Path('~/bin').expanduser()),
        os.environ['PATH']
    ])
    run([SETUP_EXE, 'init'])
    print("Done installing all the things. Restart your terminal.")


if __name__ == '__main__':
    main()
