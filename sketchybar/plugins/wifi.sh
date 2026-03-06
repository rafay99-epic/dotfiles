#!/bin/bash

WIFI_IF="en0"

if [ "$SENDER" = "mouse.clicked" ]; then
  AS_LIST=$(networksetup -listpreferredwirelessnetworks $WIFI_IF 2>/dev/null \
    | tail -n +2 \
    | sed 's/^[[:space:]]*//' \
    | sed '/^$/d' \
    | sed 's/"/\\"/g' \
    | awk '{print "\"" $0 "\""}' \
    | tr '\n' ',' \
    | sed 's/,$//')

  if [ -z "$AS_LIST" ]; then
    open "x-apple.systempreferences:com.apple.wifi-settings-extension"
    exit 0
  fi

  CHOICE=$(osascript -e "choose from list {$AS_LIST} with title \"Wi-Fi\" with prompt \"Select network:\"" 2>/dev/null)

  if [ "$CHOICE" != "false" ] && [ -n "$CHOICE" ]; then
    networksetup -setairportnetwork $WIFI_IF "$CHOICE"
    sleep 2
  fi
fi

SSID=$(networksetup -getairportnetwork $WIFI_IF 2>/dev/null | sed 's/Current Wi-Fi Network: //')

if [ -z "$SSID" ] || echo "$SSID" | grep -q "not associated"; then
  ICON="○"
  ICON_COLOR=0xff565f89
  LABEL="No Wi-Fi"
  LABEL_COLOR=0xff565f89
else
  ICON="●"
  ICON_COLOR=0xff7aa2f7
  LABEL="$SSID"
  LABEL_COLOR=0xffffffff
fi

sketchybar --set $NAME icon="$ICON" icon.color=$ICON_COLOR label="$LABEL" label.color=$LABEL_COLOR
