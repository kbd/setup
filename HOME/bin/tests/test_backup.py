from unittest import mock

import _utils

_utils.add_bin_to_path()
backup = _utils.import_executable('bak')

def test_original_file_path_full():
    backup_path = '/path/to/file/foobar.baz.bak.20200314T151234'
    expected = '/path/to/file/foobar.baz'
    actual = backup.original_file_path(backup_path)
    assert expected == actual


def test_original_file_path_filename():
    backup_path = 'foobar.baz.bak.20200314T151234'
    expected = 'foobar.baz'
    actual = backup.original_file_path(backup_path)
    assert expected == actual


def test_original_file_path_multiple_baks():
    backup_path = 'foobar.baz.bak.20200314T151234.bak.20200314T151234'
    expected = 'foobar.baz'
    actual = backup.original_file_path(backup_path)
    assert expected == actual


def test_most_recent_backup_file():
    original_path = 'foobar.baz'
    files = [
        'foobar.baz',
        'foobar.baz.bak.20200314T151234',
        'foobar.baz.bak.20200314T151234.bak.20200314T151234',
        'foobar.baz.bak.20200314T151235',
        'foobar.baz.bak.20200314T151235.bak.20200314T151235',
    ]
    expected = 'foobar.baz.bak.20200314T151235.bak.20200314T151235'
    with mock.patch('os.listdir', return_value=files):
        actual = backup.most_recent_backup_file(original_path)
    assert expected == actual


def test_most_recent_backup_file_not_found():
    original_path = 'foobar.baz'
    files = [
        'foobar.baz',
        'foobar.baz.bak.200200314T151234',
        'foobar.baz.20200314T151234.bak.20200314T151234',
        'fooobar.baz.bak.20200314T151235',
        'foobar.baz.bak.20200314T151235.bak.20200314T1512356',
    ]
    expected = None
    with mock.patch('os.listdir', return_value=files):
        actual = backup.most_recent_backup_file(original_path)
    assert expected == actual
