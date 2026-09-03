#!/bin/bash
 
 
. /usr/share/i3blocks/copy-to-clipboard.sh

domain=$(/usr/bin/cat /home/kermit/.config/bin/domain.txt)
 
if [[ $domain =~ ^[a-zA-Z0-9_-]+\.[a-zA-Z]+$ ]]; then
   
  copy_on_click "$domain"
  echo "$domain  "
 
else
    echo "$(echo "no domain  ")"
fi
