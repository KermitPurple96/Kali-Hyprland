#!/bin/sh
# Shared dmenu-style prompt for the other scripts here.
#
# i3-kitty used i3-input for "rename workspace" and dmenu for clipmenu.
# Neither is a Wayland client, so this picks whichever Wayland-native
# prompt is installed and falls back to rofi through XWayland.
#
# TWO MODES, and the difference matters:
#
#   dmenu.sh "Prompt"            pick one line from a list on stdin
#   dmenu.sh --input "Prompt"    type free text; nothing is read from stdin
#
# The second mode exists because of a bug this file used to have.
# workspace-rename.sh asks for a NAME, so it has no list to offer and piped
# in an empty stdin. fuzzel's dmenu mode has --no-run-if-empty ("exit
# immediately without showing UI if stdin is empty"), which fuzzel.ini had
# switched on -- so the rename prompt exited instantly without ever drawing,
# the name came back empty, and SUPER+N appeared to do nothing at all.
#
# fuzzel's own answer is --prompt-only: same as --prompt but it "does not
# read anything from STDIN" and "sets --lines to 0". That is the free-text
# entry box.
set -eu

MODE=list
if [ "${1:-}" = "--input" ]; then MODE=input; shift; fi
prompt="${1:-}"

if command -v fuzzel >/dev/null 2>&1; then
    if [ "$MODE" = input ]; then
        exec fuzzel --dmenu --prompt-only "$prompt "
    fi
    exec fuzzel --dmenu --prompt "$prompt "
fi

if command -v wofi >/dev/null 2>&1; then
    # wofi shows its search box and returns whatever was typed even with no
    # matches, so one invocation covers both modes.
    exec wofi --dmenu --prompt "$prompt"
fi

if command -v rofi >/dev/null 2>&1; then
    exec rofi -dmenu -p "$prompt"
fi

echo "no dmenu-capable launcher installed (try: sudo apt install fuzzel)" >&2
exit 1
