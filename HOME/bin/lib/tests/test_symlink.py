import pytest
from unittest.mock import create_autospec

from lib import symlink


def MockPath(value):
    return create_autospec(symlink.MyPath, name=value, value=value)


def test_create_symlink():
    "Test that create_symlink correctly calls os.symlink"
    repo_path = MockPath('repopath')
    dest_path = MockPath('destpath')
    repo_path.is_ignored.return_value = False
    dest_path.is_symlink.return_value = False
    dest_path.exists.return_value = False

    symlink.create_link(repo_path, dest_path, partials={})

    dest_path.symlink_to.assert_called_once_with(repo_path)


def test_create_symlink_existing_correct():
    repo_path = MockPath('repopath')
    dest_path = MockPath('destpath')
    repo_path.is_ignored.return_value = False
    dest_path.is_symlink.return_value = True
    dest_path.current_link_path.return_value = repo_path

    returnval = symlink.create_link(repo_path, dest_path, partials={})

    assert returnval == True
    dest_path.unlink.assert_not_called()
    dest_path.backup.assert_not_called()


def test_create_symlink_existing_wrong():
    repo_path = MockPath('repopath')
    dest_path = MockPath('destpath')
    repo_path.is_ignored.return_value = False
    dest_path.is_symlink.return_value = True
    dest_path.exists.return_value = False
    dest_path.current_link_path.return_value = MockPath('someotherpath')

    symlink.create_link(repo_path, dest_path, partials={})

    dest_path.unlink.assert_called_once()
    dest_path.symlink_to.assert_called_once_with(repo_path)


def test_create_symlink_ignored():
    repo_path = MockPath('repopath')
    dest_path = MockPath('destpath')
    repo_path.is_ignored.return_value = True

    symlink.create_link(repo_path, dest_path, partials={})

    repo_path.is_ignored.assert_called_once()
    dest_path.unlink.assert_not_called()
    dest_path.symlink_to.assert_not_called()


def test_create_symlink_existing_dir():
    repo_path = MockPath('repopath')
    dest_path = MockPath('destpath')
    repo_path.is_ignored.return_value = False
    repo_path.is_dir.return_value = True
    dest_path.is_symlink.return_value = False
    dest_path.is_dir.return_value = True

    symlink.create_link(repo_path, dest_path, partials={})

    dest_path.unlink.assert_not_called()
    dest_path.backup.assert_called_once()
    dest_path.symlink_to.assert_called_once_with(repo_path)


def test_create_symlink_partial_dir_existing_file():
    repo_path = MockPath('repopath')
    dest_path = MockPath('destpath')
    repo_path.is_ignored.return_value = False
    repo_path.is_dir.return_value = True
    dest_path.is_symlink.return_value = False
    dest_path.is_file.return_value = True
    dest_path.exists.return_value = False
    # is_file=True and exists=False works because of the order of things in the code

    partials = {MockPath('otherpath'), dest_path}
    symlink.create_link(repo_path, dest_path, partials=partials)

    dest_path.unlink.assert_not_called()
    dest_path.backup.assert_called_once()
    dest_path.mkdir.assert_called_once()
    dest_path.symlink_to.assert_not_called()


def test_create_symlink_partial_dir_existing_dir():
    repo_path = MockPath('repopath')
    dest_path = MockPath('destpath')
    repo_path.is_ignored.return_value = False
    repo_path.is_dir.return_value = True
    dest_path.is_symlink.return_value = False
    dest_path.is_file.return_value = False
    dest_path.exists.return_value = True
    dest_path.is_dir.return_value = True

    partials = {MockPath('otherpath'), dest_path}
    symlink.create_link(repo_path, dest_path, partials=partials)

    dest_path.unlink.assert_not_called()
    dest_path.backup.assert_not_called()
    dest_path.mkdir.assert_not_called()
    dest_path.symlink_to.assert_not_called()


def test_create_symlink_partial_file():
    repo_path = MockPath('repopath')
    dest_path = MockPath('destpath')
    repo_path.is_ignored.return_value = False
    repo_path.is_dir.return_value = False
    repo_path.is_file.return_value = True
    dest_path.is_symlink.return_value = False
    dest_path.is_file.return_value = True

    partials = {MockPath('otherpath'), dest_path}

    with pytest.raises(Exception):
        symlink.create_link(repo_path, dest_path, partials=partials)

    dest_path.unlink.assert_not_called()
    dest_path.backup.assert_not_called()
    dest_path.mkdir.assert_not_called()
    dest_path.symlink_to.assert_not_called()
