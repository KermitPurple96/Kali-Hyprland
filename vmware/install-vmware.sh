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
    grim slurp wl-clipboard swaybg swaylock swayidle \
    mate-polkit wireplumber network-manager-gnome \
    fonts-hack papirus-icon-theme

echo "==> 2/5 session launcher -> /usr/local/bin/start-hyprland-vmware"
# The important one. Waits for logind Active=yes so libinput can actually open
# the keyboard, picks llvmpipe only when the host has 3D off, and writes a
# plain-language verdict to ~/hyprland-diag.txt.
sudo install -m 755 "$HERE/start-hyprland-vmware" /usr/local/bin/start-hyprland-vmware

echo "==> 3/5 session entries -> /usr/share/wayland-sessions/"
sudo install -m 644 "$HERE/hyprland.desktop"      /usr/share/wayland-sessions/hyprland.desktop
sudo install -m 644 "$HERE/hyprland-diag.desktop" /usr/share/wayland-sessions/hyprland-diag.desktop
# "Hyprland (lite)": identical config with HYPR_EFFECTS=lite. The normal
# session is already tuned for software rendering; this is the fallback if
# even that drags, reachable from the login screen instead of from a config
# file you may not be able to open.
sudo install -m 644 "$HERE/hyprland-lite.desktop" /usr/share/wayland-sessions/hyprland-lite.desktop
# "Hyprland (safe test)": the entry to use the FIRST time. Arms a 120s
# dead-man's switch, so a session you cannot see or type in ends by itself
# instead of costing you a power cycle.
sudo install -m 644 "$HERE/hyprland-test.desktop" /usr/share/wayland-sessions/hyprland-test.desktop
# uwsm is not packaged in Kali, so the entry Hyprland ships is a dead option
# that drops you straight back to the greeter. Remove it.
sudo rm -f /usr/share/wayland-sessions/hyprland-uwsm.desktop

echo "==> 4/5 desktop config -> ~/.config"
# One config, shared with the bare-metal install: ../.config/hypr/hyprland.lua.
# There is no separate VM copy any more -- the difference between a machine
# with a GPU and one without is the HYPR_EFFECTS environment variable, not a
# different file. See "PERFORMANCE" at the top of that config.
#
# Hyprland 0.51+ reads hyprland.LUA. 0.56 still loads a hyprland.conf but
# warns that support for it goes away in 0.57, so only the .lua is deployed.
REPO="$(cd "$HERE/.." && pwd)"
STAMP="$(date +%Y%m%d_%H%M%S)"

mkdir -p ~/.config/hypr/scripts ~/.config/waybar/scripts \
         ~/.config/wofi ~/.config/dunst ~/.config/kitty ~/.config/i3 ~/.wallpaper

for f in ~/.config/hypr/hyprland.lua ~/.config/kitty/kitty.conf; do
    [ -f "$f" ] && cp "$f" "$f.bak.$STAMP"
done

install -m 644 "$REPO/.config/hypr/hyprland.lua"   ~/.config/hypr/hyprland.lua
install -m 755 "$REPO"/.config/hypr/scripts/*.sh   ~/.config/hypr/scripts/
install -m 644 "$REPO/.config/waybar/config"       ~/.config/waybar/config
install -m 644 "$REPO/.config/waybar/style.css"    ~/.config/waybar/style.css
install -m 755 "$REPO"/.config/waybar/scripts/*.sh ~/.config/waybar/scripts/
install -m 644 "$REPO/.config/wofi/config"         ~/.config/wofi/config
install -m 644 "$REPO/.config/wofi/style.css"      ~/.config/wofi/style.css
install -m 644 "$REPO/.config/dunst/dunstrc"       ~/.config/dunst/dunstrc
install -m 644 "$REPO/.config/kitty/kitty.conf"    ~/.config/kitty/kitty.conf
install -m 755 "$REPO/.config/i3/clipboard_fix.sh" ~/.config/i3/clipboard_fix.sh
cp -n "$REPO"/.wallpaper/* ~/.wallpaper/ 2>/dev/null || true

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

Done. The FIRST time, log out and pick "Hyprland (safe test)".

That session arms a 120-second dead-man's switch: press CTRL+ALT+O to keep
it, and if you cannot -- black screen, dead keyboard, anything -- it ends
itself and hands you back to the login screen. No power cycle.

At ANY time, CTRL+ALT+F3 switches to a text console. Hyprland handles that
internally through logind, so it works even when every other keybind does
not. Log in there and run:

    pkill -x Hyprland

then press CTRL+ALT+F7 to get back to the login screen.

Once you are happy, use plain "Hyprland".

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

Rounded corners, blur and window animations are ON, and are tuned for a
guest with no 3D acceleration: single-pass blur, cached for surfaces that
have not changed, and no full-screen workspace animation. Do NOT go
looking for "Accelerate 3D graphics" in the VM settings to speed this up
-- on many hosts that option stops the VM booting at all, and this config
does not need it.

If it still drags, log out and pick "Hyprland (lite)": same config, same
colours, same keybinds, blur and animations off, rounded corners kept.

To see where the time actually goes, start a session with HYPR_OVERLAY=1
for Hyprland's frame-timing overlay, change one value in
~/.config/hypr/hyprland.lua, and press SUPER+SHIFT+C to reload.
DONE
