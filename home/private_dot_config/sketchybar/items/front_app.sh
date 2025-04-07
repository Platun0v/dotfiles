#!/usr/bin/env bash

FRONT_APP_SCRIPT='[ "$SENDER" = "front_app_switched" ] && sketchybar --set $NAME label="$INFO"'

front_app=(
  icon.drawing=off
  label.font="$FONT:Bold:12.0"
  associated_display=active
  label.padding_left=7
  script="$FRONT_APP_SCRIPT"
)

sketchybar --add item front_app q         \
           --set front_app "${front_app[@]}" \
           --subscribe front_app front_app_switched
