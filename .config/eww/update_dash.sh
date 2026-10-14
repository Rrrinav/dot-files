#!/bin/bash

DASH_DIR="$HOME/.config/eww/scripts/dash"
mkdir -p "$DASH_DIR"

echo "Writing volume.sh..."
cat << 'EOF' > "$DASH_DIR/volume.sh"
#!/bin/bash
wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print int($2 * 100)}'
EOF

echo "Writing media.sh..."
cat << 'EOF' > "$DASH_DIR/media.sh"
#!/bin/bash
playerctl -a metadata --format '{"status": "{{status}}", "artist": "{{artist}}", "title": "{{title}}", "cover": "{{mpris:artUrl}}"}' -F 2>/dev/null
EOF

echo "Writing screenshot.sh..."
cat << 'EOF' > "$DASH_DIR/screenshot.sh"
#!/bin/bash
sleep 0.2
grim -g "$(slurp)" - | wl-copy
notify-send "Screenshot" "Copied to clipboard" -i camera-photo
EOF

echo "Writing perf_profile.sh..."
cat << 'EOF' > "$DASH_DIR/perf_profile.sh"
#!/bin/bash
powerprofilesctl get 2>/dev/null || echo "balanced"
EOF

echo "Writing perf_toggle.sh..."
cat << 'EOF' > "$DASH_DIR/perf_toggle.sh"
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
EOF

echo "Writing wifi_list.sh..."
cat << 'EOF' > "$DASH_DIR/wifi_list.sh"
#!/bin/bash
tmp=$(mktemp)
current_rate=$(nmcli -t -f active,rate dev wifi 2>/dev/null | grep '^yes' | cut -d: -f2)

nmcli -t -f SSID,SIGNAL,ACTIVE,SECURITY dev wifi list --rescan no 2>/dev/null \
  | grep -v "^:" | grep -v "^--" \
  | sort -t: -k2 -nr \
  | awk -F: '!seen[$1]++' \
  | head -n 12 > "$tmp"

if [ ! -s "$tmp" ]; then
    echo '(box :class "wifi-empty" (label :class "detail-subtitle" :text "No networks found" :halign "center"))'
    rm -f "$tmp"
    exit 0
fi

echo -n '(box :orientation "v" :spacing 4 '

while IFS=: read -r ssid signal active sec; do
    esc_yuck=$(echo "$ssid" | sed 's/\\/\\\\/g; s/"/\\"/g')
    esc_shell=$(echo "$ssid" | sed "s/'/'\\\\''/g")
    esc_tip=$(echo "$ssid" | sed 's/"/\\"/g')

    if [ "$signal" -ge 75 ]; then icon="󰤨"
    elif [ "$signal" -ge 55 ]; then icon="󰤥"
    elif [ "$signal" -ge 35 ]; then icon="󰤢"
    else icon="󰤟"
    fi
    
    if echo "$sec" | grep -qi "wpa"; then lock=""; else lock=""; fi

    if [ "$active" = "yes" ]; then
        active_class="active"
        action="󰖩"
        action_tip="Connected — $esc_tip"
        onclick="kitty -e nmtui &"
        speed_label="(label :class \"wifi-speed\" :text \"${current_rate}\")"
    else
        active_class=""
        action="󰸞"
        action_tip="Connect to $esc_tip"
        onclick="nmcli dev wifi connect '\''$esc_shell'\'' &"
        speed_label=""
    fi

    printf '(box :class "wifi-row %s" :orientation "h" :spacing 8 :space-evenly false ' "$active_class"
    printf '(label :class "wifi-icon" :text "%s") ' "$icon"
    printf '(box :orientation "v" :hexpand true :halign "start" :spacing 0 '
    printf '(label :class "wifi-ssid" :text "%s" :halign "start" :limit-width 18) ' "$esc_yuck"
    printf '(box :orientation "h" :spacing 4 :halign "start" (label :class "wifi-sec" :text "%s") (label :class "wifi-signal" :text "%s%%") %s) ' "$lock" "$signal" "$speed_label"
    printf ') '
    printf '(label :class "wifi-active" :text "%s") ' "$action"
    printf '(eventbox :cursor "pointer" :onclick "%s" :tooltip "%s" ' "$onclick" "$action_tip"
    printf '(box :class "wifi-connect" (label :text "󰸞"))) '
    printf ') '
done < "$tmp"

echo ')'
rm -f "$tmp"
EOF

echo "Writing bt_list.sh..."
cat << 'EOF' > "$DASH_DIR/bt_list.sh"
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
EOF

echo "Removing obsolete script (wifi_speed.sh)..."
rm -f "$DASH_DIR/wifi_speed.sh"

echo "Making all scripts executable..."
chmod +x "$DASH_DIR"/*.sh

echo "Done! Restart Eww to apply changes."
