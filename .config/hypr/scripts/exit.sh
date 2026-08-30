#!/bin/sh
# Stand-in for i3's exit nagbar (SUPER+SHIFT+E): confirm before killing the
# session, so a fat-fingered keybind does not cost you your windows.
#
# Two things were wrong here and are fixed:
#
#  1. It called `wofi --dmenu` directly, so the confirmation used wofi even
#     with fuzzel installed, and would have failed outright on a box with
#     only fuzzel. It now goes through dmenu.sh like every other prompt
#     (SUPER+C, SUPER+N), which picks fuzzel -> wofi -> rofi.
#
#  2. It ran `hyprctl dispatch exit`. On 0.56 `hyprctl dispatch` takes a Lua
#     expression, so the bare legacy word is not guaranteed to be accepted --
#     the same trap already worked around in vmware/start-hyprland-vmware.
#     It now tries the Lua form first and keeps the legacy string, then a
#     plain pkill, as fallbacks.

set -eu

choice=$(printf 'Cancel\nExit Hyprland\n' | "$(dirname "$0")/dmenu.sh" 'End this session?')

[ "$choice" = "Exit Hyprland" ] || exit 0

hyprctl dispatch 'hl.dsp.exit()' >/dev/null 2>&1 && exit 0
hyprctl dispatch exit            >/dev/null 2>&1 && exit 0
pkill -x Hyprland
exit 0
