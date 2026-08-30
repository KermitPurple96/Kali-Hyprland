#!/bin/sh
# Port of i3-kitty's session.sh -- elapsed time since the epoch stamp in
# ~/.config/bin/session.txt.
#
# The original declared `local now elapsed elapsed_str` at script scope.
# `local` is only valid inside a function, so bash printed
#   "local: can only be used in a function"
# to stderr on every run -- once per interval, forever. It still produced
# the right time, because bash carries on after that error, so it looked
# fine in the bar while quietly filling the log. Rewritten without it.
f="$HOME/.config/bin/session.txt"
[ -s "$f" ] || { printf '\n'; exit 0; }

start=$(cat "$f" 2>/dev/null | tr -d '[:space:]')
case "$start" in ''|*[!0-9]*) printf '\n'; exit 0 ;; esac

now=$(date +%s)
elapsed=$(( now - start ))
[ "$elapsed" -lt 0 ] && elapsed=0
printf '%s\n' "$(date -u -d "@$elapsed" +%H:%M:%S)"
