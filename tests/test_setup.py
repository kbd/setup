import datetime
import os as os_module
import pytest
import sys
import unittest.mock as mock
from importlib.machinery import SourceFileLoader
from os.path import join
from unittest.mock import call, patch

BINPATH = os_module.path.abspath(
    os_module.path.join(os_module.path.dirname(__file__), '../HOME/bin'))
sys.path.append(BINPATH)

from lib import symlink

SOURCE_DIR = '~/setup/HOME'
DEST_DIR = '~'


@pytest.fixture
def symlink_settings():
    return {
        'pointers': {
            'sublime_text': 'Library/Application Support/Sublime Text 3/Packages/User'
        },
        'partials': [
            '~/.config'
        ],
    }


# mock everything in 'os', except use the real os.path.join
@patch('lib.symlink.os', **{'path.join': os_module.path.join})
class TestCreateSymlinks(object):
    def test_create_symlink(self, os):
        "Test that create_symlink correctly calls os.symlink"
        source_path = 'sourcepath'
        dest_path = 'destpath'

        symlink.create_symlink(source_path, dest_path)
        os.symlink.assert_called_with(source_path, dest_path)

    def test_create_symlinks_basic(self, os):
        "Test basic symlink creation. One file, no prior exists"
        symlink_settings = {}
        files = ['.bash_profile']
        os.listdir.return_value = files
        os.path.lexists.return_value = False

        with patch('lib.symlink.create_symlink') as create_symlink:
            symlink.create(symlink_settings, SOURCE_DIR, DEST_DIR)

        create_symlink.assert_called_with(
            join(SOURCE_DIR, files[0]), join(DEST_DIR, files[0]))

    def test_create_symlinks_pointers(self, os, symlink_settings):
        "Test that symlink creation correctly follows pointers"
        os.listdir.return_value = ['sublime_text']
        os.path.lexists.return_value = False

        with patch('lib.symlink.create_symlink') as create_symlink:
            symlink.create(symlink_settings, SOURCE_DIR, DEST_DIR)

        pointers = symlink_settings['pointers']
        create_symlink.assert_called_with(
            join(SOURCE_DIR, 'sublime_text'), join(DEST_DIR, pointers['sublime_text'])
        )

    def test_ignores(self, os):
        "Test that an ignored file is not symlinked"
        symlink_settings = {'ignores': ['.DS_Store']}
        os.listdir.return_value = ['.DS_Store', 'hello']
        os.path.lexists.return_value = True

        with patch('lib.symlink.create_symlink') as create_symlink:
            symlink.create(symlink_settings, SOURCE_DIR, DEST_DIR)

        create_symlink.assert_called_once_with(
            join(SOURCE_DIR, 'hello'), join(DEST_DIR, 'hello'))

    def test_create_symlinks_partials_none_existing(self, os, symlink_settings):
        "Test that symlink creation creates the intermediate directory and then symlinks the file"
        files_within_config = sorted(['myconfig', 'anotherconfig'])
        os.listdir.side_effect = [['.config'], files_within_config]
        os.path.lexists.return_value = False
        with patch('lib.symlink.create_symlink') as create_symlink:
            symlink.create(symlink_settings, SOURCE_DIR, DEST_DIR)

        os.mkdir.assert_called_with('~/.config')

        expected_calls = []
        for file in files_within_config:
            source = join(SOURCE_DIR, '.config', file)
            dest = join(DEST_DIR, '.config', file)
            expected_calls.append(call(source, dest))

        assert create_symlink.mock_calls == expected_calls

    def test_create_symlinks_partials_directory_exists(self, os, symlink_settings):
        "Test that symlink creation creates the intermediate directory and then symlinks the file"
        os.listdir.side_effect = [['.config'], ['myconfig']]
        os.path.lexists.return_value = True
        with patch('lib.symlink.create_symlink') as create_symlink:
            symlink.create(symlink_settings, SOURCE_DIR, DEST_DIR)

        os.mkdir.assert_not_called()

    def test_partial_and_pointer(self, os):
        pass

    def test_get_backup_path(self, os):
        "Test that get_backup_path correctly generates backup paths"
        original_path = '/foo/bar/baz'
        expected_path = '/foo/bar/baz.bak20150101T010101'
        timestamp = datetime.datetime(2015, 1, 1, 1, 1, 1)

        exist_check_count = 0

        def exists(path):
            """Mimic a file-exists check"""
            nonlocal exist_check_count  # noqa
            # first time the file is checked it exists, then it's renamed and no longer exists
            exist_check_count += 1
            return exist_check_count <= 1

        os.path.exists.side_effect = exists
        with patch('lib.symlink.get_current_timestamp', return_value=timestamp):
            new_path = symlink.get_backup_path(original_path)
        assert new_path == expected_path


def test_follow_pointer(symlink_settings):
    pointers = symlink_settings['pointers']
    dest_dir = '/Users/test'

    # no pointer follow
    expected = os_module.path.join(dest_dir, 'myfile')
    actual = symlink.follow_pointer(pointers, dest_dir, 'myfile')
    assert actual == expected

    # pointer follow
    expected = os_module.path.join(dest_dir, pointers['sublime_text'])
    actual = symlink.follow_pointer(pointers, dest_dir, 'sublime_text')
    assert actual == expected
