import datetime
import logging
import os
from pathlib import Path
from subprocess import run
from typing import Container

from lib.utils import read_lines_from_file


log = logging.getLogger(__name__)


class MyPath(type(Path())):  # type: ignore # https://stackoverflow.com/a/34116756
    def current_link_path(self):
        return self.__class__(os.readlink(self))

    def is_ignored(self):
        """Check if the specified path is in the ignore list"""
        return run(['git', 'check-ignore', '-q', str(self)]).returncode == 0

    def backup(self):
        ts = datetime.datetime.now().strftime('%Y%m%dT%H%M%S')
        suffix = '.bak.' + ts
        i = 1
        while True:  # keep adding to filename until a path is free
            backup_path = self.with_suffix(self.suffix + suffix * i)
            if not backup_path.exists():
                break
            i += 1

        self.rename(backup_path)
        return backup_path


class Partials:
    def __init__(self, path):
        self.path = path
        self.source = read_lines_from_file(path)
        self.process()  # assigns self.paths

    def __contains__(self, value):
        return value in self.paths

    def __repr__(self):
        return f"{self.__class__.__name__}({', '.join(self.source)})"

    def add(self, path):
        log.info(f"Adding {str(path)!r} to partials")
        self.source = sorted(set(self.source + [str(path)]))  # ensure no dupes
        self.process()

    def save(self):
        log.info(f"Writing partials to {str(self.path)!r}")
        with open(self.path, 'w') as f:
            f.writelines(f"{line}\n" for line in self.source)

    def process(self):
        self.paths = self._process(self.source)

    @staticmethod
    def _process(partial_paths):
        """Expand partials as-specified-in-the-config to what we need in code.

        Background: The difference between a "partial" directory and a regular
        one is that a regular directory is symlinked, whereas only the
        *contents* of a partial directory are symlinked. A regular directory is
        under full contol of setup, while a partial directory is only partially
        under control of setup. For a partial directory, the directory as a
        whole is not under source control, only specific files within it.

        Unfortunately, it can't be obvious when a directory is in source control
        under (eg) HOME/a/b/c where we want to "start source controlling". It
        could be a, b, or c. It's something that needs to be configured.

        ---

        The config specifies a full absolute path, ~/a/b/c. Having a
        sub-directory that is a partial logically implies that directories above
        it are partials as well. So this expands the list of partial directories
        into the set of all parent directories up to and including the partial
        directory. That way it's a simple set membership test to determine
        whether a given path is a partial.
        """
        original_partials = {MyPath(p).expanduser() for p in partial_paths}
        all_partials = original_partials.copy()
        for p in original_partials:
            all_partials |= set(p.parents)

        return all_partials


def create_links(source_dir, dest_dir, partials):
    """Symlink all files and directories within source_dir into dest_dir."""
    source_dir = MyPath(source_dir).expanduser()
    dest_dir = MyPath(dest_dir).expanduser()
    assert source_dir != dest_dir
    log.info(f"Creating symlinks: {source_dir} -> {dest_dir}")
    _ready_create_links(source_dir, dest_dir, partials)


def _ready_create_links(source_dir, dest_dir, partials):
    """Does the work of create_links. Assumes partials have been pre-processed
    and user dirs expanded.
    """
    log.debug(f"source_dir is: {source_dir!r}, dest_dir is: {dest_dir!r}")
    for file in source_dir.iterdir():
        name = file.name
        repo_path = source_dir / name
        dest_path = dest_dir / name
        create_link(repo_path, dest_path, partials)


def create_link(repo_path, dest_path, partials: Container[Path]):
    log.debug(f"Creating link from {dest_path} to {repo_path}.")
    # respect ignored files
    if repo_path.is_ignored():
        log.debug(f"{repo_path} is ignored.")
        return

    # handle existing symlink
    if dest_path.is_symlink():
        log.debug(f"{dest_path} is an existing symlink.")
        curr_link_path = dest_path.current_link_path()
        if curr_link_path == repo_path:
            # if the link points where we want, leave it alone
            log.debug(f"{dest_path} already points to {repo_path}, making no changes.")
            return True  # return of True makes it easier to test this case
        else:
            # otherwise remove the wrong-pointing symlink
            log.info(f"{dest_path} points to {curr_link_path}. Removing.")
            dest_path.unlink()

    exists_msg = f"Existing file at {dest_path}. Backing up."
    # handle partial directories
    if dest_path in partials:
        if not repo_path.is_dir():
            # sanity check
            msg = f"Error in config: {dest_path} is specified as a partial but {repo_path} is a file"
            log.error(msg)
            raise Exception(msg)

        log.debug(f"{dest_path} is a partial directory")
        # if it's a file, back it up. Otherwise, ensure the dir exists
        if dest_path.is_file():
            log.info(exists_msg)
            dest_path.backup()

        if not dest_path.exists():
            log.info(f"Creating {dest_path}")
            dest_path.mkdir(parents=True)

        return _ready_create_links(repo_path, dest_path, partials)

    # everything else is a file or dir that should be symlinked
    if dest_path.exists():
        log.info(exists_msg)
        dest_path.backup()

    log.info(f"Creating symlink to {repo_path} at {dest_path}")
    dest_path.symlink_to(repo_path)
