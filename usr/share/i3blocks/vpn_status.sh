#!/bin/bash
# ADD as ~/.config/bin/hackthebox_status.sh
 
#IF=$(/usr/sbin/ifconfig | grep tun0 | awk '{print $1}' | tr -d ':')


#[[ ! -d /sys/class/net/${IF} ]] && exit


#if [[ "$(cat /sys/class/net/$IF/operstate)" = 'up' ]]; then



#!/bin/bash
# ADD as ~/.config/bin/hackthebox_status.sh
 
IFACE=$(/usr/sbin/ifconfig | grep tun0 | awk '{print $1}' | tr -d ':')
IFACE2=$(/usr/sbin/ifconfig | grep tap0 | awk '{print $1}' | tr -d ':')

 
if [ "$IFACE" = "tun0" ]; then
  echo "VPN: $(/usr/sbin/ifconfig | grep tun0 -A1 | grep inet | awk '{print $2}')"
else
  echo "Disconnected"
fi
if [ "$IFACE2" = "tap0" ]; then
  echo "VPN: $(/usr/sbin/ifconfig | grep tap0 -A1 | grep inet | awk '{print $2}')"
else
  echo "Disconnected"
fi
#if [ "$IFACE" = "tun0" ]; then
