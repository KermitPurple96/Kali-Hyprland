#!/bin/sh
# Stand-in for i3's exit nagbar (SUPER+Shift+E): confirm before killing
# the session, so a fat-fingered keybind does not cost you your windows.

choice=$(printf 'Cancel\nExit Hyprland\n' | \
    wofi --dmenu --prompt 'End this session?' --lines 3 --columns 1 --width 320 --height 140 --hide-scroll)

[ "$choice" = "Exit Hyprland" ] && hyprctl dispatch exit
exit 0
