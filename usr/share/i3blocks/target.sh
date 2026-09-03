#!/bin/bash

. /usr/share/i3blocks/copy-to-clipboard.sh
 
 
target=$(/usr/bin/cat ~/.config/bin/target.txt)
 
if [[ $target =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
   
  copy_on_click "$target"
  echo "$target"
 
else
    echo "$(echo "no target")"
fi
