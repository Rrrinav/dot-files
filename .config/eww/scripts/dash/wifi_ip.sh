#!/bin/bash
# Prints local IP for active connection, or "--" if none
ip=$(nmcli -t -f ip4.address dev show 2>/dev/null | grep -v "127.0" | head -n1 | cut -d: -f2 | cut -d/ -f1)
if [ -n "$ip" ]; then
    echo "$ip"
else
    echo "--"
fi
