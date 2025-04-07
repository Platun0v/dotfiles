#!/usr/bin/env bash

sketchybar --add item volume right \
    --set volume \
    icon.color=$BLUE \
    label.drawing=true \
    script="$PLUGIN_DIR/volume.sh" \
    --subscribe volume volume_change
