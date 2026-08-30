#!/bin/sh
# Launch Firefox so the window lands on THIS session.
#
# THE PROBLEM
# Firefox is single-instance per profile, and it finds the running instance
# over D-Bus. Kali uses dbus-user-session, which gives one session bus per
# USER -- not per login session -- so a Firefox started on the X11 session
# (tty7) is visible to a Firefox started on the Hyprland session (tty3).
# The second launch therefore does not open a window: it asks the first
# instance to open one, and that window appears on the OTHER screen.
#
# Confirmed on this machine: the running firefox-esr belonged to
# logind session 13 with DISPLAY=:0.0 and XDG_VTNR=7, while Hyprland was
# session 19 on tty3 with DISPLAY unset.
#
# This only happens while two graphical sessions are logged in at once,
# which is a testing situation. With Hyprland as the only session it never
# occurs, and plain `firefox` is fine.
#
# WHAT THIS DOES
# If no Firefox is running, start it normally -- same profile, same
# bookmarks, nothing unusual.
#
# If one IS already running (i.e. on the other session), start an
# independent instance on its own profile instead:
#   MOZ_NO_REMOTE=1 / --no-remote  stop it handing the request to the
#                                  running instance over D-Bus
#   -P hyprland --new-instance     a separate profile, because the running
#                                  instance holds the lock on the default
#                                  one and two processes cannot share it
#
# The "hyprland" profile is created on first use. It starts empty --
# separate history and bookmarks -- which is the unavoidable cost of having
# two Firefoxes up at the same time.

set -eu

FF=$(command -v firefox || command -v firefox-esr || true)
[ -n "$FF" ] || {
    command -v notify-send >/dev/null 2>&1 && notify-send "Kali-Hyprland" "Firefox no está instalado"
    echo "firefox not found" >&2; exit 1
}

# Anything already running that is a real Firefox process?
if pgrep -u "$(id -u)" -f '/firefox(-esr)?( |$)' >/dev/null 2>&1; then
    PROFILES="$HOME/.mozilla/firefox/profiles.ini"
    if ! grep -q '^Name=hyprland$' "$PROFILES" 2>/dev/null; then
        "$FF" -CreateProfile hyprland >/dev/null 2>&1 || true
    fi
    command -v notify-send >/dev/null 2>&1 && notify-send "Firefox" \
        "Ya hay una instancia en otra sesión. Abriendo una independiente con el perfil 'hyprland'."
    exec env MOZ_NO_REMOTE=1 MOZ_ENABLE_WAYLAND=1 \
        "$FF" --no-remote --new-instance -P hyprland "$@"
fi

exec env MOZ_ENABLE_WAYLAND=1 "$FF" "$@"
