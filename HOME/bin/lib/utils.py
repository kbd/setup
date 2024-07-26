import logging
import re
import subprocess
import sys
from unittest.mock import patch

log = logging.getLogger(__name__)



EXECUTABLE = '/bin/bash'


def run(cmd, check=True, cap=False, input=None, exe='/bin/bash', cwd=None, env=None, **kwargs):
    log.debug(f"Executing: {cmd!r}")
    shell = isinstance(cmd, str)
    args = dict(
        check=check,
        shell=shell,
        stdout=subprocess.PIPE if cap in (True, 'stdout') else None,
        stderr=subprocess.PIPE if cap in (True, 'stderr') else None,
        executable=exe if shell else None,
        input=input.encode() if input else None,
        cwd=cwd,
        env=env,
    )
    args.update(kwargs)

    result = subprocess.run(cmd, **args)

    if cap:
        return result.stdout.decode()
    else:
        return result

# region run tests
def test_run_call_cmd():
    cmd = ['echo', 'hello']
    with patch('subprocess.run') as mockrun:
        run(cmd)

    mockrun.assert_called_with(
        cmd, check=True, shell=False, stdout=None, stderr=None,
        executable=None, input=None, cwd=None, env=None
    )


def test_run_call_shell_cmd():
    cmd = 'echo "hello"'
    with patch('subprocess.run') as mockrun:
        run(cmd)

    mockrun.assert_called_with(
        cmd, check=True, shell=True, stdout=None, stderr=None,
        executable=EXECUTABLE, input=None, cwd=None, env=None
    )


def test_run_call_shell_output():
    cmd = 'echo "hello"'
    with patch('subprocess.run') as mockrun:
        run(cmd, cap=True)

    mockrun.assert_called_with(
        cmd, check=True, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
        executable=EXECUTABLE, input=None, cwd=None, env=None
    )


def test_run_call_shell_input():
    cmd = 'cat'
    input = 'hello'
    with patch('subprocess.run') as mockrun:
        run(cmd, input=input)

    mockrun.assert_called_with(
        cmd, check=True, shell=True, stdout=None, stderr=None,
        executable=EXECUTABLE, input=input.encode(), cwd=None, env=None
    )


def test_run_call_cmd_cap_input():
    cmd = ['cat']
    input = 'hello'
    with patch('subprocess.run') as mockrun:
        run(cmd, cap=True, input=input)

    mockrun.assert_called_with(
        cmd, check=True, shell=False, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
        executable=None, input=input.encode(), cwd=None, env=None
    )


def test_run_shell_output():
    output = run('echo "hello"', cap=True)
    expected_output = 'hello\n'
    assert output == expected_output


def test_run_shell_input():
    output = run(['cat'], cap=True, input='hello')
    expected_output = 'hello'
    assert output == expected_output
# endregion run tests

def partition(pred, list):
    trues, falses = [], []
    for item in list:
        (trues if pred(item) else falses).append(item)
    return trues, falses


def partition_by_regex(regex, list):
    r = re.compile(regex or '')
    return partition(r.search, list)


def parse_config_file(file, comment='#'):
    return [
        line for line in (line.rstrip() for line in file)
        if line and not (comment and line.lstrip().startswith(comment))
    ]


def read_config_file(path, comment='#'):
    """Read the lines from a file, skipping empty and commented lines.

    Don't process comments if 'comment' is falsy.
    """
    with open(path) as file:
        return parse_config_file(file, comment)


# region config file tests
def test_parse_config_file():
    import io
    file = io.StringIO("""a\nb\nc""")
    assert parse_config_file(file) == ['a', 'b', 'c']

    file = io.StringIO("""a\nb\n#c\nc\nd""")
    assert parse_config_file(file) == ['a', 'b', 'c', 'd']

    file = io.StringIO("""a\n\nb\n    # c\nc\nd\n\n""")
    assert parse_config_file(file) == ['a', 'b', 'c', 'd']


def test_read_config():
    import tempfile

    values = ['one', 'two', 'three', '#four', '     \t  ', 'five']
    with tempfile.NamedTemporaryFile() as t:
        t.writelines(f'{v}\n'.encode() for v in values)
        t.flush()
        actual = read_config_file(t.name)

    expected = ['one', 'two', 'three', 'five']
    assert actual == expected


def test_read_config_no_comments():
    import tempfile

    values = ['one', 'two', 'three', '#four', '     \t  ', 'five']
    with tempfile.NamedTemporaryFile() as t:
        t.writelines(f'{v}\n'.encode() for v in values)
        t.flush()
        actual = read_config_file(t.name, comment=None)

    expected = ['one', 'two', 'three', '#four', 'five']
    assert actual == expected


def test_read_config_with_blanks_and_comments():
    import tempfile

    values = ['one', 'two', 'three', '# commented line', 'four', ' ', 'six']
    with tempfile.NamedTemporaryFile() as t:
        t.writelines(f'{v}\n'.encode() for v in values)
        t.flush()
        actual = read_config_file(t.name, comment='#')

    assert actual == ['one', 'two', 'three', 'four', 'six']
# endregion config file tests

def run_commands(cmd, *args, **kwargs):
    """Take one or more commands to run as a subprocess.

    * 'cmd' be one command or a tuple of commands
    * each command can be a string or a list of strings, passed to run
    """
    if isinstance(cmd, tuple):
        return [run(c, *args, **kwargs) for c in cmd]

    return run(cmd, *args, **kwargs)


def run_func_on_cmdline_input(func):
    for arg in sys.argv[1:]:
        print(func(arg))

    if not sys.stdin.isatty():
        print(func(sys.stdin.read()), end='')
