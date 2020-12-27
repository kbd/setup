import ast
import json
import logging
import re
import subprocess
from itertools import chain

from .utils import run

log = logging.getLogger(__name__)


def restart_os_functions(*args, **kwargs):
    for item in ('Finder', 'Dock', 'SystemUIServer', 'cfprefsd'):
        cmd = ['killall', item]
        log.info(f"Executing command: {cmd!r}")
        subprocess.check_call(cmd)


DEFAULTS_TYPE_MAP = {
    bool: 'boolean',
    int: 'integer',
    float: 'float',
    str: 'string',
    dict: 'dict',
    list: 'array',
    # todo: conversion procsess between bytes and <62706c69 73743030 d4010203...>
    # format that 'defaults' uses
    bytes: 'data',
}
REVERSE_TYPE_MAP = {v: k for k, v in DEFAULTS_TYPE_MAP.items()}
# Other names for types. For example, while 'defaults write' requires '-dict' to
# write a dictionary, 'defaults read-type' returns 'dictionary' for its type.
REVERSE_TYPE_MAP.update({'bool': bool, 'int': int, 'dictionary': dict})


def flatten(value):
    # will throw exception for unknown type, which is fine
    result = [f'-{DEFAULTS_TYPE_MAP[type(value)]}']
    if isinstance(value, dict):
        result.extend(chain.from_iterable((k, *flatten(v)) for k, v in value.items()))
    elif isinstance(value, list):
        result.extend(map(str, value))
    else:
        result.append(str(value))

    return result

class _DefaultsDomain:
    def __init__(self, domain=None):
        self.domain = domain

    def __getitem__(self, key):
        if not self.domain:  # still needs a domain
            return _DefaultsDomain(key)

        return DefaultsValue(self.domain, key)

    def __setitem__(self, key, value):
        return DefaultsValue(self.domain, key).write(value)

    def read_str(self):
        return run(["defaults", "read", self.domain], cap=True).rstrip('\n')

    def read_json(self):
        return json.loads(run(["plist-to-json"], cap=True, input=self.read_str()))

    read = read_str  # todo: read should really return a Python data structure


class DefaultsValue:
    def __init__(self, domain, key):
        self.domain = domain
        self.key = key

    def type(self):
        typestr = run(["defaults", "read-type", self.domain, self.key], cap=True)
        # read-type returns (literally) "Type is {typename}\n".
        # Pull the last word from the string to get the type.
        return REVERSE_TYPE_MAP[typestr.split()[-1]]

    def read_str(self):
        return run(["defaults", "read", self.domain, self.key], cap=True).rstrip('\n')

    def read_json(self):
        return json.loads(run(["plist-to-json"], cap=True, input=self.read_str()))

    def read(self):
        t = self.type()
        s = self.read_str()
        if t == str:
            return s
        elif t != dict:
            return t(ast.literal_eval(s))

        # parse dict. Looks like: '{\n    keyCode = 47;\n    modifierFlags = 1310720;\n}\n'
        stripped_lines = (l.strip() for l in s.strip().strip('{}').splitlines())
        lines = [line for line in stripped_lines if line]
        return {
            m[1]: ast.literal_eval(m[2])
            for m in (re.search(r'(\w+)\s+=\s+(.*);', line) for line in lines)
        }

    def write(self, value):
        return run(["defaults", "write", self.domain, self.key, *flatten(value)])

    @staticmethod
    def _get_plist(value):
        return run(["json-to-plist"], cap=True, input=json.dumps(value))

    def write_plist(self, value):
        return run(["defaults", "write", self.domain, self.key, self._get_plist(value)])


    __str__ = read_str


defaults = _DefaultsDomain()
defaults.g = defaults['-g']
