#!/user/bin/env python3

"""Test clipboard utility 'cb'.

Call out to 'cb' utility with various usages. Originally intended to run with
py.test, except running with py.test causes a problem where the clipboard
doesn't actually get set during the test, and I have zero idea why.

What's stranger, if you run the debugger (left commented out in set_clipboard
for now) it behaves correctly, even if you just immediately (c)ontinue.

So, I implemented a main that runs the tests manually, which behaves correctly.

It also works in Nose! Example outputs:

$ py.test -v test_cb.py
...
test_cb.py::test_default FAILED
test_cb.py::test_pipe_set FAILED
test_cb.py::test_pipe_get FAILED
test_cb.py::test_argument_set FAILED
test_cb.py::test_set_with_redirect FAILED

$ nosetests -v test_cb.py
Test default usage. ... ok
Test setting clipboard with value piped to cb. ... ok
Test getting clipboard with value piped from cb. ... ok
Test setting clipboard with an argument. ... ok
Test setting clipboard with file redirect. ... ok

$ python3 test_cb.py
Running functions: ['test_argument_set', 'test_default', 'test_pipe_get', 'test_pipe_set', 'test_set_with_redirect']
Running test_argument_set
Result is 'baz', test_str is 'baz' =? True
Running test_default
Result is 'foo', test_str is 'foo' =? True
Running test_pipe_get
Result is 'bar', test_str is 'bar' =? True
Running test_pipe_set
Result is 'bar', test_str is 'bar' =? True
Running test_set_with_redirect
Result is 'qux', test_str is 'qux' =? True
"""

import inspect
import tempfile
from subprocess import check_call as cc, check_output as co

# CB = 'xerox'
CB = 'cb'

# get and set clipboard utility functions. These depend on cb behavior being
# correct in the first place, but could potentially be replaced with an
# independent method
def set_clipboard(test_str):
    # import pdb; pdb.set_trace()
    cc([CB, test_str])


def get_clipboard():
    value = co(CB).decode()
    if CB == 'xerox':
        value = value.rstrip()

    return value


def call(cmd):
    args = {'shell': True, 'executable': 'bash'} if isinstance(cmd, str) else {}
    # print(f'Executing {cmd}, {args}')
    value = co(cmd, **args).decode()
    if CB == 'xerox':
        value = value.rstrip()

    return value


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
    print(f'Result is {result!r}, test_str is {test_str!r} =? {result == test_str!r}')
    assert result == test_str


def test_pipe_set():
    """Test setting clipboard with value piped to cb.

    Example:
        $ echo bar | cb
        $ cb
        bar
    """
    # import pdb; pdb.set_trace()
    test_str = 'bar'
    call(f'echo -n "{test_str}" | {CB}')
    result = get_clipboard()
    print(f'Result is {result!r}, test_str is {test_str!r} =? {result == test_str!r}')
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
    print(f'Result is {result!r}, test_str is {test_str!r} =? {result == test_str!r}')
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
    print(f'Result is {result!r}, test_str is {test_str!r} =? {result == test_str!r}')
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
    print(f'Result is {result!r}, test_str is {test_str!r} =? {result == test_str!r}')
    assert result == test_str


if __name__ == '__main__':
    test_funcs = {
        name: item for name, item in globals().items()
        if inspect.isfunction(item) and name.startswith('test_')
    }
    print(f"Running functions: {sorted(test_funcs)}")

    for name, func in sorted(test_funcs.items()):
        try:
            print(f"Running {name}")
            func()
        except:
            print("###Assertion failed")
