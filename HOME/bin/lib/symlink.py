import datetime
import logging
import os
from pathlib import Path
from subprocess import run
from typing import Container

from lib.utils import read_lines_from_file


log = logging.getLogger(__name__)

SYSTEM_FILES = ('.git', '.gitignore')

class SymPath(type(Path())):  # type: ignore # https://stackoverflow.com/a/34116756
    def current_link_path(self):
        return self.__class__(os.readlink(self))

    def is_ignored(self):
        """Check if the specified path is in the ignore list"""
        return run(['git', 'check-ignore', '-q', str(self)]).returncode == 0

    def backup(self):
        run(['bak', self])

    def walk(self):
        """Return all files under this directory"""
        for file in self.iterdir():
            p = self / file
            if p.is_dir():
                yield from p.walk()
            else:
                yield p


def link_directories(source_dir, dest_dir):
    """Symlink all files within source_dir into dest_dir."""
    source_dir = SymPath(source_dir).expanduser()
    dest_dir = SymPath(dest_dir).expanduser()
    assert source_dir != dest_dir
    _link_directories(source_dir, dest_dir)


def _link_directories(source_dir, dest_dir):
    """Do the linking without validation or type coercion.

    Useful as an entry-point for tests"""
    log.info(f"Creating symlinks: {source_dir} -> {dest_dir}")
    for file in sorted(source_dir.walk()):
        source_path = file.resolve()  # ensure absolute
        dest_path = dest_dir / file.relative_to(source_dir)

        # don't link files ignored by git
        if source_path.is_ignored():
            log.debug(f"{source_path} is ignored")
            continue
        elif source_path.name in SYSTEM_FILES:
            log.debug(f"Ignoring system file {source_path}")
            continue

        log.debug(f"Creating link at {dest_path} to {source_path}")
        link_file(source_path, dest_path)


def link_file(link_path: Path, dest_path: Path):
    # coerce to SymPaths in case
    link_path = SymPath(link_path)
    dest_path = SymPath(dest_path)
    if link_path.parent.resolve() == dest_path.parent.resolve():
        msg = (
            f"Parent directories being linked point to the same place: "
            f"{link_path.parent} == {dest_path.parent}"
        )
        log.error(msg)
        raise Exception(msg)

    # create parent directories if necessary
    if not dest_path.parent.exists():
        log.info(f"Creating directory: {dest_path.parent}")
        dest_path.parent.mkdir(parents=True)

    # handle existing symlink
    if dest_path.is_symlink():
        log.debug(f"{dest_path} is an existing symlink")
        curr_link_path = dest_path.current_link_path()
        if curr_link_path == link_path:
            # if the link points where we want, leave it alone
            log.debug(f"{dest_path} already points to {link_path}, making no changes")
            return True  # return of True makes it easier to test this case
        else:
            # otherwise remove the wrong-pointing symlink
            log.info(f"{dest_path} points to {curr_link_path}. Removing.")
            dest_path.unlink()
    # back up existing files
    elif dest_path.is_file():
        log.info(f"Existing file at {dest_path}. Backing up.")
        dest_path.backup()

    log.info(f"Creating symlink at {dest_path} to {link_path}")
    dest_path.symlink_to(link_path)
