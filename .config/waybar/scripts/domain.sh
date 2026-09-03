#!/bin/sh
# Port of i3-kitty's domain.sh -- ~/.config/bin/domain.txt
. "$(dirname "$0")/fields-clipboard.sh"

f="$HOME/.config/bin/domain.txt"
d=$(cat "$f" 2>/dev/null | tr -d '[:space:]')
if printf '%s' "$d" | grep -qE '^[a-zA-Z0-9_-]+\.[a-zA-Z]+$'; then
    save_field domain "$d"
    printf '%s\n' "$d"
else
    save_field domain "no domain"
    printf 'no domain\n'
fi
