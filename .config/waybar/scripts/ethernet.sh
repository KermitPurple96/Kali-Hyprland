#!/bin/sh
# Port of i3-kitty's ethernet_status.sh.
#
# The original read the interface name from /usr/share/i3blocks/iface (a
# root-owned file containing e.g. "eth0"). That still works and is checked
# first, so the existing setup keeps behaving the same; if it is missing we
# fall back to whichever interface actually holds the default route, which
# is what you want on a VM that renames NICs (ens33, enp0s3...).
iface=""
[ -r /usr/share/i3blocks/iface ] && iface=$(cat /usr/share/i3blocks/iface 2>/dev/null | tr -d '[:space:]')
[ -n "$iface" ] || iface=$(ip route show default 2>/dev/null | awk '/default/{print $5; exit}')
[ -n "$iface" ] || { printf 'Disconnected\n'; exit 0; }

addr=$(ip -4 -o addr show dev "$iface" 2>/dev/null | awk '{print $4}' | cut -d/ -f1)
[ -n "$addr" ] && printf '%s\n' "$addr" || printf 'Disconnected\n'
