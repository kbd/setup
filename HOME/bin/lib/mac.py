import logging
import subprocess

from . import homebrew

log = logging.getLogger(__name__)


def brew(settings, *args, **kwargs):
    # filter for valid args to workflow
    kwargs = {k: v for k, v in kwargs.items() if k in ['fix_repo']}
    homebrew.workflow(settings['homebrew'], **kwargs)


def update_os_settings(settings):
    # defaults read | pbcopy to get a list of all current settings
    # execute mac.sh in conf as a shell script
    mac_settings_location = 'conf/mac.sh'
    log.info(f"Running {mac_settings_location}")
    subprocess.run(mac_settings_location)
    restart_os_functions()


def restart_os_functions(*args, **kwargs):
    for item in ('Finder', 'Dock', 'SystemUIServer'):
        cmd = ['killall', item]
        log.info(f"Executing command: {cmd!r}")
        subprocess.check_call(cmd)
