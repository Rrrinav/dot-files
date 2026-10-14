#!/bin/bash
# Prints "on" if DND (dunst paused) is active, else "off"
if dunstctl is-paused 2>/dev/null | grep -q "true"; then
    echo "on"
else
    echo "off"
fi
