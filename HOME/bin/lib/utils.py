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
        capture_output=cap,
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
