layout := '
layout {
   pane split_direction="vertical" size="60%" {
      pane size="35%" command="just" {
         args "watch"
      }
      pane command="just" {
         args "log"
      }
   }
   pane size="40%"
}
'

default:
   #!/usr/bin/env bash
   zellij --layout <(echo '{{layout}}')

watch:
   git watch

log:
   echo .git/COMMIT_EDITMSG | DELTA_PAGER="$DELTA_PAGER +G -EX" entr git lp -n1
