#!/bin/bash
# Disconnect all connected Bluetooth devices (used by bar hover button)
# Runs without blocking eww

connected=$(bluetoothctl devices Connected 2>/dev/null | awk '{print $2}')

if [ -z "$connected" ]; then
    notify-send "Bluetooth" "No device connected" -t 1500 2>/dev/null &
    exit 0
fi

for mac in $connected; do
    bluetoothctl disconnect "$mac" 2>/dev/null &
done
wait

# Optional feedback
name=$(bluetoothctl devices Connected 2>/dev/null | cut -d' ' -f3- | head -n1)
if [ -z "$name" ]; then
    # If still shows before poll updates, use previous name from tooltip
    notify-send "Bluetooth" "Disconnecting..." -t 1500 2>/dev/null &
else
    notify-send "Bluetooth" "Disconnected" -t 1500 2>/dev/null &
fi
