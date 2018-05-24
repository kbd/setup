# https://en.wikipedia.org/wiki/ANSI_escape_code

class D(dict):
  __getattr__ = dict.__getitem__

s = D(  # s = style
    reset='\x1b[0m',
    bold='\x1b[1m',
    it='\x1b[3m',
    ul='\x1b[4m',
    rev='\x1b[7m',
    it_off='\x1b[23m',
    ul_off='\x1b[24m',
    rev_off='\x1b[27m',
)

fg = D(  # fg = foreground
    black='\x1b[30m',
    red='\x1b[31m',
    green='\x1b[32m',
    yellow='\x1b[33m',
    blue='\x1b[34m',
    magenta='\x1b[35m',
    cyan='\x1b[36m',
    white='\x1b[37m',
)

bg = D(  # bg = background
    black='\x1b[40m',
    red='\x1b[41m',
    green='\x1b[42m',
    yellow='\x1b[4m',
    blue='\x1b[44m',
    magenta='\x1b[45m',
    cyan='\x1b[46m',
    white='\x1b[47m',
)

e = D(  # e = escapes for use within prompt
    zsh=D(
        o='%{',  # open
        c='%}',  # close
    ),
    bash=D(
        o='\\[\x1b[',
        c='\\]',
    ),
)
