#!/bin/sh

# The wifi_change event supplies a $INFO variable in which the current SSID
# is passed to the script.

# https://github.com/noperator/wifi-unredactor/tree/main
IP_ADDRESS=$(~/Applications/wifi-unredactor.app/Contents/MacOS/wifi-unredactor | jq '.ssid' -r)

WIFI=${IP_ADDRESS:-"No connection"}

sketchybar --set $NAME label="${WIFI::12}"
