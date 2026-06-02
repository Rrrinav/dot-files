#!/usr/bin/env sh

brightnessctl -m | awk -F, '{print int($4)}'
