#!/bin/bash
 
 
target=$(/usr/bin/cat ~/.config/bin/target.txt)
 
if [[ $target =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
   
  echo "$target"
 
else
    echo "$(echo "no target")"
fi
