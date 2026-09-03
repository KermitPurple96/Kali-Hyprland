#!/bin/sh
# Shared by the i3blocks scripts in this directory: i3blocks re-runs a
# block's command on every click, with BLOCK_BUTTON set to which button
# (1 = left). Sourcing this gets a script "click to copy" for free --
# call copy_on_click with the value it just displayed, once it knows one.
#
#   . /usr/share/i3blocks/copy-to-clipboard.sh
#   copy_on_click "$ip"
#
# Only left click copies, so right/middle/scroll stay free for whatever
# gets bound to them later. Errors (no xclip, no DISPLAY) are swallowed --
# a failed copy should never make the block itself misbehave.

copy_on_click() {
    [ "${BLOCK_BUTTON:-}" = "1" ] || return 0
    printf '%s' "$1" | xclip -selection clipboard -in >/dev/null 2>&1
}
