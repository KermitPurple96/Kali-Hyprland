#!/bin/bash

. /usr/share/i3blocks/copy-to-clipboard.sh

INTERFACE=$(cat /usr/share/i3blocks/iface)
GATEWAY=$(ip route show dev "$INTERFACE" | grep default | awk '{print $3}')

if [[ -n "$GATEWAY" ]]; then
  copy_on_click "$GATEWAY"
  echo "Gateway: $GATEWAY"
else
  echo "No gateway"
fi
