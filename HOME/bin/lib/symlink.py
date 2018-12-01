import datetime
import fnmatch
import logging
import os

log = logging.getLogger(__name__)


def create_symlink(source_path, dest_path):
    log.info(f"Creating symlink of {source_path!r} to {dest_path!r}")
    os.symlink(source_path, dest_path)


def follow_pointer(pointers, dest_dir, file):
    """Return the correct destination path taking pointers into account"""
    # default to the provided dest_dir, otherwise use the pointer
    if file not in pointers:
        return os.path.join(dest_dir, file)

    # if a pointer, should still be within the dest_dir
    dest = os.path.join(dest_dir, pointers[file])
    log.debug(f"Overridden destination for file {file!r} is {dest!r}")
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
    ['~/.config'], the destination is '~/.config/myconfig', expanduser on everything to be safe.

    """
    log.debug(f"Checking if dest path {file!r} is in partials: {partials!r}")
    return file in partials and (os.path.isdir(file) or not os.path.exists(file))


def handle_partials(symlink_settings, repo_path, dest_path):
    """Create symlinks for partial directories"""
    log.debug(f"{dest_path!r} is a partial location, not overwriting")
    # ensure directory exists
    if not os.path.lexists(dest_path):
        log.info(f"Partial directory {dest_path!r} doesn't exist, creating it")
        os.makedirs(dest_path)

    # recurse into it and only create symlinks for files that exist in repo
    create(symlink_settings, repo_path, dest_path)


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
            backup_file(dest_path)


def create(symlink_settings, source_dir, dest_dir):
    """
    For all files and directories within source_dir, symlink them into dest_dir.

    The destination in the dest_dir defaults to its location in the source_dir
    unless it's overridden in symlink_settings['pointers'].

    """
    log.info(f"Creating symlinks: {source_dir} -> {dest_dir}")
    source_dir = os.path.expanduser(source_dir)
    dest_dir = os.path.expanduser(dest_dir)
    pointers = symlink_settings.get('pointers', {})
    ignores = symlink_settings.get('ignores', [])
    partials = symlink_settings.get('partials', [])
    partials = list(map(os.path.expanduser, partials))

    files = os.listdir(source_dir)
    log.debug(f"source_dir is: {source_dir!r}, dest_dir is: {dest_dir!r}")
    for file in files:
        if is_file_ignored(ignores, file):
            log.debug(f"{file!r} is ignored")
            continue

        repo_path = os.path.join(source_dir, file)
        dest_path = follow_pointer(pointers, dest_dir, file)

        log.debug(f"Linking {repo_path!r} to {dest_path!r}")
        if handle_existing_path(partials, repo_path, dest_path):
            # existing symlink pointed where we wanted, or was a partial, nothing to do
            continue

        if is_a_partial_directory(partials, dest_path):
            handle_partials(symlink_settings, repo_path, dest_path)
        else:
            # make sure the parent directory exists for the symlink
            dest_parent_dir = os.path.dirname(dest_path)
            log.debug(f"Ensuring parent directory {dest_parent_dir!r} of dest_path {dest_path!r} exists")
            if not os.path.exists(dest_parent_dir):
                os.makedirs(dest_parent_dir)
            create_symlink(repo_path, dest_path)
