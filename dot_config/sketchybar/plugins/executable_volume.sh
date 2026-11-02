#!/bin/bash
# Volume: scroll to change, click for a popup with a slider and the output/input devices.
# Device switching via SwitchAudioSource (brew switchaudio-osx).

CONFIG_DIR=${CONFIG_DIR:-$HOME/.config/sketchybar} # unset when run from a device row click_script
source "$CONFIG_DIR/colors.sh"

SWITCH=/opt/homebrew/bin/SwitchAudioSource
FONT="Comic Code Ligatures:Bold:13.0"
ICON_FONT="Symbols Nerd Font Mono:Regular:15.0"

current_volume() {
  osascript -e 'output volume of (get volume settings)'
}

update() {
  volume=${1:-$(current_volume)}
  # output devices without software volume (DACs, monitors) report "missing value"
  if ! [[ $volume =~ ^[0-9]+$ ]]; then
    sketchybar --set volume icon=󰓃 label.drawing=off --set volume.slider drawing=off
    return
  fi
  case $volume in
    [6-9][0-9] | 100) icon=󰕾 ;;
    [3-5][0-9]) icon=󰖀 ;;
    [1-9] | [1-2][0-9]) icon=󰕿 ;;
    *) icon=󰖁 ;;
  esac
  sketchybar --set volume icon="$icon" label.drawing=on label="$volume%" \
    --set volume.slider drawing=on slider.percentage="$volume"
}

# virtual devices that are no real choice
HIDDEN_DEVICES='^Microsoft Teams Audio$'

# one popup row per device of type output|input, the current one highlighted.
# sketchybar draws the icon before the label, so the name is the (fixed width) icon
# and the checkmark the label, to get the checkmark at the right end.
device_rows() {
  local type=$1 title=$2 current
  current=$("$SWITCH" -c -t "$type" -f json | jq -r .uid)
  args+=(--add item "volume.$type" popup.volume
    --set "volume.$type" icon.drawing=off label="$title" label.padding_left=6 label.color=$FG3 background.drawing=off)
  local i=0
  while IFS=$'\t' read -r uid name; do
    i=$((i + 1))
    if [ "$uid" = "$current" ]; then
      style=(icon.color=$MAGENTA label=󰄬 label.color=$MAGENTA)
    else
      style=(icon.color=$FG1 label=" " label.color=$FG1)
    fi
    args+=(--add item "volume.$type.$i" popup.volume
      --set "volume.$type.$i" icon="$name" icon.font="$FONT" icon.width=200 icon.padding_left=6
      label.font="$ICON_FONT" "${style[@]}" background.drawing=off
      click_script="$SWITCH -t $type -u '$uid' >/dev/null; $CONFIG_DIR/plugins/volume.sh popup")
  done < <("$SWITCH" -a -t "$type" -f json |
    jq -r --arg hidden "$HIDDEN_DEVICES" 'select(.name | test($hidden) | not) | [.uid, .name] | @tsv')
}

popup() {
  args=()
  for item in $(sketchybar --query volume | jq -r '.popup.items[]? | select(. != "volume.slider")'); do
    args+=(--remove "$item")
  done
  device_rows output Output
  device_rows input Input
  sketchybar "${args[@]}" --set volume popup.drawing=on
  update
}

case "$SENDER" in
  volume_change) update "$INFO" ;;
  mouse.scrolled)
    volume=$(current_volume)
    [[ $volume =~ ^[0-9]+$ ]] || exit 0
    volume=$((volume + SCROLL_DELTA * 2))
    osascript -e "set volume output volume $((volume < 0 ? 0 : volume > 100 ? 100 : volume))"
    ;;
  mouse.clicked)
    if [ "$(sketchybar --query volume | jq -r .popup.drawing)" = "on" ]; then
      sketchybar --set volume popup.drawing=off
    else
      popup
    fi
    ;;
  mouse.exited.global) sketchybar --set volume popup.drawing=off ;;
  *)
    # called from a device row: refresh the popup after switching
    if [ "$1" = popup ]; then popup; else update; fi
    ;;
esac
