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
        run(['bak', self])


def create_links(source_dir, dest_dir):
    """Symlink all files and directories within source_dir into dest_dir."""
    source_dir = MyPath(source_dir).expanduser()
    dest_dir = MyPath(dest_dir).expanduser()
    assert source_dir != dest_dir
    log.info(f"Creating symlinks: {source_dir} -> {dest_dir}")
    _ready_create_links(source_dir, dest_dir)


def _ready_create_links(source_dir, dest_dir):
    """Does the work of create_links. Assumes partials have been pre-processed
    and user dirs expanded.
    """
    log.debug(f"source_dir is: {source_dir!r}, dest_dir is: {dest_dir!r}")
    for file in source_dir.iterdir():
        name = file.name
        repo_path = source_dir / name
        dest_path = dest_dir / name
        create_link(repo_path, dest_path)


def create_link(repo_path, dest_path):
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
    # back up existing files
    elif dest_path.is_file():
        log.info(f"Existing file at {dest_path}. Backing up.")
        dest_path.backup()

    # recurse into subdirectories, ensuring they exist
    if repo_path.is_dir():
        if not dest_path.exists():
            log.info(f"Creating {dest_path}")
            dest_path.mkdir(parents=True)

        return _ready_create_links(repo_path, dest_path)
    else:  # create single symlink
        log.info(f"Creating symlink to {repo_path} at {dest_path}")
        dest_path.symlink_to(repo_path)
