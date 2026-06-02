#!/usr/bin/env python3

from pathlib import Path
import shutil

paths = [
    ("~/.config/nvim", "./"),
    ("~/.config/hypr", "./"),
    ("~/.clang-format", "./"),
    ("~/.clangd", "./"),

    ("~/.config/kitty", "./.config"),
    ("~/.config/ghostty", "./.config"),
    ("~/.config/dunst", "./.config"),
    ("~/.config/eww", "./.config"),
    ("~/.config/fastfetch", "./.config"),
    ("~/.config/fish", "./.config"),
    ("~/.config/rofi", "./.config"),
    ("~/.config/wlogout", "./.config"),

    ("~/.local/bin/brightness.sh", "./bin"),
    ("~/.local/bin/pywal.sh", "./bin"),
    ("~/.local/bin/mic.sh", "./bin"),
    ("~/.local/bin/volume.sh", "./bin"),
]

for src_path, dst_dir in paths:
    src = Path(src_path).expanduser()
    dst_dir = Path(dst_dir)

    dst = dst_dir / src.name

    dst.parent.mkdir(parents=True, exist_ok=True)

    if src.is_dir():
        shutil.copytree(src, dst, dirs_exist_ok=True)
    else:
        shutil.copy2(src, dst)

    print(f"Copied {src} -> {dst}")
