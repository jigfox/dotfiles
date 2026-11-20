#!/bin/bash
# Left side of the bar, driven by aerospace:
# - per workspace a bracket with its number and a clickable icon per app (non-empty and focused ones,
#   on the bar of their monitor), the focused workspace highlighted
# - the windows of the visible workspace of each monitor with icon and app name, the focused one highlighted
# Items are only rebuilt when windows/workspaces change, otherwise just restyled (no flicker).

source "$CONFIG_DIR/colors.sh"
source "$CONFIG_DIR/icon_map.sh"

APP_FONT="sketchybar-app-font:Regular:15.0"

focused_ws=${FOCUSED_WORKSPACE:-$(aerospace list-workspaces --focused)}
focused_win=$(aerospace list-windows --focused --format '%{window-id}' 2>/dev/null)
workspaces=$(aerospace list-workspaces --all --format '%{workspace}|%{monitor-appkit-nsscreen-screens-id}')
visible=" $(aerospace list-workspaces --monitor all --visible | tr '\n' ' ') "
windows=$(aerospace list-windows --all --format '%{window-id}|%{workspace}|%{app-name}')

key() { echo "${1//[^A-Za-z0-9_]/_}"; }

order=() # all left items in bar order
dynamic=() # app.* and win.* items in bar order
set_args=()
add_args=()

while IFS='|' read -r sid display; do
  ws_apps=$(awk -F'|' -v ws="$sid" '$2 == ws && !seen[$3]++' <<<"$windows")
  order+=("space.$sid")

  if [ "$sid" = "$focused_ws" ]; then
    bg=$MAGENTA fg=$BG0 app_fg=$BG0
  elif [ -n "$ws_apps" ]; then
    bg=$BG2 fg=$FG1 app_fg=$FG0
  else
    set_args+=(--set "space.$sid" drawing=off --set "ws.$sid" background.drawing=off)
    continue
  fi
  set_args+=(--set "space.$sid" drawing=on display="$display" icon.color=$fg
    --set "ws.$sid" background.drawing=on background.color=$bg)

  members=()
  last=$(tail -n1 <<<"$ws_apps" | cut -d'|' -f1)
  while IFS='|' read -r id _ app; do
    [ -n "$id" ] || continue
    __icon_map "$app"
    order+=("app.$id") dynamic+=("app.$id") members+=("app.$id")
    add_args+=(--add item "app.$id" left)
    set_args+=(--set "app.$id" display="$display" icon="$icon_result" icon.color=$app_fg
      icon.padding_right=$([ "$id" = "$last" ] && echo 8 || echo 3))
  done <<<"$ws_apps"
  printf -v "members_$(key "$sid")" '%s ' "${members[@]}"
done <<<"$workspaces"

order+=(aerospace)

# windows of the visible workspaces, in workspace order
while IFS='|' read -r sid display; do
  [[ $visible == *" $sid "* ]] || continue
  while IFS='|' read -r id _ app; do
    [ -n "$id" ] || continue
    __icon_map "$app"
    order+=("win.$id") dynamic+=("win.$id")
    add_args+=(--add item "win.$id" left)
    if [ "$id" = "$focused_win" ]; then
      style=(icon.color=$MAGENTA label.color=$MAGENTA background.drawing=on)
    else
      style=(icon.color=$FG3 label.color=$FG3 background.drawing=off)
    fi
    set_args+=(--set "win.$id" display="$display" icon="$icon_result" label="$app" "${style[@]}")
  done < <(awk -F'|' -v ws="$sid" '$2 == ws' <<<"$windows")
done <<<"$workspaces"

current=$(sketchybar --query bar | jq -r '.items[] | select(test("^(app|win)\\."))')
if [ "$(printf '%s\n' "${dynamic[@]}")" != "$current" ]; then
  # rebuild: drop old app/window items and brackets, add the new ones, then put everything in order
  rebuild=()
  for item in $current $(sketchybar --query bar | jq -r '.items[] | select(startswith("ws."))'); do
    rebuild+=(--remove "$item")
  done
  rebuild+=("${add_args[@]}")
  for item in "${dynamic[@]}"; do
    case $item in
      app.*) rebuild+=(--set "$item" icon.font="$APP_FONT" icon.y_offset=-1 label.drawing=off
        background.drawing=off padding_left=0 padding_right=0 icon.padding_left=3
        click_script="aerospace focus --window-id ${item#app.}") ;;
      win.*) rebuild+=(--set "$item" icon.font="$APP_FONT" icon.y_offset=-1
        click_script="aerospace focus --window-id ${item#win.}") ;;
    esac
  done
  while IFS='|' read -r sid _; do
    var="members_$(key "$sid")"
    # shellcheck disable=SC2206 # item names have no spaces
    rebuild+=(--add bracket "ws.$sid" "space.$sid" ${!var}
      --set "ws.$sid" background.corner_radius=6 background.height=24)
  done <<<"$workspaces"
  rebuild+=(--reorder "${order[@]}")
  sketchybar "${rebuild[@]}"
fi

sketchybar "${set_args[@]}"
