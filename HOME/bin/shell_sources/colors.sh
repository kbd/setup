# http://linuxcommand.org/lc3_adv_tput.php
# http://unix.stackexchange.com/questions/269077/tput-setaf-color-table-how-to-determine-color-codes
# http://misc.flogisoft.com/bash/tip_colors_and_formatting
# https://en.wikipedia.org/wiki/ANSI_escape_code

export     COLOR_RESET="$(tput sgr0)"
export      COLOR_BOLD="$(tput bold)"
export       COLOR_DIM="$(tput dim)"
export     COLOR_ULINE="$(tput smul)"
export  COLOR_NO_ULINE="$(tput rmul)"
export     COLOR_BLINK="$(tput blink)"

export     COLOR_BLACK="$(tput setaf 0)"
export       COLOR_RED="$(tput setaf 1)"
export     COLOR_GREEN="$(tput setaf 2)"
export    COLOR_YELLOW="$(tput setaf 3)"
export      COLOR_BLUE="$(tput setaf 4)"
export    COLOR_PURPLE="$(tput setaf 5)"
export      COLOR_CYAN="$(tput setaf 6)"
export      COLOR_GREY="$(tput setaf 7)"
# setaf 9 is wrong on mac, but right in screen and tmux ¯\_(ツ)_/¯
export   COLOR_DEFAULT="$(tput setaf 9)"

export   BGCOLOR_BLACK="$(tput setab 0)"
export     BGCOLOR_RED="$(tput setab 1)"
export   BGCOLOR_GREEN="$(tput setab 2)"
export  BGCOLOR_YELLOW="$(tput setab 3)"
export    BGCOLOR_BLUE="$(tput setab 4)"
export  BGCOLOR_PURPLE="$(tput setab 5)"
export    BGCOLOR_CYAN="$(tput setab 6)"
export    BGCOLOR_GREY="$(tput setab 7)"
# see comment for setaf 9
export BGCOLOR_DEFAULT="$(tput setab 9)"
