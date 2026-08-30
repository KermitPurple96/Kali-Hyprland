#!/bin/sh
# Auto-fit the Hyprland output to the VMware window size.
#
# open-vm-tools already does the first half of a guest resize: the host
# pushes the new window size down through vmwgfx, which publishes it as the
# preferred (first) mode on the virtual connector. The second half is
# missing under Wayland -- vmware-user applies that mode with xrandr, an
# X11 call with no Wayland equivalent -- so Hyprland keeps whatever mode it
# enumerated at startup and the desktop never fills the window.
#
# This closes the gap: watch the connector, and whenever Hyprland's mode
# differs from the connector's preferred one, switch it.
#
# Compare against Hyprland's LIVE mode, not against the last mode we set.
# Hyprland re-applies the `mode = "preferred"` monitor rule on config reload
# (SUPER+SHIFT+R) and on output hotplug, which drops it back to its own idea
# of preferred -- caching what we last applied would make those reverts
# permanent. Reading the live value re-fixes them on the next tick.
#
# The config is Lua, so `hyprctl keyword` is rejected ("can't work with
# non-legacy parsers"); hl.monitor() through `hyprctl eval` is the way in.

set -eu

INTERVAL="${VMWARE_AUTOFIT_INTERVAL:-1}"

# One watcher per session. The autostart fires once, but a stray manual run
# or a restarted session would otherwise stack instances that fight over the
# same output. Losing the lock is the normal case, not an error.
exec 9>"${XDG_RUNTIME_DIR:-/tmp}/vmware-autofit.lock"
flock -n 9 || exit 0

# Only one virtual connector is ever plugged, but its number moves around
# (Virtual-1 .. Virtual-8), so find it rather than hardcoding it.
conn=""
for c in /sys/class/drm/card*-Virtual-*/; do
    [ -r "$c/status" ] || continue
    [ "$(cat "$c/status")" = "connected" ] || continue
    conn="$c"
    break
done
[ -n "$conn" ] || { echo "vmware-autofit: no connected virtual output" >&2; exit 1; }

name=$(basename "$conn" | sed 's/^card[0-9]*-//')

# What Hyprland currently drives this output at, as WxH.
current_mode() {
    hyprctl monitors 2>/dev/null | awk -v n="$name" '
        $1 == "Monitor" && $2 == n { f = 1; next }
        f { sub(/@.*/, "", $1); print $1; exit }
    '
}

while :; do
    # The preferred mode is the first line of the connector mode list; it is
    # the entry vmwgfx rewrites on every host-side resize.
    want=$(head -n1 "$conn/modes" 2>/dev/null || true)

    # An empty list means the output is momentarily down (resize in flight,
    # DPMS blank). Wait it out rather than acting on nothing.
    if [ -n "$want" ] && [ "$want" != "$(current_mode)" ]; then
        # vmwgfx's dynamic mode always runs at 60Hz, as does every static
        # EDID fallback in the list.
        hyprctl eval "hl.monitor({output=\"$name\", mode=\"$want@60\", position=\"0x0\", scale=1})" >/dev/null 2>&1 || true
    fi

    sleep "$INTERVAL"
done
