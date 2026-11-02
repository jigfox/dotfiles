#!/bin/bash

source "$CONFIG_DIR/colors.sh"

info=$(pmset -g batt)
percent=$(echo "$info" | grep -Eo '[0-9]+%' | tr -d '%')

# no battery (desktop Mac)
if [ -z "$percent" ]; then
  sketchybar --set "$NAME" drawing=off
  exit 0
fi

if [[ $info == *"AC Power"* ]]; then
  icon=󰂄 color=$GREEN
elif [ "$percent" -gt 80 ]; then
  icon=󰁹 color=$GREEN
elif [ "$percent" -gt 50 ]; then
  icon=󰁾 color=$FG1
elif [ "$percent" -gt 20 ]; then
  icon=󰁼 color=$YELLOW
else
  icon=󰁺 color=$RED
fi

sketchybar --set "$NAME" drawing=on icon="$icon" icon.color=$color label="$percent%"
