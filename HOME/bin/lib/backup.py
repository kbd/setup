import datetime
import logging
import re
import os
import shutil

log = logging.getLogger(__name__)


BACKUP_FORMAT = ".{ext}.{ts}"
EXTENSION = 'bak'


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

        path += BACKUP_FORMAT.format(ext=EXTENSION, ts=ts)

    return path


def get_original_file_path(path):
    bak = BACKUP_FORMAT.format(ext=EXTENSION, ts=r'\d{8}T\d{6}').replace('.', r'\.')
    regex = rf'^(.*?)(?:{bak})+$'
    return re.sub(regex, r'\1', path)


def find_backup_files(original, files):
    return [f for f in files if re.match(re.escape(original)+r'(?:\.bak\.\d{8}T\d{6})+$', f)]


def get_most_recent_backup_file_for_file(original_path):
    """Find the path of the most recent backed up file"""
    files = os.listdir(os.path.dirname(os.path.abspath(original_path)))
    return get_most_recent_backup_file(original_path, files)


def get_most_recent_backup_file(original_path, files):
    # find files starting with the original path that match the backup pattern
    # out of those files, pick the most recent timestamp.
    # The date format sorts properly, so no need to actually parse the dates.
    backup_files = find_backup_files(original_path, files)
    if not backup_files:
        return None

    length_of_timestamp = 8+1+6
    backup_files.sort(key=lambda x: x[-length_of_timestamp:], reverse=True)
    return backup_files[0]


def move_file(from_path, to_path, keep=False):
    action = 'Copying' if keep else 'Moving'
    log.info(f"{action} {from_path!r} to {to_path!r}")
    if keep:
        func = shutil.copytree if os.path.isdir(from_path) else shutil.copy2
        func(from_path, to_path)
    else:
        os.rename(from_path, to_path)


def backup_file(path, keep=False):
    backup_path = get_backup_path(path)
    move_file(path, backup_path, keep)
    return backup_path
