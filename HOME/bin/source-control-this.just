kitty_launch := 'kitty @ launch --type window --cwd=current --copy-env --location=before --dont-take-focus'

run:
   {{kitty_launch}} --bias=25 git watch
   {{kitty_launch}} --bias=50 git tail-log
