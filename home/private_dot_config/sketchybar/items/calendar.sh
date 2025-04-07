#!/usr/bin/env bash

calendar=(
  icon=cal
  icon.font="$FONT:Bold:13.0"
  icon.padding_right=0
  label.width=50
  label.align=right
  label.font="$FONT:Bold:13.0"
  padding_left=4
  update_freq=30
  script="$PLUGIN_DIR/calendar.sh"
  click_script="$PLUGIN_DIR/zen.sh"
)

sketchybar --add item calendar right       \
           --set calendar "${calendar[@]}" \
           --subscribe calendar system_woke