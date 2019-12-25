import logging
import re
import subprocess

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
