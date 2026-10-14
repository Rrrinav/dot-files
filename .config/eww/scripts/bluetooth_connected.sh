#!/bin/bash
# Bluetooth bar widget - only outputs when a device is connected.
# Returns connected device name(s), empty string otherwise.
# EWW uses :visible {bluetooth != ""} to hide when not connected.

# Get list of connected devices (MAC + Name)
# "bluetoothctl devices Connected" outputs nothing when disconnected
connected=$(bluetoothctl devices Connected 2>/dev/null | cut -d' ' -f3-)

if [ -z "$connected" ]; then
    echo ""
    exit 0
fi

# Join multiple devices with ", " and trim to keep bar compact
# Keep it short - show first device if multiple are connected
# If you want all devices comma-separated, use the paste line below instead:
# echo "$connected" | paste -sd ',' - | sed 's/,/, /g'

echo "$connected" | head -n1 | sed 's/^ *//;s/ *$//'
