#!/bin/bash
# Prints root filesystem usage as an integer percentage.
df -h / 2>/dev/null | awk 'NR==2{gsub("%","",$5); print $5}'
