#!/bin/bash
# Push Mic Control status, MUTED comes from helpers/mic_watch

source "$CONFIG_DIR/colors.sh"

[ "$SENDER" = "mic_change" ] || exit 0

if [ "$MUTED" = "true" ]; then
  sketchybar --set "$NAME" icon=󰍭 icon.color=$FG3 background.color=$BG2
else
  sketchybar --set "$NAME" icon=󰍬 icon.color=$BG0 background.color=$RED
fi
