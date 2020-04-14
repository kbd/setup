import logging
import re
import runpy
import shutil
from pathlib import Path

from lib import homebrew, setup
from lib.mac import defaults
from lib.utils import read_config_file, run

log = logging.getLogger()


def install_packages(settings, args, **kwargs):
    log.info("Installing/upgrading packages")
    filter = kwargs.get('filter') or args.filter
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


def run_commands(cmd, cwd=None):
    """Take one or more commands to run as a subprocess.

    * 'cmd' be one command or a tuple of commands
    * each command can be a string or a list of strings, passed to utils.run
    """
    if isinstance(cmd, tuple):
        return [run(c, cwd=cwd) for c in cmd]

    return run(cmd, cwd=cwd)


def install_package(name, settings):
    log.info(f"Installing packages for: {name}")
    module = globals()
    if name in module:
        # if the name matches a function in this module, call it and pass settings
        log.debug(f"Found package function for {name}")
        module[name](settings)
    else:
        # otherwise, expect a cmd to run
        run_commands(settings['cmd'])

    # run post-install operations, if present
    post_install = settings.get('post_install')
    if post_install:
        log.info("Running post-install operations")
        run_commands(post_install)


def vscode(settings):
    config_path = settings['extensions']
    log.info("Updating Visual Studio Code extensions")

    # get installed/expected extensions
    cmd = ['code', '--list-extensions']
    current_extensions = set(map(str.strip, run(cmd, cap='stdout').splitlines()))
    expected_extensions = set(read_config_file(config_path))

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


def manual(settings):
    """Set up software that is more manual.

    For example, software that isn't configured with a package manager like
    Homebrew, where an archive needs to be downloaded and unpacked, or a repo
    needs to be checked out from git and a program manually built.

    Conventions:
        * if git, shallow check out into __deps/{name}
        * if archive, download into __deps/{name}/{archive_name},
          extract and process from there

    Note that 'setup' automatically sets the cwd to the root of the repo, so
    __deps == repo_root/__deps.

    Could be clever and, with git, for example:
        * check if dir exists
        * and is a git repo
        * and remote = the same as is currently specified in the config
        * if so, git pull
        * else, blow away and re-get

    Instead, at least to start with, each time just get from scratch.

    For now, just support git.
    """
    def create_symlink(dir, relative_path):
        """Create symlink in ~/bin to binary at dir/relative_path"""
        # no funny stuff, also ensures relative_path is a Path
        assert not relative_path.is_absolute(), f"relative path ({relative_path}) can't be absolute"
        to = setup.root() / dir / relative_path
        frm = Path('~/bin').expanduser() / relative_path.name
        run(['symgr', frm, to], check=True)

    dir = setup.root() / settings['dir']  # directory to download / checkout to
    for name, params in settings['packages'].items():
        log.info(f"Running setup for {name!r}")
        url = params['url']  # url of git repository
        cmd = params.get('cmd')  # commands to run after cloning
        bin = params.get('bin')  # path to the executable to install in ~/bin

        # remove if exists
        path = Path(dir, name)
        assert Path.home() in path.parents, f"path ({path}) must be under $HOME"
        if path.exists():
            log.info(f"Deleting existing directory: {path}")
            if input(f"rm -rf '{path}' ok? (y/N) ").upper() == 'Y':
                shutil.rmtree(path)
            else:
                log.info(f"Skipping {name}")
                continue

        # clone repo
        git_clone = ['git', 'clone', '--depth', '1', url, path]
        run(git_clone)

        # run any build commands
        if cmd:
            run_commands(cmd, path)

        # link any binaries specified
        if bin:
            # accept either a string or a sequence of strings
            if isinstance(bin, str):
                bin = [bin]

            for b in bin:
                create_symlink(dir, Path(name, b))
