#!/bin/bash
current=$(powerprofilesctl get 2>/dev/null)

if [ "$current" = "power-saver" ]; then
    next="balanced"
elif [ "$current" = "balanced" ]; then
    next="performance"
else
    next="power-saver"
fi

powerprofilesctl set "$next"
notify-send "Performance" "Profile set to $next" -t 1500
