import logging
import re
import subprocess
import sys

log = logging.getLogger(__name__)


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


def test_parse_config_file():
    import io
    file = io.StringIO("""a\nb\nc""")
    assert parse_config_file(file) == ['a', 'b', 'c']

    file = io.StringIO("""a\nb\n#c\nc\nd""")
    assert parse_config_file(file) == ['a', 'b', 'c', 'd']

    file = io.StringIO("""a\n\nb\n    # c\nc\nd\n\n""")
    assert parse_config_file(file) == ['a', 'b', 'c', 'd']


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
