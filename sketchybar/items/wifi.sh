#!/bin/bash

sketchybar --add item wifi right \
           --set wifi update_freq=10 \
                      script="$PLUGIN_DIR/wifi.sh" \
           --subscribe wifi mouse.clicked
