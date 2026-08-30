#!/bin/bash
# The root-owned half of the setup, on its own.
#
#   cd Kali-Hyprland/vmware && ./update-system.sh
#
# install-vmware.sh does all of this too, but it also runs `apt update &&
# apt upgrade`, which you do not want to sit through just to refresh a
# session entry. This touches only the pieces that live outside $HOME:
#
#   * swaybg            -- without it nothing can paint a Wayland background
#   * the session launcher in /usr/local/bin
#   * the login-screen session entries, including the safe-test one
#   * removal of the broken "Hyprland (uwsm-managed)" entry
#
# Everything under ~/.config is user-owned and is handled by install.sh or
# install-vmware.sh; this script never touches it.

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"

if [ "$EUID" -eq 0 ]; then
    echo "Run this as your user, not as root. It calls sudo where it needs to." >&2
    exit 1
fi

echo "==> 1/4 swaybg"
if command -v swaybg >/dev/null 2>&1; then
    echo "    already installed"
else
    # Prefer a .deb staged next to the repo (works with no network); fall
    # back to apt. swaybg's dependencies are all part of a normal Kali
    # desktop, so neither path should pull anything unexpected.
    DEB=$(ls -1 "$HOME"/swaybg_*.deb "$REPO"/swaybg_*.deb 2>/dev/null | head -1 || true)
    if [ -n "$DEB" ]; then
        echo "    installing $DEB"
        sudo dpkg -i "$DEB"
    else
        sudo apt install -y swaybg
    fi
fi

echo "==> 2/4 session launcher -> /usr/local/bin/start-hyprland-vmware"
sudo install -m 755 "$HERE/start-hyprland-vmware" /usr/local/bin/start-hyprland-vmware

echo "==> 3/4 session entries -> /usr/share/wayland-sessions/"
for entry in hyprland hyprland-lite hyprland-test hyprland-diag; do
    sudo install -m 644 "$HERE/$entry.desktop" "/usr/share/wayland-sessions/$entry.desktop"
    echo "    $entry.desktop"
done

echo "==> 4/4 removing the broken uwsm entry"
# uwsm is not packaged in Kali, so "Hyprland (uwsm-managed)" can never
# start -- picking it drops you straight back at the greeter. The Hyprland
# package reinstalls it, so this may need running again after an upgrade.
if [ -e /usr/share/wayland-sessions/hyprland-uwsm.desktop ]; then
    sudo rm -f /usr/share/wayland-sessions/hyprland-uwsm.desktop
    echo "    removed"
else
    echo "    not present"
fi

cat <<'DONE'

Done. Log out, and at the login screen pick:

    Hyprland (safe test)   <- use this FIRST

It arms a 120-second dead-man's switch. Press CTRL+ALT+O to keep the
session; if you cannot -- black screen, dead keyboard, anything -- it ends
itself and returns you here. No power cycle.

At any moment, CTRL+ALT+F3 gives you a text console. Hyprland handles that
one internally through logind, so it works even if every keybind is broken.
Log in there and run:

    pkill -x Hyprland

then CTRL+ALT+F7 to come back to the login screen.

Once you are happy, use plain "Hyprland". If it feels heavy, use
"Hyprland (lite)".
DONE
