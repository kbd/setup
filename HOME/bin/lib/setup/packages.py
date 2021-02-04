import logging
import re
import runpy
import shutil
import subprocess
from pathlib import Path

from lib import homebrew, setup
from lib.colors import fg, s
from lib.mac import defaults
from lib.utils import read_config_file, run
from tabulate import tabulate

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
    if unexpected := current_extensions - expected_extensions:
        log.info(f"The following extensions are installed but not in source control: {fmt(unexpected)}")


def brew(settings):
    homebrew.workflow(settings['bundle'])


def mac(settings):
    path = settings['path']
    log.info(f"Running {path}")
    runpy.run_path(path, {'defaults': defaults, 'run': run})


def _format_manual_packages_table(packages, dir):
    items = [
        [
            f"{fg.yellow}{key}{s.reset}",
            params.get('git', params.get('url')), # source
            f'{fg.green}yes{s.reset}' if Path(dir, key).exists() else f'{fg.red}no{s.reset}'
        ]
        for key, params in packages.items()
    ]
    headers = [f"{fg.blue}{s.bold}{k}{s.reset}" for k in ["key","source","installed"]]
    table = tabulate(items, headers=headers, tablefmt="plain")
    return table


def _get_manual_packages_to_install(packages, dir):
    if not Path(dir, 'symgr').exists():
        # special-case symgr, since everything else depends on it.
        # if not installed, we're bootstrapping, so install everything.
        return packages.keys()

    cmd = ["fzf", "--ansi", "--header-lines=1"]
    table = _format_manual_packages_table(packages, dir)
    result = run(cmd, input=table, stdout=subprocess.PIPE, check=False)
    if result.returncode == 130:  # quit fzf, take no action
        return []

    keys = [line.split()[0].strip().decode() for line in result.stdout.splitlines()]
    return keys


def manual(settings):
    """Set up software that is more manual.

    For example, software that isn't configured with a package manager like
    Homebrew, where an archive needs to be downloaded and unpacked, or a repo
    needs to be checked out from git and a program manually built.
    """
    def create_symlink(dir, relative_path):
        """Create symlink in ~/bin to binary at dir/relative_path"""
        # no funny stuff, also ensures relative_path is a Path
        assert not relative_path.is_absolute(), f"relative path ({relative_path}) can't be absolute"
        frm = Path('~/bin').expanduser() / relative_path.name
        to = setup.root() / dir / relative_path
        run(['symgr', frm, to])

    packages = settings['packages']
    dir = setup.root() / settings['dir']  # directory to download / checkout to
    keys = _get_manual_packages_to_install(packages, dir)

    if not keys:
        return

    log.info(f"Installing packages: {', '.join(keys)}")
    for key in keys:
        log.info(f"Installing: {key}")
        params = packages[key]
        git = params.get('git')  # url of git repository to clone
        tag = params.get('tag')  # tag of git repo to get
        url = params.get('url')  # url of file to download
        cmd = params.get('cmd')  # commands to run after cloning
        bin = params.get('bin')  # path to the executable to install in ~/bin

        # remove if exists
        path = Path(dir, key)
        assert Path.home() in path.parents, f"path ({path}) must be under $HOME"
        if path.exists():
            log.info(f"Deleting existing directory: {path}")
            shutil.rmtree(path)

        # get something
        if any([git, url]):
            c = None  # suppress Pylance "c is possibly unbound" errors
            if git:
                log.info(f"Cloning {git} to {path}")
                c = ['git', 'clone', '--depth', '1', '--recurse-submodules']
                if tag:
                    c += ['--branch', tag]
                c += [git, path]
            if url:
                log.info(f"Downloading {url} to {path}")
                c = ['wget', '--directory-prefix', path, url]

            log.info(f"Running {c}")
            run(c)

        # run any build/extract commands
        if cmd:
            log.info(f"Running {cmd}")
            run_commands(cmd, path)

        # symlink any binaries specified to ~/bin
        if bin:
            # accept either a string or a sequence of strings
            if isinstance(bin, str):
                bin = [bin]

            for b in bin:
                create_symlink(dir, Path(key, b))
