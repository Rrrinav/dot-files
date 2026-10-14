#!/bin/bash
# Prints the active WiFi SSID, or a disconnected indicator.
ssid=$(nmcli -t -f active,ssid dev wifi 2>/dev/null | grep '^yes' | cut -d: -f2)

if [ -n "$ssid" ]; then
    echo " $ssid"
else
    # Check ethernet fallback
    if nmcli -t -f type,state dev 2>/dev/null | grep -q "^ethernet:connected"; then
        echo " Ethernet"
    else
        echo " Disconnected"
    fi
fi
