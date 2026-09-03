#!/bin/sh
# Port of i3-kitty's target.sh -- the IP you are working on,
# kept in ~/.config/bin/target.txt.
. "$(dirname "$0")/fields-clipboard.sh"

f="$HOME/.config/bin/target.txt"
t=$(cat "$f" 2>/dev/null | tr -d '[:space:]')
case "$t" in
    [0-9]*.[0-9]*.[0-9]*.[0-9]*) save_field target "$t"; printf '%s\n' "$t" ;;
    *) save_field target "no target"; printf 'no target\n' ;;
esac
