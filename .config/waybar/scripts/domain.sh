#!/bin/sh
# Port of i3-kitty's domain.sh -- ~/.config/bin/domain.txt
f="$HOME/.config/bin/domain.txt"
d=$(cat "$f" 2>/dev/null | tr -d '[:space:]')
if printf '%s' "$d" | grep -qE '^[a-zA-Z0-9_-]+\.[a-zA-Z]+$'; then
    printf '%s\n' "$d"
else
    printf 'no domain\n'
fi
