layout := '
layout {
   pane command="just" {
      args "watch"
   }
   pane command="just" {
      args "log"
   }
}
'

run:
   #!/usr/bin/env bash
   zellij --layout <(echo '{{layout}}') --session='{{file_name(parent_directory(justfile()))}}'

watch:
   git watch

log:
   watchexec --ignore-nothing -r -w .git/COMMIT_EDITMSG git --no-pager lp -n1
