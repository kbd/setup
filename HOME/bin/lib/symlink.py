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


def backup_file(path):
    backup_path = path.rstrip('/')  # strip trailing slash in case of directory
    ts = datetime.datetime.now().strftime('%Y%m%dT%H%M%S')
    while os.path.exists(backup_path):  # keep adding to filename until it doesn't exist
        backup_path = backup_path + '.bak.' + ts

    os.rename(path, backup_path)
    return backup_path


def preprocess_partials(partial_paths):
    """Expand partials as-specified-in-the-config to what we need in code.

    Background: The difference between a "partial" directory and a regular one
    is that a regular directory is symlinked, whereas only the *contents* of a
    partial directory are symlinked. A regular directory is under full contol of
    setup, while a partial directory is only partially under control of setup.
    For a partial directory, the directory as a whole is not under source
    control, only specific files within it.

    Unfortunately, it can't be obvious when a directory is in source control
    under (eg) HOME/a/b/c where we want to "start source controlling". It could
    be a, b, or c. It's something that needs to be configured.


    The config specifies a full absolute path, ~/a/b/c. Having a sub-directory
    that is a partial logically implies that directories above it are partials
    as well. So `preprocess_partials` expands the list of partial directories
    into the set of all parent directories up to and including the partial
    directory. That way it's a simple set membership test to determine whether a
    given path is a partial.
    """
    # for all partials, make sure all parents are in partials
    # original_partials = {Path(p).expanduser() for p in partial_paths}
    # return set(*({p, *p.parents} for p in original_partials))

    original_partials = {Path(p).expanduser() for p in partial_paths}
    all_partials = original_partials.copy()
    for p in original_partials:
        all_partials |= set(p.parents)

    return all_partials


def create(source_dir, dest_dir, partials):
    """
    For all files and directories within source_dir, symlink them into dest_dir.
    """
    source_dir = Path(source_dir).expanduser()
    dest_dir = Path(dest_dir).expanduser()
    log.info(f"Creating symlinks: {source_dir} -> {dest_dir}")
    partials = preprocess_partials(partials)

    files = os.listdir(source_dir)
    log.debug(f"source_dir is: {source_dir!r}, dest_dir is: {dest_dir!r}")
    for file in files:
        repo_path = source_dir / file
        dest_path = dest_dir / file
        if is_file_ignored(repo_path):
            log.debug(f"{repo_path!r} is ignored")
            continue

        if os.path.lexists(dest_path):
            log.debug(f"Path {dest_path!r} already exists")
            if os.path.islink(dest_path):
                curr_link_path = os.readlink(dest_path)
                if curr_link_path == repo_path:
                    log.debug(f"{dest_path!r} already points where we want, making no changes")
                    continue
                else:
                    log.info(f"Symlink at {dest_path!r} points to {curr_link_path!r}. Removing existing symlink")
                    os.remove(dest_path)
            elif dest_path in partials:
                log.debug(f"{dest_path!r} is a partial, not backing up")
            else:
                log.debug("Backing up existing file")
                backup_file(dest_path)

        log.debug(f"Linking {repo_path!r} to {dest_path!r}")
        if dest_path in partials:
            log.debug(f"{dest_path!r} is a partial")
            # ensure directory exists
            if not os.path.lexists(dest_path):
                log.info(f"Partial directory {dest_path!r} doesn't exist, creating it")
                os.makedirs(dest_path)

            # recurse into it and only create symlinks for files that exist in repo
            # todo: this recursion is a bit wasteful, try to clean up later
            create(repo_path, dest_path, partials)
        else:
            # make sure the parent directory exists for the symlink
            log.debug(f"Ensuring parent directory {dest_path.parent!r} of dest_path {dest_path!r} exists")
            if not dest_path.parent.exists():
                dest_path.parent.mkdir(parents=True)

            create_symlink(repo_path, dest_path)
