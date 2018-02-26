import datetime
import logging
import os
import shutil

log = logging.getLogger(__name__)


BACKUP_FORMAT = ".{ext}.{ts}"


def get_current_timestamp():
    return datetime.datetime.now()


def get_current_timestamp_str():
    return get_current_timestamp().strftime('%Y%m%dT%H%M%S')


def get_backup_path(path, format=BACKUP_FORMAT):
    """
    Create a backup path given path. Use case is that a file exists at path and
    you want to rename it to (a non-existent) backup path. Obviously there's a
    small race condition (where a file is created at the backup path you
    specify before you move the file there but after this determines the backup
    path), but that's not worth handling.

    'format' is a string that will be formatted, filling in the
    'ext' (extension) and 'ts' (timestamp) values.

    """
    ts = get_current_timestamp_str()

    while os.path.exists(path):  # keep adding to filename until you get a non-existent one
        # strip a trailing slash so you don't create something like foo/.bak...
        if path[-1] == '/':
            path = path[:-1]

        path += BACKUP_FORMAT.format(ext='bak', ts=ts)

    return path


def back_up_existing_file(path, keep=False):
    backup_path = get_backup_path(path)
    log.info(f"Backing up {path!r} to {backup_path!r}")
    if keep:
        shutil.copy2(path, backup_path)
    else:
        os.rename(path, backup_path)

    return backup_path
