import subprocess
from unittest.mock import patch

import _utils

_utils.add_bin_to_path()

from lib import utils


EXECUTABLE = '/bin/bash'


def test_run_call_cmd():
    cmd = ['echo', 'hello']
    with patch('lib.utils.subprocess.run') as run:
        utils.run(cmd)

    run.assert_called_with(cmd, check=True, shell=False, executable=None, stdout=None, input=None)


def test_run_call_shell_cmd():
    cmd = 'echo "hello"'
    with patch('lib.utils.subprocess.run') as run:
        utils.run(cmd)

    run.assert_called_with(cmd, check=True, shell=True, executable=EXECUTABLE, stdout=None, input=None)


def test_run_call_shell_output():
    cmd = 'echo "hello"'
    with patch('lib.utils.subprocess.run') as run:
        utils.run(cmd, cap=True)

    run.assert_called_with(cmd, check=True, shell=True, executable=EXECUTABLE, stdout=subprocess.PIPE, input=None)


def test_run_call_shell_input():
    cmd = 'cat'
    input = 'hello'
    with patch('lib.utils.subprocess.run') as run:
        utils.run(cmd, input=input)

    run.assert_called_with(cmd, check=True, shell=True, executable=EXECUTABLE, stdout=None, input=input.encode())


def test_run_call_cmd_cap_input():
    cmd = ['cat']
    input = 'hello'
    with patch('lib.utils.subprocess.run') as run:
        utils.run(cmd, cap=True, input=input)

    run.assert_called_with(cmd, check=True, shell=False, executable=None, stdout=subprocess.PIPE, input=input.encode())


def test_run_shell_output():
    output = utils.run('echo "hello"', cap=True)
    expected_output = 'hello\n'
    assert output == expected_output


def test_run_shell_input():
    output = utils.run(['cat'], cap=True, input='hello')
    expected_output = 'hello'
    assert output == expected_output

