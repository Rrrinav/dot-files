#!/bin/bash

# Kill children on exit
trap "pkill -P $$" EXIT

# Config file path
config_file="/tmp/eww_cava_config"

# Create a dedicated config for EWW
# bars = 12 defines how many columns (characters) wide it is
cat << EOF > "$config_file"
[general]
framerate = 60
bars = 16

[input]
method = pulse
source = auto

[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 7
EOF

# Run cava and pipe output to sed for character mapping
# We map 0-7 to block characters
cava -p "$config_file" | sed -u 's/;//g;s/0/ /g;s/1/▂/g;s/2/▃/g;s/3/▄/g;s/4/▅/g;s/5/▆/g;s/6/▇/g;s/7/█/g;'
