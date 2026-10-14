#!/bin/bash
paired=$(bluetoothctl devices 2>/dev/null)

if [ -z "$paired" ]; then
    echo '(box :class "bt-empty" (label :class "detail-subtitle" :text "No devices found" :halign "center"))'
    exit 0
fi

connected_macs=$(bluetoothctl devices Connected 2>/dev/null | awk '{print $2}')
tmp=$(mktemp)

{
    echo "$paired" | while read -r line; do
        mac=$(echo "$line" | awk '{print $2}')
        if echo "$connected_macs" | grep -q "$mac"; then echo "$line"; fi
    done
    echo "$paired" | while read -r line; do
        mac=$(echo "$line" | awk '{print $2}')
        if ! echo "$connected_macs" | grep -q "$mac"; then echo "$line"; fi
    done
} | head -n 8 > "$tmp"

echo -n '(box :orientation "v" :spacing 4 '

while IFS= read -r line; do
    mac=$(echo "$line" | awk '{print $2}')
    name=$(echo "$line" | cut -d' ' -f3-)
    esc_yuck=$(echo "$name" | sed 's/\\/\\\\/g; s/"/\\"/g')
    esc_tip=$(echo "$name" | sed 's/"/\\"/g')

    if echo "$connected_macs" | grep -q "$mac"; then
        conn_class="connected"
        status="Connected"
        action_icon="󰂭"
        action_tip="Disconnect $esc_tip"
        onclick="bluetoothctl disconnect $mac &"
        
        info=$(bluetoothctl info "$mac" 2>/dev/null)
        batt_raw=$(echo "$info" | grep -i "Battery Percentage" | grep -o "[0-9]\+" | tail -n1)
        if [ -n "$batt_raw" ]; then batt=" • ${batt_raw}%"; else batt=""; fi
    else
        conn_class=""
        status="Paired"
        action_icon="󰂯"
        action_tip="Connect $esc_tip"
        onclick="bluetoothctl connect $mac &"
        batt=""
    fi

    printf '(box :class "bt-row %s" :orientation "h" :spacing 8 :space-evenly false ' "$conn_class"
    printf '(label :class "bt-icon" :text "󰂯") '
    printf '(box :orientation "v" :hexpand true :halign "start" :spacing 0 '
    printf '(label :class "bt-name" :text "%s" :halign "start" :limit-width 18) ' "$esc_yuck"
    printf '(label :class "bt-status" :text "%s%s" :halign "start") ' "$status" "$batt"
    printf ') '
    printf '(eventbox :cursor "pointer" :onclick "%s" :tooltip "%s" ' "$onclick" "$action_tip"
    printf '(box :class "bt-action %s" (label :text "%s")))' "$conn_class" "$action_icon"
    printf ') '
done < "$tmp"

echo ')'
rm -f "$tmp"
