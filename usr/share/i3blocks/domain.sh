#!/bin/bash
 
 
domain=$(/usr/bin/cat /home/kermit/.config/bin/domain.txt)
 
if [[ $domain =~ ^[a-zA-Z0-9_-]+\.[a-zA-Z]+$ ]]; then
   
  echo "$domain  "
 
else
    echo "$(echo "no domain  ")"
fi
