import abc
import getpass
import logging
import os
import pwd
import re
import shutil
import subprocess
from collections import OrderedDict
from distutils.util import strtobool

from . import homebrew

log = logging.getLogger(__name__)


def brew(action, settings, *args, **kwargs):
    # filter for valid args to workflow
    kwargs = {k: v for k, v in kwargs.items() if k in ['fix_repo']}
    homebrew.workflow(settings['homebrew'], **kwargs)


class mybool(metaclass=abc.ABCMeta):
    """
    Provide something that will parse '0' as False
    because that's how 'defaults' returns false values

    """
    def __new__(self, value='0'):
        return bool(strtobool(value))

mybool.register(bool)


# map 'defaults' types to Python's types
# Use OrderedDict because isinstance(True, int) is True, so compare to bool first
DEFAULTS_TO_PYTHON_TYPE = OrderedDict((
    ('boolean', mybool),
    ('integer', int),
    ('float', float),
    ('string', str),
))


def defaults_read(domain, key, missing_ok=False):
    cmd = ['defaults', 'read-type', domain, key]
    log.debug("Executing command: {!r}".format(cmd))
    try:
        result = subprocess.check_output(cmd, stderr=subprocess.STDOUT)
    except subprocess.CalledProcessError as e:
        output = e.output.decode()  # bytes -> string
        log.warning("Error reading setting {}:{}. Return code {}, output was: {}".format(
            domain, key, e.returncode, output))

        if 'does not exist' in output:
            log.warning("Prior value for {}:{} doesn't exist".format(domain, key))
            if missing_ok:
                return None

        raise

    log.debug("Result was: {!r}".format(result))

    result_type = re.match('Type is (\w+)', result.decode()).group(1)
    type = DEFAULTS_TO_PYTHON_TYPE[result_type]

    cmd = ['defaults', 'read', domain, key]
    log.debug("Executing command: {!r}".format(cmd))
    result = subprocess.check_output(cmd)
    typed_result = type(result.decode().rstrip('\n'))
    log.debug("Result was: {!r}, typed_result was {!r}".format(result, typed_result))
    return typed_result


def defaults_write(domain, key, value):
    cmd = ['defaults', 'write', domain, key]

    for type_str, type in DEFAULTS_TO_PYTHON_TYPE.items():
        if isinstance(value, type):
            break
    else:
        raise Exception("Unsupported value type provided to defaults_write: {!r}".format(value))

    cmd.extend(['-{}'.format(type_str), str(value)])

    log.debug("Executing command: {!r}".format(cmd))
    subprocess.check_call(cmd)


def update_os_settings(settings):
    # useful resources
    # https://github.com/mathiasbynens/dotfiles/blob/master/.osx

    # defaults read | pbcopy to get a list of all current settings

    defaults = settings['osx']['defaults']
    for domain, settings in sorted(defaults.items()):
        for key, value in sorted(settings.items()):
            old_value = defaults_read(domain, key, missing_ok=True)

            if old_value != value:
                log.info("Setting new value for {}:{}. Old value: {!r}, new value: {!r}.".format(
                    domain, key, old_value, value))

            defaults_write(domain, key, value)


def restart_os_functions(*args, **kwargs):
    for item in ('Finder', 'Dock', 'SystemUIServer'):
        cmd = ['killall', item]
        log.info("Executing command: {!r}".format(cmd))
        subprocess.check_call(cmd)
