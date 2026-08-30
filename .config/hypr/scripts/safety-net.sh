#!/bin/sh
# Dead-man's switch for testing a Hyprland session you are not yet sure of.
#
# Armed by starting the session with HYPR_SAFETY=<seconds> (the "Hyprland
# (safe test)" login entry sets 120). If nobody confirms the session is
# usable before the timer runs out, it ends the session by itself and drops
# you back at the display manager.
#
#   safety-net.sh          arm, using $HYPR_SAFETY  (no-op if unset or 0)
#   safety-net.sh --ok     disarm  (bound to CTRL+ALT+O)
#
# Confirming is deliberately a KEYBIND, not a mouse click: pressing it is
# proof that the two things that have actually broken on this machine both
# work -- libinput bound a keyboard, and keybinds are registered. Seeing the
# notification it sends is proof that rendering works. If any of those are
# broken you cannot confirm, which is exactly when you want the auto-exit.
#
# This is the second line of defence. The first is CTRL+ALT+F3, which
# Hyprland handles internally (CKeybindManager::handleVT -> libseat), so it
# works even inside a submap and even if every user keybind is broken.

set -u

RUNDIR="${XDG_RUNTIME_DIR:-/tmp}"
SENTINEL="$RUNDIR/hypr-safety-ok"

# --- disarm ------------------------------------------------------------
if [ "${1:-}" = "--ok" ]; then
    : > "$SENTINEL"
    command -v notify-send >/dev/null 2>&1 && \
        notify-send -u low "Safety net disarmed" "This session will not auto-exit."
    exit 0
fi

# --- arm ---------------------------------------------------------------
timeout="${1:-${HYPR_SAFETY:-0}}"
case "$timeout" in
    ''|*[!0-9]*) exit 0 ;;      # not a number -> not armed
esac
[ "$timeout" -gt 0 ] || exit 0

rm -f "$SENTINEL"

say() {
    command -v notify-send >/dev/null 2>&1 && notify-send -u critical "$1" "$2"
    echo "safety-net: $1 -- $2" >&2
}

say "Safety net armed (${timeout}s)" \
    "Press CTRL+ALT+O to keep this session.
Otherwise it exits by itself and returns you to the login screen.
CTRL+ALT+F3 gives you a text console at any time."

half=$((timeout / 2))
i=0
while [ "$i" -lt "$timeout" ]; do
    [ -f "$SENTINEL" ] && exit 0
    sleep 1
    i=$((i + 1))
    [ "$i" -eq "$half" ] && say "Safety net: $((timeout - i))s left" "CTRL+ALT+O to keep this session."
    [ "$((timeout - i))" -eq 10 ] && say "Safety net: 10s left" "CTRL+ALT+O now, or the session ends."
done

[ -f "$SENTINEL" ] && exit 0

say "Safety net: ending session" "Nobody confirmed. Returning to the login screen."
sleep 1

# Ask nicely (0.56 takes a Lua expression; the pre-0.51 form is the
# fallback), then stop asking.
hyprctl dispatch 'hl.dsp.exit()' >/dev/null 2>&1 && sleep 3
pgrep -x Hyprland >/dev/null 2>&1 || exit 0

hyprctl dispatch exit >/dev/null 2>&1 && sleep 3
pgrep -x Hyprland >/dev/null 2>&1 || exit 0

pkill -x Hyprland
