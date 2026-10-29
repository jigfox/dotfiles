#!/bin/sh
# Seamless ctrl+shift+h/j/k/l resize: nvim split -> herdr pane -> kitty window.
# Moves the divider in the given direction.
# Usage: resize.sh left|down|up|right [--from-nvim]

HERDR=/opt/homebrew/bin/herdr
JQ=/opt/homebrew/bin/jq
NVIM=/opt/homebrew/bin/nvim
NVIM_RUN_DIR="$(getconf DARWIN_USER_TEMP_DIR)nvim.$(id -un)"

dir=$1
from_nvim=$2

case $dir in
  left) key=ctrl+shift+h; axis="left right" ;;
  down) key=ctrl+shift+j; axis="up down" ;;
  up) key=ctrl+shift+k; axis="up down" ;;
  right) key=ctrl+shift+l; axis="left right" ;;
  *) echo "usage: $0 left|down|up|right [--from-nvim]" >&2; exit 2 ;;
esac

# Always act on the UI-focused pane, not the pane the caller happens to live in.
unset HERDR_PANE_ID
pane=$("$HERDR" pane current | "$JQ" -r '.result.pane.pane_id')
[ -n "$pane" ] || exit 1

# nvim in the focused pane: let it resize its own splits via RPC (prints 1 if it did)
if [ "$from_nvim" != "--from-nvim" ]; then
  for pid in $("$HERDR" pane process-info --pane "$pane" |
    "$JQ" -r '.result.process_info.foreground_processes[] | select(.name | test("^n?vim$")) | .pid'); do
    for sock in "$NVIM_RUN_DIR"/*/nvim."$pid".0; do
      [ -S "$sock" ] || continue
      handled=$("$NVIM" --headless --clean --server "$sock" --remote-expr "v:lua.SeamlessResize('$dir')" 2>/dev/null)
      [ "$handled" = "1" ] && exit 0
    done
  done
fi

# herdr pane has a neighbor on this axis
edges=$("$HERDR" pane edges --pane "$pane")
for side in $axis; do
  if [ "$(echo "$edges" | "$JQ" -r ".result.edges.$side")" = "false" ]; then
    exec "$HERDR" pane resize --pane "$pane" --direction "$dir" --amount 0.03
  fi
done

# at the herdr edge: hand off to the outer terminal (kitty or Ghostty)
exec "$(dirname "$0")/outer.sh" resize "$dir"
