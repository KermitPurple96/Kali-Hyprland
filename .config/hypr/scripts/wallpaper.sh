#!/bin/sh
# Wayland stand-in for kali-clean's ~/.fehbg.
# feh cannot paint a Wayland root window, so a Wayland wallpaper daemon
# does it instead. swaybg is the one this repo installs; hyprpaper and swww
# are accepted if you already run one of them.
#
# Override the image with:  WALLPAPER=/path/to/img.jpg
# Otherwise the first of the candidates below that exists wins.

set -eu

# Pick the image ---------------------------------------------------------
img=""
if [ -n "${WALLPAPER:-}" ] && [ -f "$WALLPAPER" ]; then
    img="$WALLPAPER"
else
    for f in \
        "$HOME/.wallpaper/John_Martin_Le_Pandemonium_Louvre.jpg" \
        "$HOME/.wallpaper/23.jpg" \
        "$HOME/.wallpaper/fondo.jpg" \
        "$HOME/.wallpaper/forest.jpg"
    do
        [ -f "$f" ] && { img="$f"; break; }
    done
fi

# Pick the daemon --------------------------------------------------------
if command -v swaybg >/dev/null 2>&1; then
    pkill -x swaybg 2>/dev/null || true
    if [ -n "$img" ]; then
        exec swaybg -m fill -i "$img"
    fi
    # Nothing found: fall back to kali-clean's bar colour, not black.
    exec swaybg -c '1C1D2B'
fi

if command -v hyprpaper >/dev/null 2>&1 && [ -n "$img" ]; then
    pkill -x hyprpaper 2>/dev/null || true
    printf 'preload = %s\nwallpaper = ,%s\nsplash = false\n' "$img" "$img" \
        > "${XDG_RUNTIME_DIR:-/tmp}/hyprpaper.conf"
    exec hyprpaper -c "${XDG_RUNTIME_DIR:-/tmp}/hyprpaper.conf"
fi

if command -v swww-daemon >/dev/null 2>&1 && [ -n "$img" ]; then
    swww-daemon & sleep 1; exec swww img "$img"
fi

# No wallpaper daemon installed. Say so once, out loud, instead of dying
# silently and leaving the user staring at Hyprland's default backdrop.
msg="No Wayland wallpaper daemon found. Install one with: sudo apt install swaybg"
command -v notify-send >/dev/null 2>&1 && notify-send "Kali-Hyprland" "$msg"
echo "wallpaper.sh: $msg" >&2
exit 0
