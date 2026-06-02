#!/bin/bash

# Path to battery (Check if yours is BAT0 or BAT1)
BAT="/sys/class/power_supply/BAT1"

# Get capacity and status
# If file doesn't exist (desktop), default to 100%
if [ -d "$BAT" ]; then
    CAP=$(cat "$BAT/capacity")
    STATUS=$(cat "$BAT/status")
else
    CAP=100
    STATUS="Full"
fi

# Define Icons
OUTPUT=""

if [ "$STATUS" = "Charging" ]; then
    OUTPUT="[BAT-CH]:$CAP%" # Charging bolt
else
    # Choose icon based on capacity level
    if [ "$CAP" == 100 ]; then
        OUTPUT="[BAT-FULL]"
    elif [ "$CAP" -ge 90 ]; then
        OUTPUT="[BAT-DIS]:$CAP%"
    elif [ "$CAP" -ge 70 ]; then
        OUTPUT="[BAT-DIS]:$CAP%"
    elif [ "$CAP" -ge 40 ]; then
        OUTPUT="[BAT-DIS]:$CAP%"
    elif [ "$CAP" -ge 15 ]; then
        OUTPUT="[BAT-DIS]:$CAP%"
    else
        OUTPUT="[BAT-DIS]:$CAP%" # Empty/Warning
    fi
fi

# Final Output: "Icon  Percentage%"
echo "$OUTPUT "
