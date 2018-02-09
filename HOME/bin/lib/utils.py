import logging
import subprocess

log = logging.getLogger(__name__)


def run(cmd, check=True, cap=False, input=None, exe='/bin/bash'):
    log.debug(f"Executing: {cmd!r}")
    shell = isinstance(cmd, str)
    result = subprocess.run(
        cmd,
        check=check,
        shell=shell,
        stdout=subprocess.PIPE if cap else None,
        executable=exe if shell else None,
        input=input.encode() if input else None,
    )

    if cap:
        return result.stdout.decode()
    else:
        return result
