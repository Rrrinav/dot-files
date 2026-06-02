#!/usr/bin/env bash
set -e

STEP=5
SINK='@DEFAULT_AUDIO_SINK@'

case "$1" in
  up)    wpctl set-volume $SINK ${STEP}%+ ;;
  down)  wpctl set-volume $SINK ${STEP}%- ;;
  mute)  wpctl set-mute   $SINK toggle ;;
  *)     echo "Usage: volume.sh up|down|mute" && exit 1 ;;
esac

vol=$(wpctl get-volume $SINK | awk '{print int($2*100)}')
state=$(wpctl get-volume $SINK | grep -q MUTED && echo "Muted" || echo "$vol%")

notify-send \
  -h int:value:$vol \
  -h string:x-canonical-private-synchronous:volume \
  "Volume" "$state"

