#!/usr/bin/env bash
set -e

STEP=2

case "$1" in
  up)   brightnessctl s +${STEP}% ;;
  down) brightnessctl s ${STEP}%- ;;
  *)    exit 1 ;;
esac

percent=$(brightnessctl | awk -F'[(%)]' '/Current brightness/ {print $2}')

notify-send \
  -h int:value:$percent \
  -h string:x-canonical-private-synchronous:brightness \
  "Brightness" "$percent%"

