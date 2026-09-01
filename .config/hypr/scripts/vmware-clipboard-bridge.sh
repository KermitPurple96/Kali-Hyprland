#!/bin/sh
# Bridge Hyprland's native Wayland clipboard with the XWayland CLIPBOARD
# selection, so VMware host<->guest clipboard sync (clipboard_fix.sh /
# vmtoolsd -n vmusr) actually reaches it.
#
# vmtoolsd only ever speaks X11 -- it watches the CLIPBOARD selection on
# XWayland's :0. That is fine for an i3 (pure X11) session, but every
# client in a Hyprland session is Wayland-native by default (`hyprctl
# clients` shows xwayland: 0 for kitty, Firefox, all of it), and Hyprland
# does not bridge the two clipboards on its own. Confirmed by hand:
# content set with wl-copy is invisible to xclip on :0, and content set
# with xclip on :0 never reaches wl-paste, in either direction. So without
# this, copying in a real (Wayland-native) window never reaches the host,
# and host copies never reach the guest, despite vmtoolsd running fine.
#
# wl-clipboard has no equivalent to X11's XFixes selection-owner-change
# event, so the X11 -> Wayland leg has to poll -- the same tradeoff
# vmware-autofit.sh already makes for the display-resize gap. The
# Wayland -> X11 leg is event-driven via `wl-paste --watch`.
#
# A shared "last value" file stops the two legs from echoing each other's
# writes back and forth forever.

set -eu

INTERVAL="${VMWARE_CLIPBOARD_BRIDGE_INTERVAL:-1}"
export DISPLAY="${DISPLAY:-:0}"
export STATE="${XDG_RUNTIME_DIR:-/tmp}/vmware-clipboard-bridge.last"
: > "$STATE" 2>/dev/null || true

# One instance per session -- a stray manual run or a restarted session
# would otherwise stack watchers/pollers that fight each other.
exec 9>"${XDG_RUNTIME_DIR:-/tmp}/vmware-clipboard-bridge.lock"
flock -n 9 || exit 0

cleanup() { kill 0 2>/dev/null || true; }
trap cleanup EXIT INT TERM

# Wayland -> X11 (event-driven). $STATE and $DISPLAY are exported above,
# so the callback -- run by wl-paste in a child process -- inherits both
# without needing to be spliced into the command string.
wl-paste --type text --watch sh -c '
    new="$(cat)"
    [ -n "$new" ] || exit 0
    old="$(cat "$STATE" 2>/dev/null || true)"
    [ "$new" = "$old" ] && exit 0
    printf %s "$new" > "$STATE"
    printf %s "$new" | xclip -selection clipboard
' &

# X11 -> Wayland (polled -- nothing to watch, so reconcile on an interval).
while :; do
    new="$(xclip -selection clipboard -o 2>/dev/null || true)"
    old="$(cat "$STATE" 2>/dev/null || true)"
    if [ -n "$new" ] && [ "$new" != "$old" ]; then
        printf %s "$new" > "$STATE"
        printf %s "$new" | wl-copy
    fi
    sleep "$INTERVAL"
done
