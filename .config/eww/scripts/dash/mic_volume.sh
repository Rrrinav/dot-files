#!/bin/bash
# Prints mic volume percent 0-100
wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null | awk '{printf "%d", $2*100}'
