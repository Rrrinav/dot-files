#!/bin/bash
# Prints "on" or "off" depending on bluetooth power state.
if bluetoothctl show 2>/dev/null | grep -q "Powered: yes"; then
    echo "on"
else
    echo "off"
fi
