#!/usr/bin/env python

"""Bootstrap the setup tool.

This assumes Python is installed on the target os, but not specifically Python3.

What this does (only intended for Mac atm):

* installs Homebrew
* Homebrew installs a core set of packages (git and python3)
* git check out the project into ~/setup
* run
  - setup (will restart os functions to reflect new settings)
  - setup brew
  - setup packages
* tell the user to restart terminal to get new everything

You should be able to run this with curl | python shenanigans.

"""

import os
import subprocess

REPO_URL = 'https://github.com/kbd/setup.git'
HOMEBREW_INSTALL_CMD = '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
SETUP_PATH = os.path.expanduser('~/setup')
SETUP_EXE = os.path.join(SETUP_PATH, 'HOME/bin/setup')

def main():
    print("Installing Homebrew")
    if not subprocess.call(['which', 'brew']):
        print("Homebrew is installed")
    else:
        subprocess.check_call(HOMEBREW_INSTALL_CMD, shell=True, executable='/bin/bash')

    print("Installing dependencies")
    for cmd in 'git', 'python':
        subprocess.check_call("brew install {0} || brew upgrade {0}".format(cmd), shell=True)
    subprocess.check_call(['pip3', 'install', '--upgrade', 'click'])  # required for 'setup'

    if os.path.exists(SETUP_PATH):
        print("Setup location already exists, updating")
        subprocess.check_call(['git', 'pull'], cwd=SETUP_PATH)
    else:
        print("Checking out setup repo")
        subprocess.check_call(['git', 'clone', REPO_URL], cwd=os.path.dirname(SETUP_PATH))

    print("Installing all the things")
    # add to path because bootstrapping
    os.environ['PATH'] = ':'.join([
        os.path.dirname(SETUP_EXE),  # add repo bin dir to path, symlinks not yet run
        os.path.expanduser('~/bin'),
        os.environ['PATH']
    ])
    subprocess.check_call([SETUP_EXE, 'init'])
    print("Done installing all the things. Restart your terminal.")


if __name__ == '__main__':
    main()
