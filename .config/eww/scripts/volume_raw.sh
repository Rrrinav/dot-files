#!/usr/bin/env sh

INFO=$(wpctl get-volume @DEFAULT_AUDIO_SINK@)
echo "$INFO" | awk '{printf "%d\n", $2 * 100}'
