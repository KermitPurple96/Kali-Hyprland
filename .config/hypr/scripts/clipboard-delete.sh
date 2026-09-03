#!/bin/sh
# SUPER+ALT+C -- same picker as SUPER+C's clipboard.sh, but deletes the
# chosen entry from cliphist instead of pasting it. See clipboard.sh for
# why cliphist (not clipmenu) is the store under Wayland.
set -eu

if ! command -v cliphist >/dev/null 2>&1; then
    msg="cliphist is not installed -- clipboard history is off. sudo apt install cliphist"
    command -v notify-send >/dev/null 2>&1 && notify-send "Kali-Hyprland" "$msg"
    echo "$msg" >&2
    exit 1
fi

cliphist list | "$(dirname "$0")/dmenu.sh" "Delete from clipboard:" | cliphist delete
