# http://linuxcommand.org/lc3_adv_tput.php
# http://unix.stackexchange.com/questions/269077/tput-setaf-color-table-how-to-determine-color-codes
# http://misc.flogisoft.com/bash/tip_colors_and_formatting
# https://en.wikipedia.org/wiki/ANSI_escape_code

typeset -A COL  # declare associative array, works both in bash and zsh
export COL

COL[reset]="$(tput sgr0)"
COL[bold]="$(tput bold)"
COL[dim]="$(tput dim)"
COL[uline]="$(tput smul)"
COL[no_uline]="$(tput rmul)"
COL[blink]="$(tput blink)"

COL[black]="$(tput setaf 0)"
COL[red]="$(tput setaf 1)"
COL[green]="$(tput setaf 2)"
COL[yellow]="$(tput setaf 3)"
COL[blue]="$(tput setaf 4)"
COL[purple]="$(tput setaf 5)"
COL[cyan]="$(tput setaf 6)"
COL[grey]="$(tput setaf 7)"
# setaf 9 is wrong on mac, but right in screen and tmux ¯\_(ツ)_/¯
COL[default]="$(tput setaf 9)"

COL[b_black]="$(tput setab 0)"
COL[b_red]="$(tput setab 1)"
COL[b_green]="$(tput setab 2)"
COL[b_yellow]="$(tput setab 3)"
COL[b_blue]="$(tput setab 4)"
COL[b_purple]="$(tput setab 5)"
COL[b_cyan]="$(tput setab 6)"
COL[b_grey]="$(tput setab 7)"
# see comment for setaf 9
COL[b_default]="$(tput setab 9)"
