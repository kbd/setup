# https://en.wikipedia.org/wiki/ANSI_escape_code

class D(dict):
    __getattr__ = dict.__getitem__

colors = ['black', 'red', 'green', 'yellow', 'blue', 'magenta', 'cyan', 'white']
style_codes = dict(reset=0, bold=1, it=3, ul=4, rev=7, it_off=23, ul_off=24, rev_off=27)
esc = lambda i: f'\x1b[{i}m'

# s = style, fg = foreground, bg = background
s = D({name: esc(i) for name, i in style_codes.items()})
fg = D({colors[i]: esc(30+i) for i in range(8)})
bg = D({colors[i]: esc(40+i) for i in range(8)})

e = D(  # e = escapes for use within prompt, o=open, c=close
    zsh=D(o='%{', c='%}'),
    bash=D(o='\\[\x1b[', c='\\]'),
    interactive=D(o='', c=''),
)
