#!/bin/sh
# Port of i3-kitty's /usr/share/i3blocks/vpn_status.sh
#
# The original shelled out to `ifconfig | grep tun0 -A1 | grep inet | awk`
# for each of tun0 and tap0, and printed TWO lines -- which i3blocks read as
# full-text + short-text, so the second one was effectively discarded and a
# tap0-only VPN showed "Disconnected". This checks both and reports whichever
# is actually up, using `ip` (ifconfig is deprecated and not always present).
for iface in tun0 tap0; do
    addr=$(ip -4 -o addr show dev "$iface" up 2>/dev/null | awk '{print $4}' | cut -d/ -f1)
    if [ -n "$addr" ]; then
        printf '%s\n' "$addr"
        exit 0
    fi
done
printf 'Disconnected\n'
