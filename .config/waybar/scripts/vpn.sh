#!/bin/sh
# Port of kali-clean's i3blocks [iface] block (instance=tun0).
# Shows the VPN address in #3BB92D when tun0 is up, and stays out of the
# way when it is not.

iface=${1:-tun0}

addr=$(ip -4 -o addr show dev "$iface" 2>/dev/null | awk '{print $4}' | cut -d/ -f1)

if [ -n "$addr" ]; then
    printf '{"text":" %s","class":"connected","tooltip":"%s is up"}\n' "$addr" "$iface"
else
    printf '{"text":"","class":"disconnected","tooltip":"%s is down"}\n' "$iface"
fi
