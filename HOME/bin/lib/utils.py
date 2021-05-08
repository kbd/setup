import logging
import os
import re
import subprocess
from contextlib import contextmanager
from pathlib import Path

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


def read_config_file(path, comment='#'):
    """Read the lines from a file, skipping empty and commented lines.

    Don't process comments if 'comment' is falsy.
    """
    with open(path) as file:
        return [
            line for line in (line.rstrip() for line in file)
            if line and not (comment and line.startswith(comment))
        ]


def run_commands(cmd, *args, **kwargs):
    """Take one or more commands to run as a subprocess.

    * 'cmd' be one command or a tuple of commands
    * each command can be a string or a list of strings, passed to run
    """
    if isinstance(cmd, tuple):
        return [run(c, *args, **kwargs) for c in cmd]

    return run(cmd, *args, **kwargs)


@contextmanager
def chdir(dir: Path):
    original = os.getcwd()
    os.chdir(dir)
    try:
        yield
    finally:
        os.chdir(original)
