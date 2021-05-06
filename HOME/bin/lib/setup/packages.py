import logging

from lib.utils import run_commands

log = logging.getLogger(__name__)


def install(name, settings):
    log.info(f"Setting up: {name}")
    if func := globals().get(name):
        # if the name matches a function in this module, call it and pass settings
        log.debug(f"Found package function for {name}")
        func(settings)

    if code := settings.get('exec'):
        log.debug(f"Executing: {code}")
        exec(code)

    if cmd := settings.get('cmd'):
        log.debug(f"Running: {cmd}")
        run_commands(cmd)
