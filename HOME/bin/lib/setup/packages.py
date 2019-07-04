import logging
import re
import runpy

from lib import homebrew
from lib.mac import defaults
from lib.utils import run

log = logging.getLogger()


def install_packages(settings, *args, **kwargs):
    log.info("Installing/upgrading packages")
    filter = kwargs['filter']
    for name, settings in settings['packages'].items():
        if filter and not re.search(filter, name):
            log.debug(f"Skipping {name}")
            continue

        if settings.get('skip_if_not_requested') and (
            not filter or (filter and not re.fullmatch(filter, name))
        ):
            log.info(f"Skipping {name}; not specifically requested")
            continue

        install_package(name, settings)


def install_package(name, settings):
    log.info(f"Installing packages for: {name}")
    module = globals()
    if name in module:
        # if the name matches a function in this module, call it and pass settings
        log.debug(f"Found package function for {name}")
        module[name](settings)
    else:
        # otherwise, expect a cmd to run
        cmd = settings['cmd']
        log.debug(f"Executing: {cmd}")
        run(cmd)

    # post_install should be a list of shell commands passed directly to 'run'
    post_install = settings.get('post_install')
    if post_install:
        log.info("Running post-install operations")
        for cmd in post_install:
            run(cmd)


def vscode(settings):
    config_path = settings['extensions']
    log.info("Updating Visual Studio Code extensions")

    # show currently installed extensions
    cmd = ['code', '--list-extensions']
    current_extensions = set(map(str.strip, run(cmd, cap='stdout').splitlines()))
    expected_extensions = set(map(str.strip, open(config_path)))

    fmt = lambda s: ', '.join(sorted(s, key=str.lower))

    log.debug(f"Current extensions are: {fmt(current_extensions)}")
    log.debug(f"Expected extensions are: {fmt(expected_extensions)}")

    # install any missing extensions
    missing = expected_extensions - current_extensions
    for package in sorted(missing):
        log.info(f"Installing missing package: {package}")
        run(['code', '--install-extension', package])

    # report any extensions that are installed that aren't in source control
    unexpected = current_extensions - expected_extensions
    if unexpected:
        log.info(f"The following extensions are installed but not in source control: {fmt(unexpected)}")


def brew(settings):
    homebrew.workflow(settings['bundle'])


def mac(settings):
    path = settings['path']
    log.info(f"Running {path}")
    runpy.run_path(path, {'defaults': defaults, 'run': run})
