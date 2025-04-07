#!/bin/sh

# The wifi_change event supplies a $INFO variable in which the current SSID
# is passed to the script.

LABEL=$(/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I | awk 'NR==13 {print $2}')

WIFI=${LABEL:-"No connection"}

sketchybar --set $NAME label="${WIFI::12}"
