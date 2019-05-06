import datetime
import fnmatch
import logging
import os
from pathlib import Path
from subprocess import run


log = logging.getLogger(__name__)


def create_symlink(source_path, dest_path):
    log.info(f"Creating symlink of {source_path!r} to {dest_path!r}")
    os.symlink(source_path, dest_path)


def is_file_ignored(path):
    """Check if the specified path is in the ignore list"""
    return run(['git', 'check-ignore', '-q', path]).returncode == 0


def is_a_partial_directory(partials, file):
    """
    Check if file is a partial.

    'partials' is a list of *directories* that are partials.

    This needs to check if the given destination path is within the partial directory.
    For example, if the file to symlink is '~/setup/HOME/.config/myconfig' and partials is
    ['~/.config'], the destination is '~/.config/myconfig', expanduser on everything to be safe.

    """
    log.debug(f"Checking if dest path {file!r} is in partials: {partials!r}")
    return file in partials and (os.path.isdir(file) or not os.path.exists(file))


def handle_partials(repo_path, dest_path, partials):
    """Create symlinks for partial directories"""
    log.debug(f"{dest_path!r} is a partial location, not overwriting")
    # ensure directory exists
    if not os.path.lexists(dest_path):
        log.info(f"Partial directory {dest_path!r} doesn't exist, creating it")
        os.makedirs(dest_path)

    # recurse into it and only create symlinks for files that exist in repo
    # todo: this recursion is wasteful, try to clean up later
    create(repo_path, dest_path, partials)


def handle_existing_symlink(repo_path, dest_path):
    """
    Remove existing symlink if it doesn't point where we want.

    Return True if there's nothing left to do.

    """
    prior_symlink = os.readlink(dest_path)
    if prior_symlink == repo_path:
        log.debug(f"{dest_path!r} already points where we want, making no changes")
        return True
    else:
        log.info(f"Symlink at {dest_path!r} points to {prior_symlink!r}. Removing existing symlink")
        os.remove(dest_path)


def backup_file(path):
    backup_path = path.rstrip('/')  # strip trailing slash in case of directory
    ts = datetime.datetime.now().strftime('%Y%m%dT%H%M%S')
    while os.path.exists(backup_path):  # keep adding to filename until it doesn't exist
        backup_path = backup_path + '.bak.' + ts

    os.rename(path, backup_path)
    return backup_path


def handle_existing_path(partials, repo_path, dest_path):
    "Handle existing symlink, return True if there's nothing left to do."
    if os.path.lexists(dest_path):
        log.debug(f"Path {dest_path!r} already exists")
        if os.path.islink(dest_path):
            return handle_existing_symlink(repo_path, dest_path)
        elif is_a_partial_directory(partials, dest_path):
            log.debug(f"{dest_path!r} is a partial, not backing up")
        else:
            log.debug("Backing up existing file")
            backup_file(dest_path)


def preprocess_partials(partials):
    # if any of the partials is a path and not just a directory, each
    # component of the path is also a partial. I.e. if the partial is:
    # '~/Library/Application Support/.../User', it wouldn't make sense
    # for .../User to be a partial and the dirs before it to not be.

    # partials should start with the home directory (~), so a partial that
    # doesn't need special handling has length 2. Any longer and you need to
    # ensure that the parts in-between are also partials
    paths_to_add = set()
    for p in partials:
        parts = Path(p).parts
        if len(parts) <= 2:
            continue

        for i in range(2, len(parts)):
            partial_path = Path(*parts[:i])
            paths_to_add.add(partial_path)

    log.debug(f"Adding intermediate paths to partials: {list(map(str, paths_to_add))}")
    partials = set(map(os.path.expanduser, set(partials) | paths_to_add))
    return partials


def create(source_dir, dest_dir, partials):
    """
    For all files and directories within source_dir, symlink them into dest_dir.
    """
    log.info(f"Creating symlinks: {source_dir} -> {dest_dir}")
    source_dir = os.path.expanduser(source_dir)
    dest_dir = os.path.expanduser(dest_dir)
    partials = preprocess_partials(partials)

    files = os.listdir(source_dir)
    log.debug(f"source_dir is: {source_dir!r}, dest_dir is: {dest_dir!r}")
    for file in files:
        repo_path = os.path.join(source_dir, file)
        if is_file_ignored(repo_path):
            log.debug(f"{repo_path!r} is ignored")
            continue

        dest_path = os.path.join(dest_dir, file)

        log.debug(f"Linking {repo_path!r} to {dest_path!r}")
        if handle_existing_path(partials, repo_path, dest_path):
            # existing symlink pointed where we wanted, or was a partial, nothing to do
            continue

        if is_a_partial_directory(partials, dest_path):
            handle_partials(repo_path, dest_path, partials)
        else:
            # make sure the parent directory exists for the symlink
            dest_parent_dir = os.path.dirname(dest_path)
            log.debug(f"Ensuring parent directory {dest_parent_dir!r} of dest_path {dest_path!r} exists")
            if not os.path.exists(dest_parent_dir):
                os.makedirs(dest_parent_dir)

            create_symlink(repo_path, dest_path)
