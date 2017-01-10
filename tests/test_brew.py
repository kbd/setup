import pytest
from unittest.mock import patch

import utils

utils.add_bin_to_path()

from lib import homebrew


def test_install_formula():
    formula = 'myformula'
    with patch('lib.homebrew._execute') as _execute:
        homebrew.install_formula(formula)

    _execute.assert_called_once_with(
        ['brew', 'install', 'myformula']
    )


def test_install_formula_with_arguments():
    formula = ['myformula', '--with-arguments', '--arg=5']
    with patch('lib.homebrew._execute') as _execute:
        homebrew.install_formula(formula)

    _execute.assert_called_once_with(
        ['brew', 'install', 'myformula', '--with-arguments', '--arg=5']
    )
