#!/usr/bin/env bash
set -Eeuxo pipefail

shell=$1
shellfile=${2-'/etc/shells'}

if [[ -z "$shell" ]]; then
  echo >&2 "missing shell argument"
  exit 1
fi

echo "Ensuring shell is set to '$shell'"

echo "Ensuring '$shell' is in '$shellfile'"
grep -Fqx "$shell" "$shellfile" || echo "$shell" | 1>/dev/null sudo tee -a "$shellfile"
echo "Changing shell to '$shell'"
chsh -s "$shell"
