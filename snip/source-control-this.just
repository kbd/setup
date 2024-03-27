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

run:
   #!/usr/bin/env bash
   zellij --layout <(echo '{{layout}}') --session='{{file_name(parent_directory(justfile()))}}'

watch:
   git watch

log:
   watchexec --ignore-nothing -r -w .git/COMMIT_EDITMSG git --no-pager lp -n1
