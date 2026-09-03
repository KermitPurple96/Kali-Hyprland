#!/bin/sh
# waybar on-click handler, wired in as e.g.
#   "on-click": "$HOME/.config/waybar/scripts/copy-field.sh vpn"
#
# Copies that field's last known value (saved by the module's own script,
# see fields-clipboard.sh) to the clipboard -- whatever the bar is showing
# right now, no re-fetch.

. "$(dirname "$0")/fields-clipboard.sh"

val=$(field_value "$1") && printf '%s' "$val" | wl-copy
exit 0
