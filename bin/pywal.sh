#!/bin/bash

set -x

# Specify the directory path for wallpapers
DIR="$HOME/.wallpapers"

# Cache directories
CACHE_DIR="$HOME/.cache/wal/schemes"
CACHE_WALLPAPER_DIR="$HOME/.cache/wallpapers"
CACHE_FILE="$CACHE_WALLPAPER_DIR/current_wallpaper.png"

# Ensure directories exist
mkdir -p "$CACHE_DIR" "$CACHE_WALLPAPER_DIR"

# REMOVED: Sourcing .bashrc is dangerous in scripts and unnecessary here.
# REMOVED: "rm -f" of schemes. WAL overwrites them anyway; deleting them first just wastes SSD IO.

# Initialize empty string for Rofi
cmd=""

# Build the list of files for Rofi (Fast method)
# We use null separators for safer filename handling
while IFS= read -r -d '' file; do
    cmd="${cmd}${file}\0icon\x1f${file}\n"
done < <(find "$DIR" -maxdepth 1 -type f -print0)

# Prompt user
file=$(echo -en "$cmd" | PREVIEW=true rofi -dmenu -i -p "Select wallpaper:" -show-icons)

# Exit if cancelled
if [[ -z "$file" ]]; then
    exit 0
fi

# 1. Generate Colors (Silent)
wal -i "$file" -n -q -t

# 2. Update Hyprland Colors
# We read the color file directly to avoid complex parsing
echo "Updating Hyprland colors..."
hyprTheme="$HOME/.cache/wal/colors-hyprland.conf"
# Use a simple template to write the config file in one go (Less Disk IO)
{
    source "$HOME/.cache/wal/colors.sh"
    echo "\$color0 = rgb(${color0/'#'/})"
    echo "\$color1 = rgb(${color1/'#'/})"
    echo "\$color2 = rgb(${color2/'#'/})"
    echo "\$color3 = rgb(${color3/'#'/})"
    echo "\$color4 = rgb(${color4/'#'/})"
    echo "\$color5 = rgb(${color5/'#'/})"
    echo "\$color6 = rgb(${color6/'#'/})"
    echo "\$color7 = rgb(${color7/'#'/})"
    echo "\$color8 = rgb(${color8/'#'/})"
    echo "\$color9 = rgb(${color9/'#'/})"
    echo "\$color10 = rgb(${color10/'#'/})"
    echo "\$color11 = rgb(${color11/'#'/})"
    echo "\$color12 = rgb(${color12/'#'/})"
    echo "\$color13 = rgb(${color13/'#'/})"
    echo "\$color14 = rgb(${color14/'#'/})"
    echo "\$color15 = rgb(${color15/'#'/})"
} > "$hyprTheme"

# Reload Hyprland instantly
hyprctl reload

# 2b. Reload Ghostty colors
echo "Updating Ghostty colors..."
# wal auto-writes to ~/.cache/wal/colors-ghostty.conf via the template
# Ghostty picks up config-file changes on reload
pkill -SIGUSR2 ghostty 2>/dev/null || true

# 3. Set Wallpaper (Animation)
swww img --transition-type any --transition-fps 165 --transition-pos top-right "$file" >/dev/null

# 4. Convert for Lockscreen (Only if needed)
# This is the heaviest part. We check extension to decide how to process.
extension="${file##*.}"

eww reload

if [[ "${extension,,}" == "gif" ]]; then
    # Extract first frame for non-animated lockscreens
    ffmpeg -y -i "$file" -vf "select='gte(n\,1)',scale=1920:-1:flags=lanczos" -frames:v 1 "$CACHE_FILE" >/dev/null 2>&1
elif [[ "${extension,,}" == "png" ]]; then
    # If it is already a PNG, just copy it
    cp "$file" "$CACHE_FILE"
else
    # For JPG/WEBP, convert it to a real PNG so hyprlock does not crash
    magick "$file" "$CACHE_FILE"
fi

notify-send "Theme Updated" "Wallpaper and colors applied." -a 'System'
