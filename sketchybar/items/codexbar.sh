#!/bin/bash

sketchybar --add item codexbar right \
           --set codexbar update_freq=60        \
                          icon="✦"              \
                          icon.color=$GREEN      \
                          label="C:-- G:--"      \
                          label.color=$GREEN     \
                          script="$PLUGIN_DIR/codexbar.sh"
