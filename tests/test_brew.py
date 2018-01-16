from unittest.mock import patch, DEFAULT

import pytest

import _utils

_utils.add_bin_to_path()

from lib import homebrew


def test_install_formula():
    formula = 'myformula'
    with patch('lib.homebrew.run') as run:
        homebrew.install_formula(formula)

    run.assert_called_once_with(
        ['brew', 'install', 'myformula']
    )


def test_install_formula_with_arguments():
    formula = ['myformula', '--with-arguments', '--arg=5']
    with patch('lib.homebrew.run') as run:
        homebrew.install_formula(formula)

    run.assert_called_once_with(
        ['brew', 'install', 'myformula', '--with-arguments', '--arg=5']
    )


def test_cleanup_formulas():
    fake_cache_location = '/Users/test_user/Library/Caches/Homebrew'
    with patch.multiple('lib.homebrew',
        get_space_used=DEFAULT, run=DEFAULT, delete_dir=DEFAULT, brew_cache=lambda: fake_cache_location
    ) as patches:
        homebrew.cleanup_formulas()

    patches['get_space_used'].assert_called_with(fake_cache_location)
    patches['delete_dir'].assert_called_with(fake_cache_location)


def test_cleanup_formulas_bad_cache_dir():
    fake_cache_location = '/Users/test_user/Library/'

    with pytest.raises(Exception, match="doesn't match pattern"):
        with patch.multiple('lib.homebrew',
            run=DEFAULT, brew_cache=lambda: fake_cache_location
        ) as patches:
            homebrew.cleanup_formulas()


def test_homebrew_not_installed():
    cmd = '/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"'
    with patch.multiple(homebrew, is_installed=lambda: False, run=DEFAULT) as patches:
        homebrew.ensure_homebrew_installed()
    patches['run'].assert_called_once_with(cmd)


def test_ensure_homebrew_installed():
    with patch.multiple(homebrew, is_installed=lambda: True, run=DEFAULT) as patches:
        homebrew.ensure_homebrew_installed()
    patches['run'].assert_not_called()
