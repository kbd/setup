"""A library for controlling Homebrew through Python."""

import getpass
import logging
import os
import pwd
import shutil
import subprocess

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
    log.info("Installing formula: {}".format(formula))
    _execute(['brew', 'install', formula])


def install_cask(cask):
    # note: brew cask doesn't support upgrade yet:
    # https://github.com/caskroom/homebrew-cask/issues/4678

    log.info("Installing cask: {}".format(cask))
    _execute(['brew', 'cask', 'install', cask])


def install_tap(tap):
    log.info("Installing tap: {}".format(tap))
    _execute(['brew', 'tap', tap])


def cleanup():
    log.info("Running cleanup")
    _execute(['brew', 'cleanup'])


def update():
    log.info("Updating Homebrew")
    _execute(['brew', 'update'])


def upgrade():
    log.info("Running upgrade")
    # Homebrew can return an error code in cases that aren't errors:
    # https://github.com/Homebrew/homebrew/issues/27048
    # so, catch any error here and make sure to inspect the output for problems
    try:
        _execute(['brew', 'upgrade', '--all'])
    except:
        pass


def install_missing(type, expected):
    assert type in ('formula', 'cask', 'tap')
    get_installed = globals()['get_installed_{}s'.format(type)]
    install = globals()['install_{}'.format(type)]

    log.info("Expected {}s are: {}".format(type, ', '.join(sorted(expected))))
    installed = get_installed()
    log.info("Currently installed {}s are: {}".format(type, ', '.join(installed)))

    missing = sorted(set(expected) - set(installed))
    log.info("Missing {}s are: {}".format(type, ', '.join(missing)))
    for item in missing:
        install(item)


def update_formulas(formulas):
    log.info("Updating formulas")
    upgrade()
    install_missing('formula', formulas)
    cleanup()

    # possible todo: remove things not in settings, but that'd delete things you installed manually
    # maybe provide option to list things that "shouldn't" be installed so they can be
    # removed manually


def update_casks(casks):
    install_missing('cask', casks)


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

    log.debug("Currently logged in user is {!r}, owner of /usr/local is {!r}".format(
        user, local_owner))

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


def _get_command_output(cmd):
    """Execute the specified command, parse its output, and return a list of items in the output."""
    # bytes.decode defaults to utf-8, which *should* also be the default system encoding
    # but I suppose to really do this correctly I should check that. However, pretty sure
    # all Homebrew package names should be ascii anyway so it's fine
    log.debug("Executing: {}".format(cmd))
    return subprocess.check_output(cmd).decode().split()


def _execute(cmd, shell=False):
    log.debug("Executing: {}".format(cmd))
    subprocess.check_call(cmd, shell=isinstance(cmd, str))
