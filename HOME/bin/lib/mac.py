import logging
import subprocess
from itertools import chain

from . import homebrew
from .utils import run

log = logging.getLogger(__name__)


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


DEFAULTS_TYPE_MAP = {
    bool: 'bool',
    int: 'int',
    float: 'float',
    str: 'string',
    dict: 'dict',
}

def flatten(value):
    # will throw exception for unknown type, which is fine
    result = [f'-{DEFAULTS_TYPE_MAP[type(value)]}']
    if isinstance(value, dict):
        result.extend(chain.from_iterable((k, *flatten(v)) for k, v in value.items()))
    else:
        result.append(str(value))

    return result

class _DefaultsDomain:
    def __init__(self, domain=None):
        self.domain = domain

    def __getitem__(self, key):
        if not self.domain:  # still needs a domain
            return _DefaultsDomain(key)

        run(["defaults", "read", self.domain, key])

    def __setitem__(self, key, value):
        run(["defaults", "write", self.domain, key, *flatten(value)])


defaults = _DefaultsDomain()
defaults.g = defaults['-g']
