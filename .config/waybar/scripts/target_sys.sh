#!/bin/sh
# Port of i3-kitty's target_sys.sh -- shows the target host name with a
# Windows or Linux glyph, chosen by ~/.config/bin/ttl.txt.
. "$(dirname "$0")/fields-clipboard.sh"

ttl=$(cat "$HOME/.config/bin/ttl.txt" 2>/dev/null | tr -d '[:space:]')
name=$(cat "$HOME/.config/bin/target_sys.txt" 2>/dev/null | tr -d '[:space:]')

case "$ttl" in
    windows) save_field target_sys "$name"; printf '%s \n' "$name" ;;
    linux)   save_field target_sys "$name"; printf '%s \n' "$name" ;;
    *)       save_field target_sys "no system"; printf 'no system\n' ;;
esac
