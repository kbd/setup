import subprocess
from unittest.mock import patch

from lib import utils


EXECUTABLE = '/bin/bash'


def test_run_call_cmd():
    cmd = ['echo', 'hello']
    with patch('lib.utils.subprocess.run') as run:
        utils.run(cmd)

    run.assert_called_with(
        cmd, check=True, shell=False, stdout=None,
        executable=None, input=None, cwd=None, env=None
    )


def test_run_call_shell_cmd():
    cmd = 'echo "hello"'
    with patch('lib.utils.subprocess.run') as run:
        utils.run(cmd)

    run.assert_called_with(
        cmd, check=True, shell=True, stdout=None,
        executable=EXECUTABLE, input=None, cwd=None, env=None
    )


def test_run_call_shell_output():
    cmd = 'echo "hello"'
    with patch('lib.utils.subprocess.run') as run:
        utils.run(cmd, cap=True)

    run.assert_called_with(
        cmd, check=True, shell=True, stdout=subprocess.PIPE,
        executable=EXECUTABLE, input=None, cwd=None, env=None
    )


def test_run_call_shell_input():
    cmd = 'cat'
    input = 'hello'
    with patch('lib.utils.subprocess.run') as run:
        utils.run(cmd, input=input)

    run.assert_called_with(
        cmd, check=True, shell=True, stdout=None,
        executable=EXECUTABLE, input=input.encode(), cwd=None, env=None
    )


def test_run_call_cmd_cap_input():
    cmd = ['cat']
    input = 'hello'
    with patch('lib.utils.subprocess.run') as run:
        utils.run(cmd, cap=True, input=input)

    run.assert_called_with(
        cmd, check=True, shell=False, stdout=subprocess.PIPE,
        executable=None, input=input.encode(), cwd=None, env=None
    )


def test_run_shell_output():
    output = utils.run('echo "hello"', cap=True)
    expected_output = 'hello\n'
    assert output == expected_output


def test_run_shell_input():
    output = utils.run(['cat'], cap=True, input='hello')
    expected_output = 'hello'
    assert output == expected_output
