#!/usr/bin/env bash
# Kali-Hyprland -- the tooling half of the setup.
#
# This is https://github.com/KermitPurple96/i3-kitty/blob/main/config.sh,
# reworked for a Hyprland desktop. install.sh sets up the desktop; this puts
# the tools on. They are separate on purpose: you will re-run this one far
# more often than that one.
#
#   ./tools.sh                 everything below
#   ./tools.sh --apt           distro packages only
#   ./tools.sh --python        pipx / uv tools only
#   ./tools.sh --go            go tools only
#   ./tools.sh --rust          rustup + cargo tools only
#   ./tools.sh --npm           node tools only
#   ./tools.sh --bin           standalone binaries (deb/tar/zip releases)
#   ./tools.sh --git           git clones into ~/dev and /opt
#   ./tools.sh --wordlists     unpack rockyou etc.
#   ./tools.sh --voided        print what was dropped, and why, then exit
#   ./tools.sh --dry-run       print what would happen, change nothing
#
# Safe to re-run: every step checks for what it installs first.
#
#############################################################################
# WHAT WAS DROPPED, AND WHY
#############################################################################
#
# config.sh names 141 apt packages. 38 of them exist only to support an X11
# i3 desktop, and this setup does not have one. They are not installed:
#
#   i3 i3-wm i3blocks i3status  -> Hyprland + waybar
#   compton                     -> Hyprland composites natively
#   rofi dmenu                  -> fuzzel (wofi as fallback)
#   xsel xdotool                -> wl-clipboard, wtype
#   unclutter                   -> cursor:inactive_timeout in hyprland.lua
#   arandr                      -> wdisplays / wlr-randr
#   lxappearance                -> nwg-look
#   flameshot                   -> grim + slurp (scripts/screenshot.sh);
#                                  flameshot's Wayland support goes through
#                                  a portal and does not work on wlroots
#                                  compositors the way it does on X11
#   feh                         -> swaybg (feh cannot paint a Wayland root
#                                  window at all)
#   fonts-font-awesome          -> was only for i3-workspace-names-daemon;
#                                  waybar draws those glyphs from the Nerd
#                                  Font instead
#   snapd                       -> only pulled in for glade; snap on Kali
#                                  brings its own mount/systemd baggage
#
# and the entire i3-gaps build chain, which is the big one:
#
#   meson ninja-build autoconf libxcb-{shape0,keysyms1,util0,icccm4,xkb,
#   cursor,xinerama0,randr0,render-util0,xfixes0,xrm}-dev libxcb-xrm0
#   libxcb1-dev libyajl-dev libev-dev libpango1.0-dev libcairo2-dev
#   libxkbcommon{,-x11}-dev libstartup-notification0-dev libpcre2-dev
#   libxfixes-dev
#
# ~25 -dev packages and a meson/ninja compile, all to build Airblader/i3.
# Gaps have been in upstream i3 since 4.22 and Kali ships 4.25 with
# src/gaps.c compiled in, so that build was already unnecessary on X11 and
# is entirely moot here.
#
# Also dropped: the Alacritty bullseye .deb (i3-kitty uses kitty), and
# clipmenu's git build plus its systemd user service (X11-only; cliphist
# replaces it and install.sh handles that).
#
# EVERY security tool in config.sh is kept. Nothing offensive was cut.
#############################################################################

set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USER_NAME="$(id -un)"
DRY=0
DO_ALL=1
declare -A DO=()

c_reset=$'\033[0m'; c_ok=$'\033[32m'; c_warn=$'\033[33m'
c_err=$'\033[31m'; c_hdr=$'\033[36m'
hdr()  { printf '\n%s==> %s%s\n' "$c_hdr" "$*" "$c_reset"; }
info() { printf '    %s\n' "$*"; }
ok()   { printf '    %s%s%s\n' "$c_ok" "$*" "$c_reset"; }
warn() { printf '    %s!  %s%s\n' "$c_warn" "$*" "$c_reset"; }
die()  { printf '\n%sERROR: %s%s\n' "$c_err" "$*" "$c_reset" >&2; exit 1; }
run()  { if [ "$DRY" -eq 1 ]; then printf '    [dry-run] %s\n' "$*"; else "$@"; fi; }

# Print the dropped-packages block: from its heading down to its closing
# line. Anchored on the text, not on the "####" rules -- the heading is
# immediately followed by one, so a /^####*$/ end-range stops instantly.
print_voided() {
    sed -n '/^# WHAT WAS DROPPED/,/^# EVERY security tool/p' "$0" | sed 's/^# \{0,1\}//'
}

while [ $# -gt 0 ]; do
    case "$1" in
        --apt|--python|--go|--rust|--npm|--bin|--git|--wordlists)
            DO["${1#--}"]=1; DO_ALL=0 ;;
        --dry-run) DRY=1 ;;
        --voided)  print_voided; exit 0 ;;
        -h|--help) sed -n '2,30p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) die "unknown option: $1 (try --help)" ;;
    esac
    shift
done
want() { [ "$DO_ALL" -eq 1 ] || [ "${DO[$1]:-0}" = 1 ]; }

[ "${EUID:-$(id -u)}" -eq 0 ] && die "run as your user, not root; it sudos where needed"
command -v apt >/dev/null 2>&1 || die "expects a Debian/Kali system"

if [ "$DRY" -eq 0 ]; then
    hdr "Checking sudo"; sudo -v || die "sudo required"; ok "ok"
fi

have() { command -v "$1" >/dev/null 2>&1; }

# A package that does not exist on this release must not abort the run.
apt_install() {
    local want=() skip=() p
    for p in "$@"; do
        if apt-cache show "$p" >/dev/null 2>&1; then want+=("$p"); else skip+=("$p"); fi
    done
    for p in "${skip[@]:-}"; do [ -n "$p" ] && warn "not in apt, skipping: $p"; done
    [ ${#want[@]} -eq 0 ] && return 0
    if [ "$DRY" -eq 1 ]; then printf '    [dry-run] apt install %s\n' "${want[*]}"; return 0; fi
    sudo apt install -y "${want[@]}"
}

#############################################################################
if want apt; then
hdr "APT: recon, exploitation, AD, web, misc"
[ "$DRY" -eq 0 ] && sudo apt update

# Everything from config.sh's apt lines that is not desktop-X11 scaffolding.
apt_install \
    nmap netdiscover nbtscan onesixtyone oscanner sslscan sipvicious \
    tnscmd10g whatweb dnsrecon dnsmasq enum4linux smtp-user-enum \
    autorecon ipcalc traceroute hping3 thc-ipv6 ipv6toolkit \
    feroxbuster dirsearch wfuzz exploitdb seclists \
    smbclient smbmap redis-tools snmp snmp-mibs-downloader krb5-user \
    impacket-scripts metasploit-framework powershell-empire starkiller \
    villain powercat certipy-ad bloodyad putty-tools \
    neo4j bloodhound \
    proxychains dnscat2 ncat rlwrap swaks xsltproc httptunnel \
    remmina rdesktop keepass2 ftp scrub steghide ghex hexedit \
    docker.io docker-compose apache2 ntpsec-ntpdate \
    build-essential gcc clang cmake lldb golang-go nodejs npm \
    python3-venv python3-pip pipx python-dev-is-python3 \
    libsasl2-dev libldap2-dev libssl-dev \
    ruby-dev cargo \
    grc lolcat moreutils coreutils cryptsetup ncdu locate \
    ripgrep jq unzip curl wget git gum \
    xclip wl-clipboard \
    unrar strace

# wpscan: the Kali package has been broken for a while; config.sh removes it
# and installs the gem instead.
if have wpscan; then ok "wpscan present"
else
    hdr "wpscan (gem, the apt one is broken)"
    run sudo apt remove -y wpscan
    run sudo gem install wpscan
fi

if have evil-winrm; then ok "evil-winrm present"
else hdr "evil-winrm (gem)"; run sudo gem install evil-winrm; fi
fi

#############################################################################
if want python; then
hdr "Python tooling (pipx + uv)"
have pipx || apt_install pipx
[ "$DRY" -eq 0 ] && pipx ensurepath >/dev/null 2>&1

pipx_install() {
    local name="$1" spec="${2:-$1}"
    if pipx list 2>/dev/null | grep -qi "package $name "; then ok "$name present"; return; fi
    if [ "$DRY" -eq 1 ]; then info "[dry-run] pipx install $spec"; return; fi
    pipx install "$spec" >/dev/null 2>&1 && ok "$name" || warn "pipx failed: $name"
}
pipx_install pywal
pipx_install hyfetch
pipx_install lsassy
pipx_install wappalyzer
pipx_install poetry
pipx_install ntlmrecon
pipx_install donpapi   "git+https://github.com/login-securite/DonPAPI.git"
pipx_install uploadserver

# uv, and the two tools config.sh installs through it
if ! have uv; then
    hdr "uv"
    run sh -c 'curl -LsSf https://astral.sh/uv/install.sh | sh'
fi
if have uv; then
    for t in impacket "git+https://github.com/Pennyw0rth/NetExec"; do
        if [ "$DRY" -eq 1 ]; then info "[dry-run] uv tool install $t"
        else uv tool install "$t" >/dev/null 2>&1 && ok "uv: $t" || warn "uv failed: $t"; fi
    done
fi
fi

#############################################################################
if want go; then
hdr "Go tools"
have go || apt_install golang-go
if have go; then
    for m in \
        github.com/jesseduffield/lazygit@latest \
        github.com/ffuf/ffuf/v2@latest \
        github.com/OJ/gobuster/v3@latest
    do
        bin="${m%@*}"; bin="${bin##*/}"; bin="${bin%%/v[0-9]*}"
        if have "$bin"; then ok "$bin present"; continue; fi
        if [ "$DRY" -eq 1 ]; then info "[dry-run] go install $m"; continue; fi
        go install "$m" >/dev/null 2>&1 && ok "$bin" || warn "go install failed: $m"
    done
    info "go binaries land in ~/go/bin -- make sure that is on PATH"
fi
fi

#############################################################################
if want rust; then
hdr "Rust"
if have cargo; then ok "cargo present"
else run sh -c "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y"; fi
if have cargo && ! have ntlm-info; then
    if [ "$DRY" -eq 1 ]; then info "[dry-run] cargo install ntlm-info"
    else cargo install ntlm-info >/dev/null 2>&1 && ok "ntlm-info" || warn "cargo failed: ntlm-info"; fi
fi
fi

#############################################################################
if want npm; then
hdr "Node tools"
have npm || apt_install npm nodejs
if have npm; then
    for p in js-beautify pyright vscode-langservers-extracted; do
        if [ "$DRY" -eq 1 ]; then info "[dry-run] npm -g install $p"; continue; fi
        sudo npm -g install "$p" >/dev/null 2>&1 && ok "$p" || warn "npm failed: $p"
    done
fi
fi

#############################################################################
if want bin; then
hdr "Standalone release binaries"

# fetch <url> <dest>  -- skip if dest already exists
fetch() {
    [ -e "$2" ] && { ok "$(basename "$2") present"; return 0; }
    if [ "$DRY" -eq 1 ]; then info "[dry-run] download $(basename "$2")"; return 0; fi
    curl -fsSL --retry 3 -o "$2" "$1" || { warn "download failed: $1"; return 1; }
}
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

# lsd
if ! have lsd; then
    fetch https://github.com/lsd-rs/lsd/releases/download/v1.2.0/lsd-musl_1.2.0_amd64.deb "$TMP/lsd.deb" \
        && run sudo dpkg -i "$TMP/lsd.deb"
else ok "lsd present"; fi

# bat
if ! have bat; then
    fetch https://github.com/sharkdp/bat/releases/download/v0.24.0/bat_0.24.0_amd64.deb "$TMP/bat.deb" \
        && run sudo dpkg -i "$TMP/bat.deb"
else ok "bat present"; fi

# rustscan
if ! have rustscan; then
    fetch https://github.com/RustScan/RustScan/releases/download/2.3.0/rustscan-2.3.0-x86_64-linux.zip "$TMP/rs.zip" \
        && run sh -c "unzip -qo '$TMP/rs.zip' -d '$TMP/rs' && sudo install -m755 \$(find '$TMP/rs' -name rustscan -type f | head -1) /usr/local/bin/rustscan"
else ok "rustscan present"; fi

# kerbrute
if ! have kerbrute; then
    fetch https://github.com/ropnop/kerbrute/releases/download/v1.0.3/kerbrute_linux_amd64 "$TMP/kerbrute" \
        && run sudo install -m755 "$TMP/kerbrute" /usr/local/bin/kerbrute
else ok "kerbrute present"; fi

# peco
if ! have peco; then
    fetch https://github.com/peco/peco/releases/download/v0.5.11/peco_linux_amd64.tar.gz "$TMP/peco.tgz" \
        && run sh -c "tar xzf '$TMP/peco.tgz' -C '$TMP' && sudo install -m755 \$(find '$TMP' -name peco -type f | head -1) /usr/local/bin/peco"
else ok "peco present"; fi

# neovim (config.sh pins 0.11.6 as an appimage)
if ! have nvim; then
    fetch https://github.com/neovim/neovim/releases/download/v0.11.6/nvim-linux-x86_64.appimage "$TMP/nvim" \
        && run sudo install -m755 "$TMP/nvim" /usr/local/bin/nvim
else ok "nvim present"; fi

# jump -- config.sh had this commented out, but config.fish uses it:
# `pin`, `unpin` and the `pins` alias all call it, so without it those
# three fail with "command not found".
if ! have jump; then
    fetch https://github.com/gsamokovarov/jump/releases/download/v0.51.0/jump_linux_amd64_binary "$TMP/jump" \
        && run sudo install -m755 "$TMP/jump" /usr/local/bin/jump
else ok "jump present"; fi

# powershell
if ! have pwsh; then
    fetch https://github.com/PowerShell/PowerShell/releases/download/v7.4.3/powershell-lts_7.4.3-1.deb_amd64.deb "$TMP/pwsh.deb" \
        && run sudo dpkg -i "$TMP/pwsh.deb"
else ok "pwsh present"; fi

# red-tldr -> /usr/local/bin/red
if ! have red; then
    fetch https://github.com/Rvn0xsy/red-tldr/releases/download/v0.4.3/red-tldr_0.4.3_linux_amd64.tar.gz "$TMP/red.tgz" \
        && run sh -c "tar xzf '$TMP/red.tgz' -C '$TMP' && sudo install -m755 '$TMP/red-tldr' /usr/local/bin/red"
else ok "red present"; fi

# lua-language-server (nvim LSP)
if [ ! -d /usr/local/lib/lua-language-server ]; then
    fetch https://github.com/LuaLS/lua-language-server/releases/download/3.13.5/lua-language-server-3.13.5-linux-x64.tar.gz "$TMP/lls.tgz" \
        && run sh -c "sudo mkdir -p /usr/local/lib/lua-language-server && sudo tar xzf '$TMP/lls.tgz' -C /usr/local/lib/lua-language-server && sudo ln -sf /usr/local/lib/lua-language-server/bin/lua-language-server /usr/local/bin/lua-language-server"
else ok "lua-language-server present"; fi

# fzf, zoxide, atuin -- their own installers
[ -d "$HOME/.fzf" ] || run sh -c "git clone -q --depth 1 https://github.com/junegunn/fzf.git '$HOME/.fzf' && '$HOME/.fzf/install' --all --no-update-rc"
have zoxide || run sh -c 'curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash'
have atuin  || run sh -c "curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh"

# sliver C2
have sliver-server || run sh -c 'curl -fsSL https://sliver.sh/install | sudo bash'
fi

#############################################################################
if want git; then
hdr "Git checkouts"
clone() {  # clone <url> <dest>
    [ -d "$2/.git" ] && { ok "$(basename "$2") present"; return 0; }
    if [ "$DRY" -eq 1 ]; then info "[dry-run] git clone $1 -> $2"; return 0; fi
    git clone -q --depth 1 "$1" "$2" && ok "$(basename "$2")" || warn "clone failed: $1"
}
mkdir -p "$HOME/dev/python" "$HOME/dev/bash" "$HOME/dev/go" "$HOME/tools" "$HOME/maquinas"

clone https://github.com/KermitPurple96/Shellpy                  "$HOME/dev/python/shellpy"
# NOTE: this one returns 404 anonymously -- it is either private or has
# been renamed. config.sh clones it too, so it has been failing there as
# well, just silently. clone() warns and carries on; if the repo is private
# and your git has credentials, it will work for you.
clone https://github.com/KermitPurple96/OSCP-PythonSupportTools  "$HOME/dev/python/support"
clone https://github.com/metal3d/bashsimplecurses               "$HOME/dev/bash/bashsimplecurses"
clone https://github.com/wirzka/incursore                       "$HOME/dev/incursore"
clone https://github.com/skelsec/minikerberos                   "$HOME/dev/python/minikerberos"
clone https://github.com/Hackndo/pyGPOAbuse                     "$HOME/dev/python/pyGPOAbuse"
clone https://github.com/jimeh/tmux-themepack                   "$HOME/.tmux-themepack"
clone https://github.com/mikesmithgh/kitty-scrollback.nvim      "$HOME/kitty.app/kitty-scrollback.nvim"
[ -d /usr/bin/arsenal ] || run sudo git clone -q https://github.com/Orange-Cyberdefense/arsenal.git /usr/bin/arsenal
[ -d /usr/bin/gtfo ]    || run sudo git clone -q https://github.com/mzfr/gtfo /usr/bin/gtfo
[ -d /usr/share/kerberos_enum_userlists ] || \
    run sudo git clone -q https://github.com/attackdebris/kerberos_enum_userlists /usr/share/kerberos_enum_userlists

# incursore on PATH, as config.sh does
[ -e /usr/local/bin/incursore ] || [ ! -f "$HOME/dev/incursore/incursore.sh" ] || \
    run sudo ln -sf "$HOME/dev/incursore/incursore.sh" /usr/local/bin/incursore

# The single-file scripts config.sh wgets into ~/dev
hdr "Personal scripts -> ~/dev"
get() {  # get <url> <dest>
    [ -e "$2" ] && { ok "$(basename "$2") present"; return 0; }
    if [ "$DRY" -eq 1 ]; then info "[dry-run] fetch $(basename "$2")"; return 0; fi
    curl -fsSL --retry 2 -o "$2" "$1" && chmod +x "$2" && ok "$(basename "$2")" \
        || warn "fetch failed: $(basename "$2")"
}
B=https://raw.githubusercontent.com/KermitPurple96/scripts/main
get "$B/Python/md4.py"                                   "$HOME/dev/python/md4"
get "$B/Python/look.py"                                  "$HOME/dev/python/lookpy"
get "$B/Python/ridbrute"                                 "$HOME/dev/python/ridbrute"
get "$B/Python/hex2sid"                                  "$HOME/dev/python/hex2sid"
get "$B/Python/shellListener.py"                         "$HOME/dev/python/shell"
get "$B/Bash/router"                                     "$HOME/dev/bash/router"
get "$B/Bash/ww"                                         "$HOME/dev/bash/ww"
get "$B/Bash/tcpudpScan.sh"                              "$HOME/dev/bash/tcpudpscan"
get "$B/Bash/tools.sh"                                   "$HOME/tools/tools.sh"
get https://raw.githubusercontent.com/mubix/IOXIDResolver/main/IOXIDResolver.py "$HOME/dev/python/IOXIDResolver"
get https://raw.githubusercontent.com/sse-secure-systems/Active-Directory-Spotlights/master/AD-Trusts/krbTicketView.py "$HOME/dev/python/TicketView"
get https://raw.githubusercontent.com/KermitPurple96/rpcenum/master/rpcenum.sh "$HOME/dev/bash/rpcenum"
get https://raw.githubusercontent.com/KermitPurple96/fastTCPscan/main/fastTCPscan.go "$HOME/dev/go/fastTCPScan.go"

# config.sh built this with `upx brute ...`, which is not a upx invocation
# (the flag is --brute) and upx was never installed -- the build silently
# failed. Just build it.
if have go && [ -f "$HOME/dev/go/fastTCPScan.go" ] && ! have fastTCPScan; then
    if [ "$DRY" -eq 1 ]; then info "[dry-run] go build fastTCPScan"
    else
        ( cd "$HOME/dev/go" && go build -ldflags "-s -w" fastTCPScan.go 2>/dev/null ) \
            && sudo install -m755 "$HOME/dev/go/fastTCPScan" /usr/local/bin/fastTCPScan \
            && ok "fastTCPScan" || warn "fastTCPScan build failed"
    fi
fi

# The state files the waybar pentest blocks read
mkdir -p "$HOME/.config/bin"
for f in target.txt domain.txt ttl.txt target_sys.txt session.txt name.txt; do
    [ -e "$HOME/.config/bin/$f" ] || : > "$HOME/.config/bin/$f"
done
fi

#############################################################################
if want wordlists; then
hdr "Wordlists"
if [ -f /usr/share/wordlists/rockyou.txt.gz ]; then
    run sudo gunzip /usr/share/wordlists/rockyou.txt.gz
    ok "rockyou.txt unpacked"
elif [ -f /usr/share/wordlists/rockyou.txt ]; then ok "rockyou.txt already unpacked"
else warn "rockyou not found (install seclists / wordlists)"; fi
[ "$DRY" -eq 0 ] && have updatedb && run sudo updatedb
fi

#############################################################################
hdr "Done"
cat <<'DONE'

  Notes
  -----
  * go binaries install to ~/go/bin, pipx to ~/.local/bin. Both need to be
    on PATH -- fish config.fish already adds them.
  * BloodHound CE runs from docker rather than being installed:
        mkdir -p ~/dev/bloodhound && cd ~/dev/bloodhound
        curl -L https://ghst.ly/getbhce -o docker-compose.yml
        docker compose up -d
        docker compose logs bloodhound | grep -i password
    then log in at http://127.0.0.1:8080/ui/login as admin.
    config.sh ran `docker-compose up` in the foreground, which blocks the
    rest of the script, so it is left to you deliberately.
  * `chsh -s /usr/bin/fish` is NOT run here -- changing your login shell
    prompts for a password and is not something a tool installer should do
    behind your back. Run it yourself when you want it.
  * config.sh ended with `reboot`. This does not reboot.

  See ./tools.sh --voided for the full list of what was dropped because
  the desktop is Hyprland rather than i3, and why.
DONE
