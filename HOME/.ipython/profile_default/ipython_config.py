c.TerminalIPythonApp.display_banner = False
c.TerminalInteractiveShell.confirm_exit = False
c.TerminalInteractiveShell.highlighting_style = "monokai"
c.TerminalInteractiveShell.term_title = False
c.TerminalInteractiveShell.autoformatter = None

import logging

logging.getLogger('parso').level = logging.WARN
