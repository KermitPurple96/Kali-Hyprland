#!/bin/sh
# Port of i3-kitty's target_sys.sh -- shows the target host name with a
# Windows or Linux glyph, chosen by ~/.config/bin/ttl.txt.
ttl=$(cat "$HOME/.config/bin/ttl.txt" 2>/dev/null | tr -d '[:space:]')
name=$(cat "$HOME/.config/bin/target_sys.txt" 2>/dev/null | tr -d '[:space:]')

case "$ttl" in
    windows) printf '%s \n' "$name" ;;
    linux)   printf '%s \n' "$name" ;;
    *)       printf 'no system\n' ;;
esac
