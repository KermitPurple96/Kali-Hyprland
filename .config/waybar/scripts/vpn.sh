#!/bin/sh
# Egress-IP indicator. Grew out of i3-kitty's /usr/share/i3blocks/vpn_status.sh,
# which only ever answered "is tun0 up?" and printed "Disconnected" otherwise.
#
# It answers one question instead: which address is our traffic leaving with?
#
#   VPN up   -> the tunnel address    (what a host on the VPN sees)
#   no VPN   -> the public address    (what a host on the internet sees)
#   neither  -> offline
#
# So the bar never just says "Disconnected" -- with no VPN it tells you the
# IP you are actually exposing, which is the thing you wanted to know when
# you looked at the field.
#
# Emits waybar JSON: "alt" picks the icon (lock / globe / broken chain) and
# "class" picks the colour. See custom/vpn in ../config, #custom-vpn in
# ../style.css.
#
# The public lookup is a network round trip and this module runs every 5s,
# so the result is cached for $TTL. The cache is keyed on the local routing
# state as well as on time: drop the VPN, or move to another network, and
# the key changes and it refetches at once rather than showing a stale
# address for up to $TTL. A stale-but-known address beats no address, so a
# failed lookup falls back to the last one and says so.

set -u

. "$(dirname "$0")/fields-clipboard.sh"

TTL=300
RUNDIR="${XDG_RUNTIME_DIR:-/tmp}"
# Shared with usr/share/i3blocks/vpn_status.sh on purpose: the answer does
# not depend on which session asked, so whichever bar ran last saves the
# other a lookup.
CACHE="$RUNDIR/egress-ip"

# waybar reads one JSON object per line. Every value below is an IP, an
# interface name or a literal, so none of them need escaping.
emit() {    # emit <state> <text> <tooltip>
    save_field vpn "${2%\?}"
    printf '{"text":"%s","alt":"%s","class":"%s","tooltip":"%s"}\n' "$2" "$1" "$1" "$3"
    exit 0
}

# --- 1. a VPN interface, if there is one -------------------------------
# OpenVPN is tun/tap, WireGuard is wg (and whatever name the consumer
# clients pick for their own wg device), PPTP/L2TP is ppp.
#
# Deliberately NOT "which interface holds the default route": on an HTB or
# OffSec VPN the default route stays on the WAN and only the lab subnet is
# pushed through tun0. The tunnel address is still the one the targets see,
# so it is the one to show.
vpn=$(ip -4 -o addr show up scope global 2>/dev/null | awk '
    $2 ~ /^(tun|tap|wg|ppp|nordlynx|proton|mullvad|tailscale)/ {
        split($4, a, "/"); print $2, a[1]; exit
    }')

if [ -n "$vpn" ]; then
    iface=${vpn%% *}
    addr=${vpn##* }
    emit vpn "$addr" "VPN up on $iface -- traffic to the lab leaves as $addr"
fi

# --- 2. no VPN: the public address of the default route ----------------
route=$(ip route show default 2>/dev/null | head -n 1)
[ -n "$route" ] || emit offline "offline" "No default route -- nothing is leaving this machine"

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

age=$((now - cached_at))
if [ -n "$cached_ip" ] && [ "$cached_key" = "$route" ] && [ "$age" -ge 0 ] && [ "$age" -lt "$TTL" ]; then
    emit external "$cached_ip" "No VPN -- traffic leaves as $cached_ip (checked ${age}s ago)"
fi

# --- 3. cache miss: ask ------------------------------------------------
# Three services, because any one of them can be down, rate-limit us, or
# answer with an HTML error page. Short timeouts: this runs on the bar's
# interval, and a hung request would freeze the module.
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
    # Write somewhere else and rename, so a reader on the bar's 5s tick
    # never sees a half-written cache.
    tmp="$CACHE.$$"
    printf '%s\n%s\n%s\n' "$now" "$route" "$ip" > "$tmp" 2>/dev/null &&
        mv -f "$tmp" "$CACHE" 2>/dev/null
    rm -f "$tmp" 2>/dev/null
    emit external "$ip" "No VPN -- traffic leaves as $ip"
fi

# The lookup failed. If we know the previous answer, show it rather than
# nothing -- flag it as stale so a wrong one is never read as current.
if [ -n "$cached_ip" ]; then
    emit external "$cached_ip?" "No VPN -- lookup failed, last known address was $cached_ip (${age}s ago)"
fi

emit offline "unknown" "No VPN, and the public address could not be resolved -- assume you are going out raw"
