import datetime
import fnmatch
import logging
import os
from pathlib import Path
from subprocess import run


log = logging.getLogger(__name__)


def is_file_ignored(path):
    """Check if the specified path is in the ignore list"""
    return run(['git', 'check-ignore', '-q', path]).returncode == 0


def backup_file(path):
    ts = datetime.datetime.now().strftime('%Y%m%dT%H%M%S')
    suffix = '.bak.' + ts
    backup_path = path.with_suffix(suffix)
    while backup_path.exists():  # keep adding to filename until it doesn't exist
        suffix += suffix
        backup_path = backup_path.with_suffix(suffix)

    path.rename(backup_path)
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

    log.debug(f"source_dir is: {source_dir!r}, dest_dir is: {dest_dir!r}")
    breakpoint()
    for file in source_dir.iterdir():
        repo_path = source_dir / file
        dest_path = dest_dir / file
        if is_file_ignored(repo_path):
            log.debug(f"{repo_path!r} is ignored")
            continue

        # if the file exists...
        if os.path.lexists(dest_path):
            log.debug(f"Path {dest_path!r} already exists")
            # and it's already a symlink
            if dest_path.is_symlink():
                curr_link_path = Path(os.readlink(dest_path))
                # and the link points where we want
                if curr_link_path == repo_path:
                    # leave it alone
                    log.debug(f"{dest_path!r} already points where we want, making no changes")
                    continue
                else:
                    # otherwise remove the wrong-pointing symlink
                    log.info(f"Symlink at {dest_path!r} points to {curr_link_path!r}. Removing existing symlink")
                    dest_path.unlink()
            # if it's not a symlink and not in partials, back up existing file
            elif dest_path not in partials:
                log.debug(f"Backing up existing file at {dest_path}")
                backup_file(dest_path)

        # at this point there should be nothing at the destination
        log.debug(f"Linking {repo_path!r} to {dest_path!r}")
        if dest_path in partials:
            log.debug(f"{dest_path!r} is a partial, ensuring it exists")
            dest_path.mkdir(parents=True, exist_ok=True)
            # since this is for a partial, recurse into it and continue linking
            create(repo_path, dest_path, partials)
        else:
            # not necessary for us to ensure parent directory exists because
            # if we got here we're either at the root of where we're creating
            # i.e. $HOME, or the directory will have been created while
            # recursing through the prior branch
            log.info(f"Creating symlink of {repo_path!r} to {dest_path!r}")
            dest_path.symlink_to(repo_path)
