#!/usr/bin/env bash
set -e

SOURCE='@DEFAULT_AUDIO_SOURCE@'

wpctl set-mute $SOURCE toggle

state=$(wpctl get-volume $SOURCE | grep -q MUTED && echo "Muted" || echo "Unmuted")

notify-send \
  -h string:x-canonical-private-synchronous:mic \
  "Microphone" "$state"

