#!/bin/bash

start_time=$(/usr/bin/cat /home/kermit/.config/bin/session.txt)

if [[ -s /home/kermit/.config/bin/session.txt ]]; then
    local now elapsed elapsed_str
    now=$(date +%s)
    elapsed=$((now - start_time))
    elapsed_str=$(date -u -d @$elapsed +%H:%M:%S)
    echo "$elapsed_str"
fi
