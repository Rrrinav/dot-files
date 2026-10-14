#!/bin/bash
sleep 0.2
grim -g "$(slurp)" - | wl-copy
notify-send "Screenshot" "Copied to clipboard" -i camera-photo
