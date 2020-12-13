"""A library for controlling Homebrew through Python."""
import logging
import os
import re
import shutil
import subprocess
import sys

from .utils import run

log = logging.getLogger(__name__)


def workflow(bundle):
    """Run an entire Homebrew update workflow."""
    # prereqs
    ensure_homebrew_installed()
    ensure_command_line_tools_installed()

    # update
    update()

    # install
    bundle_install(bundle)

    # cleanup
    cleanup()
    clean_cache()


def bundle_install(path):
    log.info("Running bundle install")
    # if relative path, will be relative to root of repo
    run(['brew', 'bundle', '-v', f"--file={path}"])
    # it doesn't accept ('--file', path) or ('--file=', path)


def ensure_homebrew_installed():
    """Install Homebrew if it's not installed."""
    log.info("Ensuring Homebrew is installed")
    if not is_installed():
        install_homebrew()
    else:
        log.info("Homebrew is installed")


def is_installed():
    """Return True if Homebrew is installed."""
    return bool(shutil.which('brew'))


def install_homebrew():
    log.warning("Installing Homebrew")
    # Incantation from https://brew.sh/
    run('/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"')


def cleanup():
    log.info("Running cleanup")
    # from 'brew cleanup --help':
    # If -s is passed, scrub the cache, including downloads for even the latest
    # versions. Note downloads for any installed formula or cask will still not
    # be deleted. If you want to delete those too: rm -rf $(brew --cache)
    run(['brew', 'cleanup', '-s'])


def makedirs(path):
    """This exists purely because it's easier to mock"""
    os.makedirs(path)


def clean_cache():
    # I'm super uncomfortable with running rm -rf on the output of a command
    # I don't control without interactively checking what $brew --cache outputs
    #     would call: run('rm -rf "$(brew --cache)"')
    # so at least verify basic things about the cache location, that it's
    # under /Users/{username}/Library/Caches/Homebrew
    pathspec = r'/Users/\w+/Library/Caches/Homebrew'
    cachedir = brew_cachedir()
    if not re.match(pathspec, cachedir):
        raise Exception(f"Cache location {cachedir!r} doesn't match pattern '{pathspec}'")

    space = get_space_used(cachedir)
    log.info(f"Deleting cache at {cachedir!r}. Will free {space} space.")
    delete_dir(cachedir)
    log.info("Deleted cache")

    path = os.path.join(cachedir, 'Cask')
    log.info(f"Recreating empty cache dir: {path}")
    makedirs(path)


def brew_cachedir():
    return run(['brew', '--cache'], cap=True).strip()


def get_space_used(dir):
    # output looks like "3.6G   /directory" so just get the first column
    return run(['du', '-hd0', dir], cap=True).split()[0]


def delete_dir(dir):
    run(['rm', '-rf', dir])


def update():
    log.info("Updating Homebrew")
    run(['brew', 'update'])


def ensure_command_line_tools_installed():
    """Ensure command line tools are installed."""
    log.info("Ensuring command line tools are installed")
    try:
        run(['xcode-select', '--install'], cap=True)
        input("Hit enter when installer is finished, or ctrl+c to quit ")
    except subprocess.CalledProcessError as error:
        if error.returncode == 1:
            log.info("Command line tools are installed")
        else:
            raise
    except KeyboardInterrupt:
        print("\nExiting")
        sys.exit(1)
