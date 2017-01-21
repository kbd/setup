#!/user/bin/env python3

"""Test clipboard utility 'cb'.

Run with nose or pytest -s (because 'cb' requires normal system fds).
"""

import inspect
import tempfile
from subprocess import check_call as cc, check_output as co

CB = 'cb'

# get and set clipboard utility functions. These depend on cb behavior being
# correct in the first place, but could potentially be replaced with an
# independent method
def set_clipboard(test_str):
    cc([CB, test_str])


def get_clipboard():
    return co(CB).decode()


def call(cmd):
    args = {'shell': True, 'executable': 'bash'} if isinstance(cmd, str) else {}
    return co(cmd, **args).decode()


def test_default():
    """Test default usage.

    Example:
        "foo" is in clipboard
        $ cb
        foo
    """
    test_str = 'foo'
    set_clipboard(test_str)
    result = call(CB)
    assert result == test_str


def test_pipe_set():
    """Test setting clipboard with value piped to cb.

    Example:
        $ echo bar | cb
        $ cb
        bar
    """
    test_str = 'bar'
    call(f'echo -n "{test_str}" | {CB}')
    result = get_clipboard()
    assert result == test_str


def test_pipe_get():
    """Test getting clipboard with value piped from cb.

    Example:
        $ cb | cat
        $ cb
        bar
    """
    test_str = 'bar'
    set_clipboard(test_str)
    result = call(f'{CB} | cat')
    assert result == test_str


def test_argument_set():
    """Test setting clipboard with an argument.

    Example:
        $ cb baz
        $ cb
        baz
    """
    test_str = 'baz'
    call(f'{CB} {test_str}')
    result = get_clipboard()
    assert result == test_str


def test_set_with_redirect():
    """Test setting clipboard with file redirect.

    Example:
        $ cb <testfile
    """
    test_str = 'qux'
    tf = tempfile.NamedTemporaryFile()
    tf.write(test_str.encode())
    tf.flush()
    call(f'{CB} <{tf.name}')
    tf.close()
    result = get_clipboard()
    assert result == test_str
