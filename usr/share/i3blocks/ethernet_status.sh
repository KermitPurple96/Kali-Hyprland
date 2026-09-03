#!/bin/bash
#ADD as ~/.config/bin/ethernet_status.sh

. /usr/share/i3blocks/copy-to-clipboard.sh

INTERFACE=$(cat /usr/share/i3blocks/iface)
IP=$(/usr/sbin/ifconfig | grep "$INTERFACE" -A1 | grep inet | awk '{print $2}')
if [[ "$IP" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
  copy_on_click "$IP"
  echo "$IP"
else
  echo "Disconnected"
fi
