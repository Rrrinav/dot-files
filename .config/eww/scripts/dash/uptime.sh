#!/bin/bash
# Prints a short human-readable uptime string.
uptime -p 2>/dev/null | sed 's/^up //'
