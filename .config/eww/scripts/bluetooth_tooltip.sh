#!/bin/bash
# Tooltip for bluetooth bar icon - detailed info, multiline.
# Empty when not connected (widget hidden anyway).

devices=$(bluetoothctl devices Connected 2>/dev/null)

if [ -z "$devices" ]; then
    echo ""
    exit 0
fi

# Build tooltip for each connected device
first=true
echo "$devices" | while IFS= read -r line; do
    # line: "Device MAC Name"
    mac=$(echo "$line" | awk '{print $2}')
    name=$(echo "$line" | cut -d' ' -f3-)

    info=$(bluetoothctl info "$mac" 2>/dev/null)

    # Try to get battery - parse last number on Battery Percentage line (handles "0x50 (80)" and "85")
    battery=$(echo "$info" | grep -i "Battery Percentage" | grep -o "[0-9]\+" | tail -n1)
    # Fallback: some BlueZ versions expose battery via separate D-Bus property, try upower? ignore for now

    # Separator between devices (blank line except first)
    if [ "$first" = true ]; then
        first=false
    else
        echo ""
    fi

    echo "󰂯 $name"
    echo "  $mac"
    if [ -n "$battery" ]; then
        echo "  Battery: ${battery}%"
    fi
    # Optional extra: show Icon type if useful
    # icon=$(echo "$info" | grep "Icon:" | cut -d: -f2 | xargs)
    # [ -n "$icon" ] && echo "  Type: $icon"
done
