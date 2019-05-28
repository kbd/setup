import io
import logging
import re
import runpy
import subprocess
import zipfile

from lib import homebrew
from lib.mac import defaults
from lib.utils import run, read_lines_from_file

log = logging.getLogger()


def install_packages(settings, *args, **kwargs):
    log.info("Installing/upgrading packages")
    module = globals()
    language_filter = kwargs['language_filter']
    for language, params in settings['packages'].items():
        if language_filter and not re.search(language_filter, language):
            log.debug(f"Skipping {language}")
            continue

        if params.get('skip_if_not_requested') and (
            not language_filter or
            (language_filter and not re.fullmatch(language_filter, language))
        ):
            log.info(f"Skipping {language}; not specifically requested")
            continue

        log.info(f"Installing/upgrading packages for: {language}")

        # if the name of the "language" matches a function in this module, call
        # the function and pass it a reference to the settings for that "language"
        if language in module:
            # the function does whatever it wants with its settings
            log.debug(f"Found package function for {language}")
            module[language](params, language_filter)
        else:
            # allow specific commands
            cmd = params['cmd']
            log.debug(f"Executing: {cmd}")
            run(cmd)

        # post_install should be a list of shell commands.
        # Each shell command can be a string or a list of strings, passed to 'run'
        post_install = params.get('post_install')
        if post_install:
            log.info("Running post-install operations")
            for cmd in post_install:
                run(cmd)


def vscode(package_settings, language_filter):
    config_path = package_settings['extensions']
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


def brew(package_settings, language_filter):
    homebrew.workflow(package_settings['bundle'])


def mac(settings, language_filter):
    path = settings['path']
    log.info(f"Running {path}")
    runpy.run_path(path, {'defaults': defaults, 'run': run})
