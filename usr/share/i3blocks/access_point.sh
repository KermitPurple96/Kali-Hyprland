#!/bin/bash

INTERFACE=$(cat /usr/share/i3blocks/iface)
GATEWAY=$(ip route show dev "$INTERFACE" | grep default | awk '{print $3}')

if [[ -n "$GATEWAY" ]]; then
  echo "Gateway: $GATEWAY"
else
  echo "No gateway"
fi
