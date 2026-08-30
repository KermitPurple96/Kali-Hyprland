#!/bin/bash
# Kali + Hyprland 0.56 inside a VMware guest -- full deploy on a fresh install.
#
#   git clone https://github.com/KermitPurple96/Kali-Hyprland
#   cd Kali-Hyprland/vmware && ./install-vmware.sh
#
# Run as your normal user; it calls sudo where it needs to.
# See ../VMWARE-NOTES.md for why each piece exists.

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "$EUID" -eq 0 ]; then
    echo "Do not run this as root. Run it as your user; it will sudo when needed." >&2
    exit 1
fi

echo "==> 1/5 packages"
sudo apt update
sudo apt install -y \
    hyprland xdg-desktop-portal-hyprland xwayland \
    waybar wofi dunst kitty thunar \
    grim slurp wl-clipboard swaylock swayidle \
    mate-polkit wireplumber

echo "==> 2/5 session launcher -> /usr/local/bin/start-hyprland-vmware"
# The important one. Waits for logind Active=yes so libinput can actually open
# the keyboard, picks llvmpipe only when the host has 3D off, and writes a
# plain-language verdict to ~/hyprland-diag.txt.
sudo install -m 755 "$HERE/start-hyprland-vmware" /usr/local/bin/start-hyprland-vmware

echo "==> 3/5 session entries -> /usr/share/wayland-sessions/"
sudo install -m 644 "$HERE/hyprland.desktop"      /usr/share/wayland-sessions/hyprland.desktop
sudo install -m 644 "$HERE/hyprland-diag.desktop" /usr/share/wayland-sessions/hyprland-diag.desktop
# uwsm is not packaged in Kali, so the entry Hyprland ships is a dead option
# that drops you straight back to the greeter. Remove it.
sudo rm -f /usr/share/wayland-sessions/hyprland-uwsm.desktop

echo "==> 4/5 Hyprland config -> ~/.config/hypr/hyprland.lua"
# Hyprland 0.56 reads hyprland.LUA. A hyprland.conf is ignored outright.
mkdir -p ~/.config/hypr
if [ -f ~/.config/hypr/hyprland.lua ]; then
    cp ~/.config/hypr/hyprland.lua ~/.config/hypr/hyprland.lua.bak."$(date +%Y%m%d_%H%M%S)"
fi
install -m 644 "$HERE/hyprland.lua" ~/.config/hypr/hyprland.lua

echo "==> 5/5 make Hyprland the default LightDM session"
sudo install -m 644 "$HERE/02-default-session.conf" \
    /etc/lightdm/lightdm.conf.d/02-default-session.conf
# LightDM prefers ~/.dmrc over the seat default once you have logged in once.
if [ -f ~/.dmrc ] && grep -q '^Session=' ~/.dmrc; then
    sed -i 's/^Session=.*/Session=hyprland/' ~/.dmrc
else
    printf '[Desktop]\nSession=hyprland\n' > ~/.dmrc
fi

cat <<'DONE'

Done. Log out and pick "Hyprland" (not "Hyprland (diagnostic)").

If input dies again, ~/hyprland-diag.txt has the answer at the bottom
within ~12 seconds, in plain words:

    OK:     libinput bound a keyboard ...
    BROKEN: libinput bound no keyboard, so typing cannot work.

and ~/hyprland-last.log has the full session log -- it survives a hard
power-off of the VM, which the runtime log in /run/user does not.

Rescue keybinds, deliberately not on SUPER in case the host grabs it:
    CTRL+ALT+T          terminal
    ALT+Return          terminal
    CTRL+ALT+BackSpace  exit Hyprland cleanly
DONE
