#!/bin/sh
# Port of i3-kitty's target.sh -- the IP you are working on,
# kept in ~/.config/bin/target.txt.
f="$HOME/.config/bin/target.txt"
t=$(cat "$f" 2>/dev/null | tr -d '[:space:]')
case "$t" in
    [0-9]*.[0-9]*.[0-9]*.[0-9]*) printf '%s\n' "$t" ;;
    *) printf 'no target\n' ;;
esac
