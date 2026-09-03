#!/bin/bash

. /usr/share/i3blocks/copy-to-clipboard.sh

ttl=$(/usr/bin/cat /home/kermit/.config/bin/ttl.txt)
target_name=$(/usr/bin/cat /home/kermit/.config/bin/target_sys.txt)

if [[ $ttl == "windows" ]]; then
  
    copy_on_click "$target_name"
    echo -ne "$target_name  "

elif [[ $ttl == "linux" ]]; then

    copy_on_click "$target_name"
    echo -ne "$target_name  "

elif [[ $ttl == "" ]]; then

  echo -ne " $(echo "no system")"

fi
