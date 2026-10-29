#!/bin/sh
# Seamless ctrl+h/j/k/l navigation: nvim split -> herdr pane -> kitty window.
# Usage: navigate.sh left|down|up|right [--from-nvim]

HERDR=/opt/homebrew/bin/herdr
JQ=/opt/homebrew/bin/jq
KITTEN=/Applications/kitty.app/Contents/MacOS/kitten
KITTY_SOCKET=unix:/tmp/mykitty

dir=$1
from_nvim=$2

case $dir in
  left) key=ctrl+h; kitty_dir=left ;;
  down) key=ctrl+j; kitty_dir=bottom ;;
  up) key=ctrl+k; kitty_dir=top ;;
  right) key=ctrl+l; kitty_dir=right ;;
  *) echo "usage: $0 left|down|up|right [--from-nvim]" >&2; exit 2 ;;
esac

# Always act on the UI-focused pane, not the pane the caller happens to live in.
unset HERDR_PANE_ID
pane=$("$HERDR" pane current | "$JQ" -r '.result.pane.pane_id')
[ -n "$pane" ] || exit 1

if [ "$from_nvim" != "--from-nvim" ] &&
  "$HERDR" pane process-info --pane "$pane" |
  "$JQ" -e '[.result.process_info.foreground_processes[].name | test("^n?vim$")] | any' >/dev/null; then
  exec "$HERDR" pane send-keys "$pane" "$key"
fi

at_edge=$("$HERDR" pane edges --pane "$pane" | "$JQ" -r ".result.edges.$dir")
if [ "$at_edge" = "false" ]; then
  exec "$HERDR" pane focus --pane "$pane" --direction "$dir"
fi

exec "$KITTEN" @ --to "$KITTY_SOCKET" focus-window --match "neighbor:$kitty_dir"
