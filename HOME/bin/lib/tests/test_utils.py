import subprocess
import tempfile
from unittest.mock import patch

from lib import utils


EXECUTABLE = '/bin/bash'


def test_run_call_cmd():
    cmd = ['echo', 'hello']
    with patch('lib.utils.subprocess.run') as run:
        utils.run(cmd)

    run.assert_called_with(
        cmd, check=True, shell=False, stdout=None, stderr=None,
        executable=None, input=None, cwd=None, env=None
    )


def test_run_call_shell_cmd():
    cmd = 'echo "hello"'
    with patch('lib.utils.subprocess.run') as run:
        utils.run(cmd)

    run.assert_called_with(
        cmd, check=True, shell=True, stdout=None, stderr=None,
        executable=EXECUTABLE, input=None, cwd=None, env=None
    )


def test_run_call_shell_output():
    cmd = 'echo "hello"'
    with patch('lib.utils.subprocess.run') as run:
        utils.run(cmd, cap=True)

    run.assert_called_with(
        cmd, check=True, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
        executable=EXECUTABLE, input=None, cwd=None, env=None
    )


def test_run_call_shell_input():
    cmd = 'cat'
    input = 'hello'
    with patch('lib.utils.subprocess.run') as run:
        utils.run(cmd, input=input)

    run.assert_called_with(
        cmd, check=True, shell=True, stdout=None, stderr=None,
        executable=EXECUTABLE, input=input.encode(), cwd=None, env=None
    )


def test_run_call_cmd_cap_input():
    cmd = ['cat']
    input = 'hello'
    with patch('lib.utils.subprocess.run') as run:
        utils.run(cmd, cap=True, input=input)

    run.assert_called_with(
        cmd, check=True, shell=False, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
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


def test_read_config():
    values = ['one', 'two', 'three', '#four', '     \t  ', 'five']
    with tempfile.NamedTemporaryFile() as t:
        t.writelines(f'{v}\n'.encode() for v in values)
        t.flush()
        actual = utils.read_config_file(t.name)

    expected = ['one', 'two', 'three', 'five']
    assert actual == expected

def test_read_config_no_comments():
    values = ['one', 'two', 'three', '#four', '     \t  ', 'five']
    with tempfile.NamedTemporaryFile() as t:
        t.writelines(f'{v}\n'.encode() for v in values)
        t.flush()
        actual = utils.read_config_file(t.name, comment=None)

    expected = ['one', 'two', 'three', '#four', 'five']
    assert actual == expected

def test_read_config_with_blanks_and_comments():
    values = ['one', 'two', 'three', '# commented line', 'four', ' ', 'six']
    with tempfile.NamedTemporaryFile() as t:
        t.writelines(f'{v}\n'.encode() for v in values)
        t.flush()
        actual = utils.read_config_file(t.name, comment='#')

    assert actual == ['one', 'two', 'three', 'four', 'six']
