"""A library for controlling Homebrew through Python."""
import getpass
import logging
import os
import pwd
import re
import shutil
import subprocess
from itertools import chain

from .utils import run

log = logging.getLogger(__name__)


def workflow(settings, fix_repo=False):
    """Run an entire Homebrew update workflow."""
    ensure_homebrew_installed()

    if fix_repo:
        fix_repository()

    ensure_command_line_tools_installed()

    update()

    update_taps(settings.get('taps', []))
    update_formulas(settings.get('formulas', []))
    update_casks(settings.get('casks', []))

    prune()

    run_post_install(settings['post_install'])


def ensure_homebrew_installed():
    """Install Homebrew if it's not installed."""
    if not is_installed():
        install_homebrew()


def is_installed():
    """Return True if Homebrew is installed."""
    return bool(shutil.which('brew'))


def install_homebrew():
    log.warning("Installing Homebrew")
    # Incantation from https://brew.sh/
    run('/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"')


def get_installed_formulas():
    log.info("Getting installed formulas")
    return _get_command_output(['brew', 'list'])


def get_installed_casks():
    log.info("Getting installed casks")
    return _get_command_output(['brew', 'cask', 'list'])


def get_installed_taps():
    log.info("Getting installed taps")
    return _get_command_output(['brew', 'tap'])


def install_formula(formula):
    log.info(f"Installing formula: {formula}")
    if isinstance(formula, str):
        formula = [formula]
    run(['brew', 'install', *formula])


def install_cask(cask):
    # note: brew cask doesn't support upgrade yet:
    # https://github.com/caskroom/homebrew-cask/issues/4678

    log.info(f"Installing cask: {cask}")
    run(['brew', 'cask', 'install', cask])


def install_tap(tap):
    log.info(f"Installing tap: {tap}")
    run(['brew', 'tap', tap])


def cleanup_formulas():
    log.info("Running cleanup: formulas")
    # from 'brew cleanup --help':
    # If -s is passed, scrub the cache, removing downloads for even the latest
    # versions of formulae. Note downloads for any installed formulae will still
    # not be deleted. If you want to delete those too: rm -rf $(brew --cache)
    run(['brew', 'cleanup', '-s'])

    # I'm super uncomfortable with running rm -rf on the output of a command
    # I don't control without interactively checking what $brew --cache outputs
    #     would call: run('rm -rf "$(brew --cache)"')
    # so at least verify basic things about the cache location, that it's
    # under /Users/{username}/Library/Caches/Homebrew
    pathspec = r'/Users/\w+/Library/Caches/Homebrew'
    cachedir = brew_cache()
    if not re.match(pathspec, cachedir):
        raise Exception(f"Cache location {cachedir!r} doesn't match pattern '{pathspec}'")

    space = get_space_used(cachedir)
    log.info(f"Deleting cache at {cachedir!r}. Will free {space} space.")
    delete_dir(cachedir)


def brew_cache():
    return run("echo -n $(brew --cache)", cap=True)


def brew_prefix():
    return run("echo -n $(brew --prefix)", cap=True)


def get_space_used(dir):
    # output looks like "3.6G   /directory" so just get the first column
    return run(f'du -hd0 "{dir}"', cap=True).split()[0]


def delete_dir(dir):
    run(f"rm -rf '{dir}'")


def cleanup_casks():
    log.info("Running cleanup: casks")
    run(['brew', 'cask', 'cleanup'])


def update():
    log.info("Updating Homebrew")
    run(['brew', 'update'])


def prune():
    log.info("Running prune")
    run(['brew', 'prune'])


def upgrade():
    log.info("Running upgrade")
    # Homebrew can return an error code in cases that aren't errors:
    # https://github.com/Homebrew/homebrew/issues/27048
    # so, catch any error here and make sure to inspect the output for problems
    try:
        run(['brew', 'upgrade'])
    except:
        pass


def install_missing(type, expected):
    assert type in ('formula', 'cask', 'tap')

    # retrieve the functions for the given type
    get_installed = globals()[f'get_installed_{type}s']
    install = globals()[f'install_{type}']

    # compare what's installed to what's expected
    installed = get_installed()
    log.info(f"Expected {type}s are: {', '.join(sorted(expected))}")
    log.info(f"Currently installed {type}s are: {', '.join(installed)}")
    missing = sorted(set(expected) - set(installed))

    # install anything missing
    if missing:
        log.info(f"Missing {type}s are: {', '.join(missing)}")
        for item in missing:
            install(item)
    else:
        log.info(f"No missing {type}s")


def update_formulas(formulas):
    log.info("Updating formulas")
    upgrade()
    install_missing('formula', formulas)
    cleanup_formulas()

    # possible todo: remove things not in settings, but that'd delete things you installed manually
    # maybe provide option to list things that "shouldn't" be installed so they can be
    # removed manually


def update_casks(casks):
    install_missing('cask', casks)
    cleanup_casks()


def update_taps(taps):
    install_missing('tap', taps)


def ensure_command_line_tools_installed():
    """Ensure command line tools are installed."""
    log.info("Ensuring command line tools are installed")
    try:
        run(['xcode-select', '--install'])
    except subprocess.CalledProcessError as error:
        if error.returncode == 1:
            log.info("Command line tools already installed")
        else:
            raise


def run_post_install(post_install):
    """
    Run any post-install operations.

    'post_install' is a list of shell commands. Each shell command can be a string or a list
    of strings. If a string, will pass shell=True to the subprocess call.

    """
    if not post_install:
        return

    log.info("Running post-install operations")
    for cmd in post_install:
        run(cmd)


def fix_repository():
    # http://stackoverflow.com/questions/14113427/brew-update-failed
    log.info("Fixing Homebrew repository")
    run('cd `brew --prefix`; git reset --hard origin/master')


def get_formula_uses(formula, installed=True):
    """Get the formulas that depend on the specified formula."""
    log.info(
        f"Getting {'installed' if installed else 'all'} formulas that depend on formula: {formula}")
    cmd = ['brew', 'uses']
    if installed:
        cmd += ['--installed']
    cmd += [formula]
    return _get_command_output(cmd)


def get_formula_dependencies(formula):
    """Get dependencies for the specified formula."""
    log.info(f"Getting dependencies for formula: {formula}")
    return _get_command_output(['brew', 'deps', formula])


def get_installed_formulas_with_dependencies():
    """Get a dictionary mapping formulas to their dependencies."""
    return {
        formula: get_formula_dependencies(formula)
        for formula in get_installed_formulas()
    }


def get_leaf_formulas():
    """Get the formulas that are not the dependencies of other formulas."""
    formulas_with_deps = get_installed_formulas_with_dependencies()
    all_deps = set(chain.from_iterable(deps for deps in formulas_with_deps.values()))
    all_formulas = set(formulas_with_deps.keys())
    return all_formulas - all_deps


def _get_command_output(cmd):
    """Execute the specified command, parse its output, and return a list of items in the output."""
    # bytes.decode defaults to utf-8, which *should* also be the default system encoding
    # but I suppose to really do this correctly I should check that. However, pretty sure
    # all Homebrew package names should be ascii anyway so it's fine
    return run(cmd, cap=True).splitlines()


