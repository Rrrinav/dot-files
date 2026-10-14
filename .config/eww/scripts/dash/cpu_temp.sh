#!/bin/bash
# Prints CPU package temperature in Celsius, best-effort across sensor layouts.
temp=$(sensors 2>/dev/null | grep -m1 -E "Package id 0|Tctl|CPU" | grep -oE '[0-9]+\.[0-9]°C' | head -1 | tr -d '°C')

if [ -n "$temp" ]; then
    printf "%.0f" "$temp"
else
    echo "N/A"
fi
