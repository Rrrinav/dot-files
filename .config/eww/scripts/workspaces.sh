#!/bin/bash

generate_workspaces() {
    # 1. Get the currently active workspace ID
    active=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .activeWorkspace.id')

    # 2. Get list of ALL occupied workspace IDs from Hyprland
    occupied_list=$(hyprctl workspaces -j | jq -r '.[].id')

    # 3. Combine persistent 1-6 and occupied IDs, then sort unique
    #    We use 'printf' to combine them with newlines safely, then 'sort -nu' handles duplicates.
    #    This ensures we get a clean list of numbers.
    sorted_targets=$(printf "%s\n%s" "$(seq 1 6)" "$occupied_list" | sort -nu)

    # 4. Generate the EWW widget string
    echo -n "(box :class \"works\" :orientation \"h\" :spacing 5 :space-evenly false :valign \"center\" "

    # Use a FOR loop which splits by whitespace/newlines automatically.
    # This fixes the issue where "6" and "8" were being read as one line "6 8".
    for i in $sorted_targets; do
        # Safety check for empty strings
        [ -z "$i" ] && continue

        class="empty"

        # Check if 'i' is in the occupied list
        if echo "$occupied_list" | grep -q "^$i$"; then
            class="occupied"
        fi

        # Check if 'i' is the active workspace
        if [ "$i" == "$active" ]; then
            class="current"
        fi

        echo -n "(eventbox :cursor \"pointer\" :onclick \"hyprctl dispatch workspace $i\" (box :class \"ws-btn $class\" :valign \"center\" (label :text \"$i\" :halign \"center\" :valign \"center\")))"
    done

    echo ")"
}

# Run generation once on startup
generate_workspaces

# Listen for Hyprland events to update instantly
socat -u UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock - | while read -r event; do
    case $event in
        workspace*|focusedmon*|createworkspace*|destroyworkspace*|movewindow*)
            generate_workspaces
            ;;
    esac
done
