#!/bin/bash

# Usage: ./window_title.sh [max_length] [type]
# Example: ./window_title.sh 30 class
# Example: ./window_title.sh 50 title

MAX_LEN="${1:-50}"   # Default to 50 chars if not provided
TYPE="${2:-title}"   # Default to 'title' if not provided

get_window_data() {
    # Fetch JSON data once
    window_info=$(hyprctl activewindow -j)

    # Handle empty desktop (no active window)
    if [ "$window_info" = "{}" ]; then
        echo ""
        return
    fi

    # Extract the requested field
    if [ "$TYPE" == "class" ]; then
        text=$(echo "$window_info" | jq -r '.class')
    else
        text=$(echo "$window_info" | jq -r '.title')
    fi

    # Truncate if longer than MAX_LEN
    if [ "${#text}" -gt "$MAX_LEN" ]; then
        text="${text:0:$MAX_LEN}..."
    fi

    echo "$text"
}

# 1. Run immediately on startup
get_window_data

# 2. Listen to socket for focus changes (instant updates)
socat -u UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock - | while read -r event; do
    case $event in
        activewindow*)
            get_window_data
            ;;
    esac
done
