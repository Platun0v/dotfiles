#!/bin/bash

sketchybar --set $NAME icon="$(LC_ALL=en_EN.utf8 date '+%d/%m')" label="$(LC_ALL=en_EN.utf8 date '+%H:%M')"
