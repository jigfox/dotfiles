#!/bin/sh
# Hand a navigation/resize off to the outer terminal (kitty or Ghostty) that is focused.
# Usage: outer.sh nav|resize left|down|up|right

JQ=/opt/homebrew/bin/jq
KITTEN=/Applications/kitty.app/Contents/MacOS/kitten
KITTY_SOCKET=unix:/tmp/mykitty

action=$1
dir=$2

case $dir in
  left) kitty_dir=left; key=ctrl+shift+h ;;
  down) kitty_dir=bottom; key=ctrl+shift+j ;;
  up) kitty_dir=top; key=ctrl+shift+k ;;
  right) kitty_dir=right; key=ctrl+shift+l ;;
  *) echo "usage: $0 nav|resize left|down|up|right" >&2; exit 2 ;;
esac

# kitty: only when its focused window runs herdr or nvim (kitty has no focused window while in the background)
if "$KITTEN" @ --to "$KITTY_SOCKET" ls --match state:focused 2>/dev/null |
  "$JQ" -e '[.[].tabs[].windows[].foreground_processes[].cmdline[0] // "" | test("herdr|n?vim")] | any' >/dev/null; then
  case $action in
    nav) exec "$KITTEN" @ --to "$KITTY_SOCKET" focus-window --match "neighbor:$kitty_dir" ;;
    resize) exec "$KITTEN" @ --to "$KITTY_SOCKET" action kitten pass_resize.py "$kitty_dir" "$key" force ;;
  esac
fi

# Ghostty: only when it is the active app
case $action in
  nav) ghostty_action="goto_split:$dir" ;;
  resize) ghostty_action="resize_split:$dir,20" ;;
esac
exec osascript - "$ghostty_action" >/dev/null 2>&1 <<'EOF'
on run argv
  if application "Ghostty" is not running then return
  tell application "Ghostty"
    if not frontmost then return
    perform action (item 1 of argv) on focused terminal of selected tab of front window
  end tell
end run
EOF
