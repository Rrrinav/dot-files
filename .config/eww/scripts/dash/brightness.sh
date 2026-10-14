#!/bin/bash
# Prints current screen brightness as an integer percentage.
brightnessctl -m 2>/dev/null | awk -F, '{gsub("%","",$4); print $4}' || echo 0
