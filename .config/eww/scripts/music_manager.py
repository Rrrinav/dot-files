#!/usr/bin/env python3

import subprocess
import json
import os
import sys
import time
import urllib.request
from urllib.parse import unquote

# Path to cache album art
CACHE_DIR = os.path.expanduser("~/.cache/eww/music")
COVER_PATH = os.path.join(CACHE_DIR, "cover.png")

if not os.path.exists(CACHE_DIR):
    os.makedirs(CACHE_DIR)


def format_time(seconds):
    """Converts seconds to M:SS format"""
    try:
        seconds = int(seconds)
        m, s = divmod(seconds, 60)
        return f"{m}:{s:02d}"
    except:
        return "0:00"


def get_metadata():
    # Use a custom separator "::" to avoid JSON syntax errors in playerctl
    # We follow (-F) to get updates on Track Change / Play / Pause
    cmd = ["playerctl", "metadata", "--format",
           "{{title}}::{{artist}}::{{status}}::{{mpris:artUrl}}::{{mpris:length}}",
           "-F"]

    process = subprocess.Popen(cmd, stdout=subprocess.PIPE, text=True)

    for line in process.stdout:
        try:
            parts = line.strip().split("::")

            if len(parts) < 3:
                continue

            title = parts[0] if parts[0] else "No Music"
            artist = parts[1] if len(parts) > 1 else "Unknown Artist"
            status = parts[2] if len(parts) > 2 else "Stopped"
            art_url = parts[3] if len(parts) > 3 else ""
            length_str = parts[4] if len(parts) > 4 else "0"

            # --- Album Art Handling ---
            local_art = ""
            if art_url.startswith("file://"):
                local_art = unquote(art_url[7:])
            elif art_url.startswith("http"):
                local_art = COVER_PATH
                try:
                    if not os.path.exists(COVER_PATH) or (time.time() - os.path.getmtime(COVER_PATH) > 60):
                        urllib.request.urlretrieve(art_url, COVER_PATH)
                except:
                    pass

            cover = local_art if local_art and os.path.exists(
                local_art) else ""

            # --- Length Calculation (Static) ---
            length_micro = int(
                length_str) if length_str and length_str.strip() else 0
            len_sec = length_micro // 1000000

            if len_sec == 0:
                len_sec = 1

            # Output JSON
            data = {
                "title": title,
                "artist": artist,
                "status": status,
                "cover": cover,
                "len_sec": len_sec,
                "len_str": format_time(len_sec)
            }

            print(json.dumps(data), flush=True)

        except Exception:
            # Fallback
            print(json.dumps({"title": "No Music", "status": "Stopped",
                  "len_sec": 100, "len_str": "0:00", "cover": ""}), flush=True)


if __name__ == "__main__":
    get_metadata()
