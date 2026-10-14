#!/bin/bash
# Prints battery % for first connected BT device, or "" if none
mac=$(bluetoothctl devices Connected 2>/dev/null | awk '{print $2}' | head -n1)
if [ -z "$mac" ]; then
    echo ""
    exit 0
fi
info=$(bluetoothctl info "$mac" 2>/dev/null)
batt=$(echo "$info" | grep -i "Battery Percentage" | grep -o "[0-9]\+" | tail -n1)
if [ -n "$batt" ]; then
    echo "${batt}%"
else
    echo ""
fi
