#!/bin/bash

input=(
    script="$PLUGIN_DIR/input.sh"
    icon.padding_left=0
    icon.padding_right=0
)

sketchybar --add event input_change 'AppleSelectedInputSourcesChangedNotification' \
           --add item input right \
           --set input "${input[@]}" \
           --subscribe input input_change
