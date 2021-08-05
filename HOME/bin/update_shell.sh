#!/usr/bin/env bash
set -e

shell=$1
shellfile=${2-'/etc/shells'}

if [[ -z "$shell" ]]; then
  echo >&2 "missing shell argument"
  exit 1
fi

get-login-shell() {
  finger $USER | rg 'Shell:\s+(\S+)' -or '$1'
}

echo "Ensuring shell is set to '$shell'"
if [[ $shell == "$(get-login-shell)" ]]; then
  echo "Confirmed shell is set to '$shell'"
else
  echo "Ensuring '$shell' is in '$shellfile'"
  grep -Fqx "$shell" "$shellfile" || echo "$shell" | 1>/dev/null sudo tee -a "$shellfile"
  echo "Changing shell to '$shell'"
  chsh -s "$shell"
  echo "Shell changed"
fi
