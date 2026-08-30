#!/bin/sh
# Application launcher for Kali-Hyprland (SUPER+D).
#
# i3-kitty used `rofi -show run`. rofi is X11-only, so under Wayland it runs
# through XWayland -- it works, but it is the slowest of the three options
# here on a machine with no GPU.
#
# Preference order, fastest first:
#
#   fuzzel  native Wayland, software renderer, in-memory desktop index.
#           This is the one to have; see ~/.config/fuzzel/fuzzel.ini.
#   wofi    GTK. Works, but re-matches and repaints the whole layer on
#           every keystroke, which is what made SUPER+D stutter.
#   rofi    the i3-kitty original, via XWayland. Last resort.
#
# Install the fast one with:  sudo apt install fuzzel

if command -v fuzzel >/dev/null 2>&1; then
    exec fuzzel
fi

if command -v wofi >/dev/null 2>&1; then
    # --no-actions and a plain `contains` match keep wofi as light as it
    # can be made; see the config for the rest.
    exec wofi --show drun --no-actions
fi

if command -v rofi >/dev/null 2>&1; then
    exec rofi -show drun
fi

command -v notify-send >/dev/null 2>&1 && \
    notify-send "Kali-Hyprland" "No launcher installed. Try: sudo apt install fuzzel"
exit 1
