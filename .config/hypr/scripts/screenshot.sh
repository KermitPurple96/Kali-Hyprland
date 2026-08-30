#!/bin/sh
# Wayland replacement for kali-clean's `flameshot gui` (SUPER+Shift+P).
# Drag a region: it lands on the clipboard *and* in your pictures directory.

set -eu

dir=$(xdg-user-dir PICTURES 2>/dev/null || true)
[ -n "$dir" ] && [ -d "$dir" ] || dir="$HOME"

file="$dir/screenshot-$(date +%Y%m%d-%H%M%S).png"

region=$(slurp -d) || exit 0          # Esc during selection = quiet exit
grim -g "$region" "$file"
wl-copy < "$file"

command -v notify-send >/dev/null 2>&1 && \
    notify-send -i "$file" "Screenshot" "Copied to clipboard\n$file"
