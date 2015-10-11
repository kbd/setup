import datetime
import fnmatch
import os
from pathlib import Path

import logging

log = logging.getLogger(__name__)


def get_current_timestamp():
    return datetime.datetime.now()


def get_current_timestamp_str():
    return get_current_timestamp().strftime('%Y%m%dT%H%M%S')


def get_backup_path(path):
    """
    Create a backup path given path. Use case is that a file exists at path and
    you want to rename it to (a non-existent) backup path. Obviously there's a
    small race condition (where a file is created at the backup path you
    specify before you move the file there but after this determines the backup
    path), but that's not worth handling.

    """
    d = get_current_timestamp_str()

    while os.path.exists(path):  # keep adding to filename until you get a non-existent one
        # strip a trailing slash so you don't create something like foo/.bak...
        if path[-1] == '/':
            path = path[:-1]

        path += '.bak' + d

    return path


def create_symlink(source_path, dest_path):
    log.info("Creating symlink of {!r} to {!r}".format(source_path, dest_path))
    os.symlink(source_path, dest_path)


def back_up_existing_file(dest_path):
    backup_path = get_backup_path(dest_path)
    log.info("Backing up {!r} to {!r}".format(dest_path, backup_path))
    os.rename(dest_path, backup_path)


def remove_existing_symlink(repo_path, dest_path):
    prior_symlink = os.readlink(dest_path)
    if prior_symlink == repo_path:
        log.debug("{!r} already points where we want, making no changes".format(dest_path))
    else:
        log.info("Symlink at {!r} points to {!r}. Removing existing symlink".format(
            dest_path, prior_symlink))
        os.remove(dest_path)


def follow_pointer(pointers, dest_dir, file):
    """Return the correct destination path taking pointers into account"""
    # default to the provided dest_dir, otherwise use the pointer
    if file not in pointers:
        return os.path.join(dest_dir, file)

    # if a pointer, should still be within the dest_dir
    dest = os.path.join(dest_dir, pointers[file])
    log.debug("Overridden destination for file {!r} is {!r}".format(file, dest))
    return dest


def is_file_ignored(ignores, file):
    """Check if the specified file is in the ignore list"""
    return any(fnmatch.fnmatch(file, ignore) for ignore in ignores)


def is_a_partial_directory(partials, file):
    """
    Check if file is a partial.

    'partials' is a list of *directories* that are partials.

    This needs to check if the given destination path is within the partial directory.
    For example, if the file to symlink is '~/setup/HOME/.config/myconfig' and partials is
    ['~/.config'], the destination is '~/.config/myconfig', expanduser on everything to be safe,

    """
    return os.path.isdir(file) and file in partials


def handle_partials(symlink_settings, repo_path, dest_path):
    """Create symlinks for partial directories"""
    log.info("{!r} is a partial location, not overwriting".format(dest_path))
    # ensure directory exists
    if not os.path.lexists(dest_path):
        log.debug("Partial directory {!r} doesn't exist, creating it".format(dest_path))
        os.mkdir(dest_path)

    # recurse into it and only create symlinks for files that exist in repo
    create(symlink_settings, repo_path, dest_path)


def create(symlink_settings, source_dir, dest_dir):
    """
    For all files and directories within source_dir, symlink them into dest_dir.

    The destination in the dest_dir defaults to its location in the source_dir
    unless it's overridden in symlink_settings['pointers'].

    """
    pointers = symlink_settings.get('pointers', {})
    ignores = symlink_settings.get('ignores', [])
    partials = symlink_settings.get('partials', [])

    files = os.listdir(source_dir)
    log.debug("source_dir is: {!r}, dest_dir is: {!r}".format(source_dir, dest_dir))
    for file in files:
        if is_file_ignored(ignores, file):
            log.debug("{!r} is ignored".format(file))
            continue

        repo_path = os.path.join(source_dir, file)
        dest_path = follow_pointer(pointers, dest_dir, file)
        log.debug("Linking {!r} to {!r}".format(repo_path, dest_path))
        if os.path.lexists(dest_path):
            log.debug("Path {!r} already exists".format(dest_path))
            if os.path.islink(dest_path):
                remove_existing_symlink(repo_path, dest_path)
            else:
                back_up_existing_file(dest_path)

        log.info("Checking if dest path {!r} is in partials: {!r}".format(dest_path, partials))
        if is_a_partial_directory(partials, dest_path):
            handle_partials(symlink_settings, repo_path, dest_path)
        else:
            create_symlink(repo_path, dest_path)
