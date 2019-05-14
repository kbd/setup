import logging
import re
import subprocess

log = logging.getLogger(__name__)


def run(cmd, check=True, cap=False, input=None, exe='/bin/bash', cwd=None, env=None):
    log.debug(f"Executing: {cmd!r}")
    shell = isinstance(cmd, str)
    result = subprocess.run(
        cmd,
        check=check,
        shell=shell,
        stdout=subprocess.PIPE if cap in (True, 'stdout') else None,
        stderr=subprocess.PIPE if cap in (True, 'stderr') else None,
        executable=exe if shell else None,
        input=input.encode() if input else None,
        cwd=cwd,
        env=env,
    )

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


def read_lines_from_file(path, comment=None):
    """Read the lines from a file, skipping empty lines and (optionally) commented lines.

    If 'comment' string is provided, lines beginning with 'comment' will not be returned.
    """
    with open(path) as file:
        lines = [line.rstrip() for line in file]

    return [
        line for line in lines
        if line and not (comment and line.startswith(comment))
    ]
