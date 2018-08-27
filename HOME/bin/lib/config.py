import collections
import itertools

class ConflictingAliasError(Exception):
    pass


def resolve_action_aliases(actions):
    """Handle aliases within actions.

    Configured as follows:
    {
        'actions': {
            'pull': {
                'func': 'repo',
                'cmd': ['pull'],
                'help': 'Pull repository from server',
                'aliases': ['update'],
            },
            ...
        }
        ...
    }

    """
    return {
        **actions, **{
            alias: a for a in actions.values()
            for alias in a.get('aliases', ())
        }
    }


def validate_aliases(settings):
    actions = settings['actions']
    # an alias is just another name for a command. It can't share a name with an existing command,
    # nor can two commands share an alias.
    # in short, the set of all top-level commands and their aliases must be disjoint from each other
    counter = collections.Counter(
        itertools.chain(actions.keys(), *(v.get('aliases', ()) for v in actions.values())))
    dups = [item for item, count in counter.items() if count > 1]

    if dups:
        raise ConflictingAliasError(f"Conflicting command aliases: {dups!r}")


def load_file(path):
    settings = eval(open(path).read())
    validate_aliases(settings)
    return settings
