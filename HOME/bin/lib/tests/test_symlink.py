import pytest
from unittest.mock import create_autospec, patch, call

from lib import symlink


def MockPath(value):
    return create_autospec(symlink.MyPath, name=value, value=value)


def test_create_links():
    source_dir = MockPath('source')
    dest_dir = MockPath('dest')
    source_dir.iterdir.return_value = [
        source_dir / 'one',
        source_dir / 'two',
        source_dir / 'three',
    ]

    with patch('lib.symlink.create_link') as create_link:
        symlink._ready_create_links(source_dir, dest_dir)

    # note it's not actually checking the correct values, since mock -op- value
    # just returns an instance of the mock which compares equal to itself. not
    # sure the right way to do that with mocks, but the test is still useful for
    # now in that it checks some aspects of the calls done.
    calls = [
        call(source_dir / 'one', dest_dir / 'one'),
        call(source_dir / 'two', dest_dir / 'two'),
        call(source_dir / 'three', dest_dir / 'three'),
    ]
    create_link.assert_has_calls(calls)


def test_create_symlink():
    "create_symlink should call os.symlink"
    repo_path = MockPath('repopath')
    dest_path = MockPath('destpath')

    # an un-ignored file in the repo
    repo_path.is_ignored.return_value = False
    repo_path.is_dir.return_value = False

    # no file at destination
    dest_path.is_symlink.return_value = False
    dest_path.is_file.return_value = False
    dest_path.exists.return_value = False

    symlink.create_link(repo_path, dest_path)

    dest_path.symlink_to.assert_called_once_with(repo_path)


def test_create_symlink_existing_correct():
    "An existing, correct, symlink should not be changed"
    repo_path = MockPath('repopath')
    dest_path = MockPath('destpath')

    # an un-ignored file in the repo
    repo_path.is_ignored.return_value = False
    repo_path.is_dir.return_value = False

    # an existing symlink at destination
    dest_path.is_symlink.return_value = True
    dest_path.current_link_path.return_value = repo_path

    returnval = symlink.create_link(repo_path, dest_path)

    assert returnval == True
    dest_path.unlink.assert_not_called()
    dest_path.backup.assert_not_called()


def test_create_symlink_existing_wrong():
    "An existing, incorrect, symlink should be changed"
    repo_path = MockPath('repopath')
    dest_path = MockPath('destpath')

    # an un-ignored file in the repo
    repo_path.is_ignored.return_value = False
    repo_path.is_dir.return_value = False

    # an existing symlink at the destination
    dest_path.is_symlink.return_value = True
    dest_path.exists.return_value = False
    dest_path.current_link_path.return_value = MockPath('someotherpath')

    symlink.create_link(repo_path, dest_path)

    dest_path.unlink.assert_called_once()
    dest_path.symlink_to.assert_called_once_with(repo_path)


def test_create_symlink_ignored():
    "A file ignored in git should not be symlinked"
    repo_path = MockPath('repopath')
    dest_path = MockPath('destpath')

    # an ignored file in the repo
    repo_path.is_ignored.return_value = True

    symlink.create_link(repo_path, dest_path)

    repo_path.is_ignored.assert_called_once()
    dest_path.unlink.assert_not_called()
    dest_path.symlink_to.assert_not_called()


def test_create_symlink_non_existent_dir():
    "A directory at the destination should be created if it doesn't exist"
    repo_path = MockPath('repopath')
    dest_path = MockPath('destpath')

    # un-ignored, directory in repo
    repo_path.is_ignored.return_value = False
    repo_path.is_dir.return_value = True

    # no file at destination
    dest_path.is_symlink.return_value = False
    dest_path.exists.return_value = False
    dest_path.is_dir.return_value = False
    dest_path.is_file.return_value = False

    symlink.create_link(repo_path, dest_path)

    dest_path.unlink.assert_not_called()
    dest_path.backup.assert_not_called()
    dest_path.mkdir.assert_called_once()


def test_create_symlink_partial_dir_existing_file():
    repo_path = MockPath('repopath')
    dest_path = MockPath('destpath')

    # un-ignored dir in repo
    repo_path.is_ignored.return_value = False
    repo_path.is_dir.return_value = True

    # existing file at destination
    dest_path.is_symlink.return_value = False
    dest_path.is_file.return_value = True
    dest_path.exists.return_value = False
    # is_file=True and exists=False works because of the order of things in the code

    symlink.create_link(repo_path, dest_path)

    dest_path.unlink.assert_not_called()
    dest_path.backup.assert_called_once()
    dest_path.mkdir.assert_called_once()
    dest_path.symlink_to.assert_not_called()


def test_create_symlink_partial_dir_existing_dir():
    repo_path = MockPath('repopath')
    dest_path = MockPath('destpath')

    # un-ignored dir in repo
    repo_path.is_ignored.return_value = False
    repo_path.is_dir.return_value = True

    # existing dir at dest
    dest_path.is_symlink.return_value = False
    dest_path.is_file.return_value = False
    dest_path.exists.return_value = True
    dest_path.is_dir.return_value = True

    symlink.create_link(repo_path, dest_path)

    dest_path.unlink.assert_not_called()
    dest_path.backup.assert_not_called()
    dest_path.mkdir.assert_not_called()
    dest_path.symlink_to.assert_not_called()
