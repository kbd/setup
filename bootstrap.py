#!/usr/bin/env python3
import os
import subprocess
from pathlib import Path

REPO_URL = 'https://github.com/kbd/setup.git'
SETUP_PATH = Path('~/setup').expanduser()
BIN_PATH = Path('~/bin').expanduser()


def run(*cmd, **kwargs):
    print(f"Executing: {cmd}")
    subprocess.run(cmd, check=True, **kwargs)


os.environ['PATH'] = ':'.join([str(BIN_PATH), '/opt/homebrew/bin', os.environ["PATH"]])

if SETUP_PATH.exists():
    print("Setup location exists, updating")
    run('git', 'pull', cwd=SETUP_PATH)
else:
    print("Checking out setup repo")
    run('git', 'clone', REPO_URL, cwd=SETUP_PATH.parent)

print("Installing ALL THE THINGS!")
run(SETUP_PATH/'HOME/bin/homebrew-workflow', SETUP_PATH/'conf/Brewfile')
run(SETUP_PATH/'HOME/bin/setup', 'init')
print("Done installing all the things.")
