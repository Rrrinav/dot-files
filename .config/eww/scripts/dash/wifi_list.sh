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
