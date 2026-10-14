#!/bin/bash
# Numeric battery percent for dashboard bars
BAT="/sys/class/power_supply/BAT1"
if [ -f "$BAT/capacity" ]; then
    cat "$BAT/capacity"
elif [ -f "/sys/class/power_supply/BAT0/capacity" ]; then
    cat "/sys/class/power_supply/BAT0/capacity"
else
    echo 100
fi
