#!/bin/bash

CLAUDE_JSON=$(codexbar usage --provider claude --format json --no-color 2>/dev/null)
CLAUDE_PCT=$(echo "$CLAUDE_JSON" | jq -r '.[0].usage.primary.usedPercent // 0' 2>/dev/null)
CLAUDE_INT=$(echo "${CLAUDE_PCT:-0}" | awk '{printf "%.0f", $1}')

GEMINI_JSON=$(codexbar usage --provider gemini --format json --no-color 2>/dev/null)
GEMINI_PCT=$(echo "$GEMINI_JSON" | jq -r '.[0].usage.primary.usedPercent // 0' 2>/dev/null)
GEMINI_INT=$(echo "${GEMINI_PCT:-0}" | awk '{printf "%.0f", $1}')

MAX=$((CLAUDE_INT > GEMINI_INT ? CLAUDE_INT : GEMINI_INT))

if [ "$MAX" -ge 80 ]; then
  COLOR=0xfff7768e  # Tokyo Night red
elif [ "$MAX" -ge 50 ]; then
  COLOR=0xffe0af68  # Tokyo Night yellow
else
  COLOR=0xff9ece6a  # Tokyo Night green
fi

sketchybar --set $NAME label="C:${CLAUDE_INT}% G:${GEMINI_INT}%" icon.color=$COLOR label.color=$COLOR
