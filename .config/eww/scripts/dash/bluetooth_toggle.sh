#!/bin/bash
# Toggles bluetooth power on/off.
if bluetoothctl show 2>/dev/null | grep -q "Powered: yes"; then
    bluetoothctl power off
else
    bluetoothctl power on
fi
