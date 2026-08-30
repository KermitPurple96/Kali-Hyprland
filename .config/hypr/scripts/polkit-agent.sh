#!/bin/sh
# Start whichever polkit authentication agent this machine actually has.
# Kali ships different ones depending on the desktop metapackage installed.

for agent in \
    /usr/libexec/polkit-mate-authentication-agent-1 \
    /usr/libexec/polkit-gnome-authentication-agent-1 \
    /usr/lib/x86_64-linux-gnu/libexec/polkit-kde-authentication-agent-1 \
    /usr/libexec/polkit-kde-authentication-agent-1 \
    /usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1
do
    [ -x "$agent" ] && exec "$agent"
done

exit 0
