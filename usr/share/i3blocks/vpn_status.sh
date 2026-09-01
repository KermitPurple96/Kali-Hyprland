#!/bin/sh
# Egress-IP indicator for the i3 session. Same logic as the Hyprland bar's
# .config/waybar/scripts/vpn.sh -- keep the two in step.
#
# It answers one question: which address is our traffic leaving with?
#
#   VPN up   -> the tunnel address    (what a host on the VPN sees)
#   no VPN   -> the public address    (what a host on the internet sees)
#   neither  -> offline
#
# The original printed "VPN: <addr>" for tun0 and then a SECOND line for
# tap0 -- which i3blocks reads as short_text, so the tap0 answer was thrown
# away and a tap0-only VPN showed "Disconnected". It also shelled out to
# ifconfig, which is deprecated and not installed by default any more.
#
# i3blocks line protocol: full_text, short_text, color. The third line
# overrides the block's color= in i3blocks.conf, which is how one block
# shows three states. The icon rides in full_text for the same reason, so
# [vpn_status.sh] carries no label= -- it would print ahead of every state.

set -u

TTL=300
RUNDIR="${XDG_RUNTIME_DIR:-/tmp}"
# Shared with the waybar script on purpose: the answer does not depend on
# which session asked, so whichever bar ran last saves the other a lookup.
CACHE="$RUNDIR/egress-ip"

ICON_VPN=""
ICON_EXTERNAL=""
ICON_OFFLINE=""

emit() {    # emit <icon> <colour> <text>
    printf '%s %s\n%s\n%s\n' "$1" "$3" "$3" "$2"
    exit 0
}

vpn()      { emit "$ICON_VPN"      '#38DE07' "$1"; }
external() { emit "$ICON_EXTERNAL" '#ffa500' "$1"; }
offline()  { emit "$ICON_OFFLINE"  '#ff0000' "$1"; }

# --- 1. a VPN interface, if there is one -------------------------------
# OpenVPN is tun/tap, WireGuard is wg (and whatever name the consumer
# clients pick), PPTP/L2TP is ppp.
#
# Deliberately NOT "which interface holds the default route": on an HTB or
# OffSec VPN the default route stays on the WAN and only the lab subnet is
# pushed through tun0. The tunnel address is still the one the targets see,
# so it is the one to show.
addr=$(ip -4 -o addr show up scope global 2>/dev/null | awk '
    $2 ~ /^(tun|tap|wg|ppp|nordlynx|proton|mullvad|tailscale)/ {
        split($4, a, "/"); print a[1]; exit
    }')
[ -n "$addr" ] && vpn "$addr"

# --- 2. no VPN: the public address of the default route ----------------
route=$(ip route show default 2>/dev/null | head -n 1)
[ -n "$route" ] || offline "offline"

now=$(date +%s)

cached_at=0
cached_key=""
cached_ip=""
if [ -r "$CACHE" ]; then
    cached_at=$(sed -n 1p "$CACHE" 2>/dev/null)
    cached_key=$(sed -n 2p "$CACHE" 2>/dev/null)
    cached_ip=$(sed -n 3p "$CACHE" 2>/dev/null)
    case "$cached_at" in
        ''|*[!0-9]*) cached_at=0 ;;
    esac
fi

# Cached on time AND on the routing state, so dropping the VPN or moving to
# another network refetches at once instead of showing a stale address for
# up to $TTL.
age=$((now - cached_at))
if [ -n "$cached_ip" ] && [ "$cached_key" = "$route" ] && [ "$age" -ge 0 ] && [ "$age" -lt "$TTL" ]; then
    external "$cached_ip"
fi

# --- 3. cache miss: ask ------------------------------------------------
# Three services, because any one of them can be down, rate-limit us, or
# answer with an HTML error page. Short timeouts: this runs on the bar's
# 5s interval, and a hung request would wedge the block.
valid_ip() {
    case "$1" in
        ''|*[!0-9a-fA-F.:]*) return 1 ;;
    esac
    case "$1" in
        *.*|*:*) return 0 ;;
    esac
    return 1
}

fetch() {
    for url in https://ifconfig.me/ip https://icanhazip.com https://api.ipify.org; do
        if command -v curl >/dev/null 2>&1; then
            body=$(curl -fsS --max-time 3 "$url" 2>/dev/null)
        else
            body=$(wget -qO- --timeout=3 --tries=1 "$url" 2>/dev/null)
        fi
        body=$(printf '%s' "$body" | tr -d '[:space:]')
        if valid_ip "$body"; then
            printf '%s\n' "$body"
            return 0
        fi
    done
    return 1
}

if ip=$(fetch); then
    # Write elsewhere and rename, so a reader on the bar's 5s tick never
    # sees a half-written cache.
    tmp="$CACHE.$$"
    printf '%s\n%s\n%s\n' "$now" "$route" "$ip" > "$tmp" 2>/dev/null &&
        mv -f "$tmp" "$CACHE" 2>/dev/null
    rm -f "$tmp" 2>/dev/null
    external "$ip"
fi

# The lookup failed. Show the last known address rather than nothing --
# flagged with a trailing ? so a stale one is never read as current.
[ -n "$cached_ip" ] && external "$cached_ip?"

offline "unknown"
