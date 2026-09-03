#!/bin/sh
# Port of i3-kitty's access_point.sh -- the default gateway.
. "$(dirname "$0")/fields-clipboard.sh"

iface=""
[ -r /usr/share/i3blocks/iface ] && iface=$(cat /usr/share/i3blocks/iface 2>/dev/null | tr -d '[:space:]')
[ -n "$iface" ] || iface=$(ip route show default 2>/dev/null | awk '/default/{print $5; exit}')

gw=$(ip route show default dev "$iface" 2>/dev/null | awk '/default/{print $3; exit}')
[ -n "$gw" ] || gw=$(ip route show default 2>/dev/null | awk '/default/{print $3; exit}')
[ -n "$gw" ] || gw="No gateway"
save_field gateway "$gw"
printf '%s\n' "$gw"
