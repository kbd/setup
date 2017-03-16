"""A library for controlling Homebrew through Python."""

import getpass
import logging
import os
import pwd
import shutil
import subprocess
from itertools import chain

log = logging.getLogger(__name__)


def workflow(settings, fix_repo=False):
    """Run an entire Homebrew update workflow."""
    if not is_installed():
        # todo: install homebrew if not installed
        raise Exception("Homebrew must be installed")

    if fix_repo:
        fix_repository()

    ensure_correct_permissions()
    ensure_command_line_tools_installed()

    update()

    update_taps(settings.get('taps', []))
    update_formulas(settings.get('formulas', []))
    update_casks(settings.get('casks', []))

    run_post_install(settings['post_install'])


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
    _execute(['brew', 'install', *formula])


def install_cask(cask):
    # note: brew cask doesn't support upgrade yet:
    # https://github.com/caskroom/homebrew-cask/issues/4678

    log.info(f"Installing cask: {cask}")
    _execute(['brew', 'cask', 'install', cask])


def install_tap(tap):
    log.info(f"Installing tap: {tap}")
    _execute(['brew', 'tap', tap])


def cleanup_formulas():
    log.info("Running cleanup: formulas")
    _execute(['brew', 'cleanup'])


def cleanup_casks():
    log.info("Running cleanup: casks")
    _execute(['brew', 'cask', 'cleanup'])


def update():
    log.info("Updating Homebrew")
    _execute(['brew', 'update'])


def upgrade():
    log.info("Running upgrade")
    # Homebrew can return an error code in cases that aren't errors:
    # https://github.com/Homebrew/homebrew/issues/27048
    # so, catch any error here and make sure to inspect the output for problems
    try:
        _execute(['brew', 'upgrade'])
    except:
        pass


def install_missing(type, expected):
    assert type in ('formula', 'cask', 'tap')
    get_installed = globals()[f'get_installed_{type}s']
    install = globals()[f'install_{type}']

    log.info(f"Expected {type}s are: {', '.join(sorted(expected))}")
    installed = get_installed()
    log.info(f"Currently installed {type}s are: {', '.join(installed)}")

    missing = sorted(set(expected) - set(installed))
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
        _execute(['xcode-select', '--install'])
    except subprocess.CalledProcessError as error:
        if error.returncode == 1:
            log.info("Command line tools already installed")
        else:
            raise


def ensure_correct_permissions(*args, **kwargs):
    """Ensure that the Homebrew formula installation directory has correct permissions."""
    user = getpass.getuser()
    uid = os.stat('/usr/local').st_uid
    local_owner = pwd.getpwuid(uid).pw_name

    log.debug(f"Currently logged in user is {user!r}, owner of /usr/local is {local_owner!r}")

    if user != local_owner:
        log.info("Fixing permissions on /usr/local before running Homebrew")
        # stupid that there's a shutil.chown but no shutil.chown -R
        cmd = ['sudo', 'chown', '-R', user, '/usr/local']
        _execute(cmd)


def is_installed():
    """Return True if Homebrew command is installed."""
    return bool(shutil.which('brew'))


def install():
    """Install Homebrew on a system that doesn't have it."""
    # http://brew.sh/
    # ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    pass


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
        _execute(cmd)


def fix_repository():
    # http://stackoverflow.com/questions/14113427/brew-update-failed
    log.info("Fixing Homebrew repository")
    _execute('cd `brew --prefix`; git reset --hard origin/master')


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
    log.debug(f"Executing: {cmd!r}")
    return subprocess.check_output(cmd).decode().split()


def _execute(cmd, shell=False):
    log.debug(f"Executing: {cmd!r}")
    subprocess.check_call(cmd, shell=isinstance(cmd, str))
