#!/bin/bash
# Toggles WiFi radio on/off via nmcli.
state=$(nmcli radio wifi)

if [ "$state" == "enabled" ]; then
    nmcli radio wifi off
else
    nmcli radio wifi on
fi
