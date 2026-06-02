#!/usr/bin/env sh

SINK="@DEFAULT_AUDIO_SINK@"

INFO=$(wpctl get-volume "$SINK")

# Example outputs:
# "Volume: 0.42"
# "Volume: 0.42 [MUTED]"

VOL=$(echo "$INFO" | awk '{printf "%d", $2 * 100}')
MUTED=$(echo "$INFO" | grep -q MUTED && echo yes || echo no)

# Default to Speaker
ICON=""

# Inspect the sink using wpctl (Good for USB & Bluetooth)
INSPECT=$(wpctl inspect "$SINK")

if echo "$INSPECT" | grep -qi 'headphone\|headset\|earpiece\|bluez\|usb\|dsp'; then
    ICON=""
# Fallback to checking the active port (Catches 3.5mm audio jacks perfectly)
elif command -v pactl >/dev/null && pactl list sinks | grep -A 20 "$(pactl get-default-sink)" | grep 'Active Port:' | grep -qi 'headphone\|headset'; then
    ICON=""
fi

# Output the result back to EWW
if [ "$MUTED" = "yes" ]; then
  echo "[VOL $ICON]:M"
else
  echo "[VOL $ICON]:${VOL}%"
fi
