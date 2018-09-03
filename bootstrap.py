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
HOMEBREW_INSTALL_CMD = '/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"'

def main():
    print("Installing Homebrew")
    if not bool(subprocess.call(['which', 'brew'])):
        print("Homebrew is installed")
    else:
        subprocess.check_call(HOMEBREW_INSTALL_CMD, shell=True, executable='/bin/bash')

    print("Installing git and Python 3")
    subprocess.check_call(['brew', 'install', 'git'])
    subprocess.check_call(['brew', 'install', 'python'])

    setup_path = os.path.expanduser('~/setup')
    if os.path.exists(setup_path):
        print("Setup location already exists, updating")
        subprocess.check_call(['git', 'pull'], cwd=setup_path)
    else:
        print("Checking out setup repo")
        subprocess.check_call(['git', 'clone', REPO_URL], cwd=os.path.dirname(setup_path))

    setup_exe = os.path.join(setup_path, 'HOME/bin/setup')

    print("Installing all the things")
    subprocess.check_call([setup_exe, 'brew'])
    subprocess.check_call([setup_exe, 'packages'])
    subprocess.check_call([setup_exe])

    print("Done installing all the things. Restart your terminal.")


if __name__ == '__main__':
    main()
