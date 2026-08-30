#!/bin/sh
# Shared dmenu-style prompt for the other scripts here.
#
# i3-kitty used i3-input for "rename workspace" and dmenu for clipmenu.
# Neither is a Wayland client, so this picks whichever Wayland-native
# prompt is installed and falls back to rofi through XWayland.
#
# Usage:  dmenu.sh "Prompt text"    < list-on-stdin
#         dmenu.sh "Prompt text"    (no stdin -> free-text entry)
prompt="${1:-}"

if command -v fuzzel >/dev/null 2>&1; then
    exec fuzzel --dmenu --prompt "$prompt "
fi
if command -v wofi >/dev/null 2>&1; then
    exec wofi --dmenu --prompt "$prompt"
fi
if command -v rofi >/dev/null 2>&1; then
    exec rofi -dmenu -p "$prompt"
fi
echo "no dmenu-capable launcher installed (try: sudo apt install fuzzel)" >&2
exit 1
