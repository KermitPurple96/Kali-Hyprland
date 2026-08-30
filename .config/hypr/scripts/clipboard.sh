#!/bin/sh
# i3-kitty:  bindsym $mod+c exec --no-startup-id clipmenu
#
# clipmenu is X11 (it drives dmenu and xsel), so it cannot see the Wayland
# clipboard. cliphist is the direct equivalent: cliphist-store runs in the
# background recording every clipboard change, and this picks one back out.
#
#   sudo apt install cliphist
#
# The store is started from the autostart block in hyprland.lua.
set -eu

if ! command -v cliphist >/dev/null 2>&1; then
    msg="cliphist is not installed -- clipboard history is off. sudo apt install cliphist"
    command -v notify-send >/dev/null 2>&1 && notify-send "Kali-Hyprland" "$msg"
    echo "$msg" >&2
    exit 1
fi

cliphist list | "$(dirname "$0")/dmenu.sh" "Clipboard:" | cliphist decode | wl-copy
