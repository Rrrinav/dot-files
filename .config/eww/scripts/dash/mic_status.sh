#!/bin/bash
# Prints "muted" or "live"
if wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null | grep -q "MUTED"; then
    echo "muted"
else
    echo "live"
fi
