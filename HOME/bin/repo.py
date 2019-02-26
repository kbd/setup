#!/usr/local/bin/python3
"""Print repo status.

Currently only supports git.

Inspiration taken from:
https://github.com/olivierverdier/zsh-git-prompt
https://github.com/yonchu/zsh-vcs-prompt
zsh's vcs_info

todo:
* capture merge/rebase status
* support other vcs
* rewrite in C using libgit2 directly?
"""
import argparse
import os
import re
import sys
from collections import Counter
from subprocess import check_output, run, PIPE

import pygit2 as git

from lib.colors import fg, e, s

def get_git_statuses():
    # {
    #     0: 'GIT_STATUS_CURRENT',
    #     1: 'GIT_STATUS_INDEX_NEW',
    #     2: 'GIT_STATUS_INDEX_MODIFIED',
    #     4: 'GIT_STATUS_INDEX_DELETED',
    #     8: 'GIT_STATUS_INDEX_RENAMED',
    #     16: 'GIT_STATUS_INDEX_TYPECHANGE',
    #     128: 'GIT_STATUS_WT_NEW',
    #     256: 'GIT_STATUS_WT_MODIFIED',
    #     512: 'GIT_STATUS_WT_DELETED',
    #     1024: 'GIT_STATUS_WT_TYPECHANGE',
    #     2048: 'GIT_STATUS_WT_RENAMED',
    #     4096: 'GIT_STATUS_WT_UNREADABLE'
    #     16384: 'GIT_STATUS_IGNORED',
    #     32768: 'GIT_STATUS_CONFLICTED',
    # }
    statuses = {
        getattr(git, s): s
        for s in (attr for attr in vars(git)
        if attr.startswith('GIT_STATUS_'))
    }
    del statuses[0]  # unnecessary
    return statuses


def get_shell():
    # this script's parent is the shell
    return check_output(['current_shell', str(os.getppid())]).decode().strip()


def get_templates(shell):
    o, c = e[shell].o.replace('{', '{{'), e[shell].c.replace('}', '}}')
    return {
        'ahead': f'{o}{fg.green}{c}↑{{}}{o}{s.reset}{c}',
        'behind': f'{o}{fg.red}{c}↓{{}}{o}{s.reset}{c}',
        'branch': f'{o}{fg.yellow}{c}{{}}{o}{s.reset}{c}',
        'conflicted': f'{o}{fg.red}{c}✖{{}}{o}{s.reset}{c}',
        'modified': f'{o}{fg.yellow}{c}+{{}}{o}{s.reset}{c}',
        'deleted': f'{o}{fg.red}{c}-{{}}{o}{s.reset}{c}',
        'staged': f'{o}{fg.blue}{c}●{{}}{o}{s.reset}{c}',
        'stashed': f'{o}{fg.blue}{c}⚑{{}}{o}{s.reset}{c}',
        'untracked': f'{o}{fg.cyan}{c}…{{}}{o}{s.reset}{c}',
    }


def get_repo(dir):
    path = git.discover_repository(dir)
    if not path:
        return None

    return git.Repository(path)


def get_repo_branch(repo):
    if repo.head_is_detached:
        # this is rare and I don't see a good way to get this info out of pygit2
        ret = run(
            ['git', 'describe', '--all', '--exact-match', 'HEAD'],
            stdout=PIPE, stderr=PIPE, cwd=repo.path
        )
        if not ret.returncode: #  if success
            return ret.stdout.decode().strip()

        # just return the short commit hash
        out = check_output(['git', 'rev-parse', '--short', 'HEAD'], cwd=repo.workdir)
        return out.decode().strip()
    elif repo.head_is_unborn:  # brand new empty repo
        return 'master'

    return repo.head.shorthand


def get_stash_count(repo):
    if repo.head_is_unborn:
        return 0, 0  # can't stash on new repo

    stashes = check_output(['git', 'stash', 'list'], cwd=repo.workdir).decode().splitlines()
    getbranch = re.compile(r'^[^:]+:[^:]+?(\S+):')
    counter = Counter(getbranch.match(s)[1] for s in stashes)
    return len(stashes), counter[repo.head.shorthand]


def get_repo_status(repo):
    status = repo.status()
    counts = Counter(status.values())
    final_counts = Counter()
    statuses = get_git_statuses()
    status_codes = sorted(statuses, reverse=True)
    # go over the counts and split up the flags
    for code, count in counts.items():
        for status_code in status_codes:
            if status_code & code:
                final_counts[status_code] += count

    return {
        status_name: final_counts[code]
        for code, status_name in statuses.items()
    }


def get_ahead_behind(repo):
    if repo.head_is_unborn or repo.head_is_detached:
        return 0, 0

    local = repo.head
    upstream = repo.branches[repo.head.shorthand].upstream
    if not upstream:
        return 0, 0

    return repo.ahead_behind(local.target, upstream.target)


def get_repo_info(repo):
    """Return a dictionary of repository info"""
    ahead, behind = get_ahead_behind(repo)
    status = get_repo_status(repo)
    # count anything in the index as staged
    staged = sum(v for k, v in status.items() if k.startswith('GIT_STATUS_INDEX'))
    result = {  # this order is how we want things displayed (req. 3.6 dict ordering)
        'branch': get_repo_branch(repo),
        'ahead': ahead,
        'behind': behind,
        'staged': staged,
        'modified': status['GIT_STATUS_WT_MODIFIED'],
        'deleted': status['GIT_STATUS_WT_DELETED'],
        'untracked': status['GIT_STATUS_WT_NEW'],
        'conflicted': status['GIT_STATUS_CONFLICTED'],
        'stashed': get_stash_count(repo)[1],  # just for the branch
    }
    return result


def print_repo_info(repo_info, templates):
    results = [templates[i].format(repo_info[i]) for i in repo_info if repo_info[i]]
    if len(results) > 1:
        # if more than branch, add space after branch (req. 3.6 dict ordering)
        results.insert(1, ' ')
    print(''.join(results))


def main(args):
    repo = get_repo(args.path)
    if not repo:
        return 1

    info = get_repo_info(repo)
    if args.fake:
        info.update({k: 2 for k in info if k != 'branch'})

    shell = get_shell()
    if args.interactive or shell not in ('bash', 'zsh'):
        shell = 'interactive'

    templates = get_templates(shell)
    print_repo_info(info, templates)
    return 0


def parse_args():
    parser = argparse.ArgumentParser(description='Print repo status')
    parser.add_argument('path', nargs='?', default='.', help='Path to repository')
    parser.add_argument('-f', '--fake', action='store_true', help='Show fake status')
    parser.add_argument('-i', '--interactive', action='store_true', help="Don't output prompt escapes")
    return parser.parse_args()


if __name__ == '__main__':
    args = parse_args()
    sys.exit(main(args))
