#!/bin/bash
playerctl -a metadata --format '{"status": "{{status}}", "artist": "{{artist}}", "title": "{{title}}", "cover": "{{mpris:artUrl}}"}' -F 2>/dev/null
