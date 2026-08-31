#!/usr/bin/env bash
# ╦ ╦╦ ╦╔═╗╦═╗╦  ╔═╗╔╗╔╔╦╗
# ╠═╣╚╦╝╠═╝╠╦╝║  ╠═╣║║║ ║║
# ╩ ╩ ╩ ╩  ╩╚═╩═╝╩ ╩╝╚╝═╩╝
# Kali-Hyprland -- one script that installs the whole desktop.
# Author: KermitPurple96
# Repository: https://github.com/KermitPurple96/Kali-Hyprland
#
# This is the kali-clean setup (https://github.com/KermitPurple96/kali-clean)
# carried over to Wayland: the same palette, the same gaps, the same
# keybindings, plus the three things i3 could never do -- real window
# animations, rounded corners and blur.
#
# USAGE
#   ./install.sh                 interactive, asks what to install
#   ./install.sh --hyprland      Hyprland only,  no questions asked
#   ./install.sh --i3            i3 only,        no questions asked
#   ./install.sh --both          both session types
#   ./install.sh --all           both + Oh My Zsh + the VMware session entries
#
#   --yes / -y     answer yes to every prompt (implied by --all)
#   --no-zsh       never install Oh My Zsh
#   --vmware       also deploy the root-side VMware bits (session launcher
#                  and login entries) by calling vmware/update-system.sh
#   --skip-upgrade skip `apt upgrade` (still does `apt update`)
#   -h / --help    this text
#
# Run it as your normal user. It calls sudo only where it must.

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STAMP="$(date +%Y%m%d_%H%M%S)"

# Nerd Fonts release to pull from. v2.1.0 is what kali-clean pinned and what
# these configs were built against; bump with NERD_VER=v3.4.0 ./install.sh
# if you want the newer glyph set.
NERD_VER="${NERD_VER:-v2.1.0}"

# The wallpaper the config defaults to.
WALLPAPER_NAME="John_Martin_Le_Pandemonium_Louvre.jpg"

# ---------------------------------------------------------------- output ---
c_reset=$'\033[0m'; c_ok=$'\033[32m'; c_warn=$'\033[33m'
c_err=$'\033[31m';  c_hdr=$'\033[36m'; c_dim=$'\033[2m'

hdr()  { printf '\n%s==> %s%s\n' "$c_hdr" "$*" "$c_reset"; }
info() { printf '    %s\n' "$*"; }
ok()   { printf '    %s%s%s\n' "$c_ok" "$*" "$c_reset"; }
warn() { printf '    %s!  %s%s\n' "$c_warn" "$*" "$c_reset"; }
die()  { printf '\n%sERROR: %s%s\n' "$c_err" "$*" "$c_reset" >&2; exit 1; }

# ------------------------------------------------------------------ flags ---
INSTALL_HYPRLAND=""
INSTALL_I3=""
ASSUME_YES=0
WANT_ZSH=""
WANT_VMWARE=0
SKIP_UPGRADE=0

# Print the header comment block (line 2 up to the first non-comment line)
# rather than a hardcoded line range, so editing the header cannot make
# --help start printing code.
usage() {
    awk 'NR>1 { if (/^#/) { sub(/^# ?/, ""); print } else { exit } }' "$0"
    exit 0
}

while [ $# -gt 0 ]; do
    case "$1" in
        --hyprland)     INSTALL_HYPRLAND=true;  INSTALL_I3=${INSTALL_I3:-false} ;;
        --i3)           INSTALL_I3=true;        INSTALL_HYPRLAND=${INSTALL_HYPRLAND:-false} ;;
        --both)         INSTALL_HYPRLAND=true;  INSTALL_I3=true ;;
        --all)          INSTALL_HYPRLAND=true;  INSTALL_I3=true
                        ASSUME_YES=1; WANT_ZSH=true; WANT_VMWARE=1 ;;
        -y|--yes)       ASSUME_YES=1 ;;
        --no-zsh)       WANT_ZSH=false ;;
        --vmware)       WANT_VMWARE=1 ;;
        --skip-upgrade) SKIP_UPGRADE=1 ;;
        -h|--help)      usage ;;
        *)              die "unknown option: $1  (try --help)" ;;
    esac
    shift
done

# -------------------------------------------------------------- pre-flight --
if [ "${EUID:-$(id -u)}" -eq 0 ]; then
    die "Do not run this as root. Run it as your user; it will sudo when needed."
fi

command -v apt >/dev/null 2>&1 || die "this installer expects a Debian/Kali system (no apt found)"

# Ask up front rather than half way through a long install.
if [ -z "$INSTALL_HYPRLAND" ] && [ -z "$INSTALL_I3" ]; then
    echo "╦ ╦╦ ╦╔═╗╦═╗╦  ╔═╗╔╗╔╔╦╗"
    echo "╠═╣╚╦╝╠═╝╠╦╝║  ╠═╣║║║ ║║"
    echo "╩ ╩ ╩ ╩  ╩╚═╩═╝╩ ╩╝╚╝═╩╝"
    echo
    echo "Which setup would you like to install?"
    echo "  1) Hyprland (Wayland)  -- animations, rounded corners, blur"
    echo "  2) i3 (X11)            -- the classic kali-clean setup"
    echo "  3) Both                -- pick either one at the login screen"
    echo
    read -r -p "Enter your choice (1/2/3): " choice
    case "$choice" in
        1) INSTALL_HYPRLAND=true;  INSTALL_I3=false ;;
        2) INSTALL_HYPRLAND=false; INSTALL_I3=true  ;;
        3) INSTALL_HYPRLAND=true;  INSTALL_I3=true  ;;
        *) die "invalid choice: $choice" ;;
    esac
fi
INSTALL_HYPRLAND=${INSTALL_HYPRLAND:-false}
INSTALL_I3=${INSTALL_I3:-false}

# Take the sudo prompt now, so a long unattended run does not stall on it
# twenty minutes in.
hdr "Checking sudo"
sudo -v || die "sudo is required"
ok "ok"

# ----------------------------------------------------------- apt helpers ---
# One bad package name must not abort the whole install. This is exactly how
# the old script died: it asked for "polkit-mate", which does not exist in
# Kali (the package is "mate-polkit"), and `set -e` took the rest with it.
#
# The other way a fresh Kali box dies here: kali-rolling's mirror redirector
# can hand two consecutive requests to mirrors that are out of sync with
# each other, so a package listed by `apt update` 404s on fetch ("Unable to
# fetch some archives, maybe run apt-get update or try with --fix-missing?").
# `set -e` turned that into a dead install needing a full manual re-run --
# sometimes several, one per flaky package. Retry once with a fresh list and
# --fix-missing before actually giving up.
apt_retry() {
    if ! sudo apt "$@"; then
        warn "apt $1 failed (likely a stale/out-of-sync mirror) -- refreshing and retrying with --fix-missing"
        sudo apt update
        sudo apt --fix-missing "$@"
    fi
}

apt_install() {
    local want=() skip=() p
    for p in "$@"; do
        if apt-cache show "$p" >/dev/null 2>&1; then
            want+=("$p")
        else
            skip+=("$p")
        fi
    done
    for p in "${skip[@]:-}"; do
        [ -n "$p" ] && warn "not in apt on this release, skipping: $p"
    done
    if [ ${#want[@]} -gt 0 ]; then
        apt_retry install -y "${want[@]}"
    fi
}

# ---------------------------------------------------------------- system ---
hdr "Updating package lists"
sudo apt update

if [ "$SKIP_UPGRADE" -eq 0 ]; then
    hdr "Upgrading installed packages (--skip-upgrade to skip)"
    apt_retry upgrade -y
else
    info "skipped"
fi

# --------------------------------------------------------- common packages --
# Everything kali-clean installs that is not specific to X11 or to Wayland.
hdr "Installing common tools"
# NOTE what is deliberately NOT here: flameshot, feh, lxappearance and
# unclutter. All four are X11-only and Hyprland replaces every one of them
# (grim+slurp, swaybg, nwg-look, cursor:inactive_timeout), so they moved
# into the i3 branch below. A --hyprland install now pulls no X11 desktop
# tooling it cannot use. See ./tools.sh --voided for the full accounting.
apt_install \
    arc-theme \
    papirus-icon-theme \
    imagemagick \
    python3-pip \
    pipx \
    nemo \
    nemo-fileroller \
    gvfs-backends \
    gvfs-fuse \
    kitty \
    pavucontrol \
    brightnessctl \
    playerctl \
    xdg-desktop-portal-gtk \
    fonts-hack \
    curl \
    wget \
    unzip \
    git \
    zoxide

# ----------------------------------------------------------------- fonts ---
# These configs name three families:
#   Hack Nerd Font        kitty, waybar, wofi, dunst, the Hyprland groupbar
#   RobotoMono Nerd Font  the i3 bar and window titles
#   Iosevka Nerd Font     kali-clean shipped it, kept for parity
#
# NOTE the Debian package `fonts-hack` is NOT the same thing as Hack Nerd
# Font: it has the letterforms but none of the patched glyphs, so every
# icon in the bar renders as a tofu box. The Nerd Font build has to come
# from the nerd-fonts release. The old installer never fetched it at all,
# which is why a fresh box came up with a bar full of empty rectangles.
install_nerd_font() {
    local zip="$1" family="$2" url tmp
    if fc-list 2>/dev/null | grep -qi "$family"; then
        ok "$family already present"
        return 0
    fi
    url="https://github.com/ryanoasis/nerd-fonts/releases/download/$NERD_VER/$zip.zip"
    tmp="$(mktemp -d)"
    info "downloading $zip ($NERD_VER)..."
    if ! curl -fsSL --retry 3 -o "$tmp/$zip.zip" "$url"; then
        warn "could not download $zip from $url -- skipping"
        rm -rf "$tmp"; return 0
    fi
    mkdir -p "$HOME/.local/share/fonts/$zip"
    unzip -qo "$tmp/$zip.zip" -d "$HOME/.local/share/fonts/$zip" \
        -x '*Windows Compatible*' 2>/dev/null || \
        unzip -qo "$tmp/$zip.zip" -d "$HOME/.local/share/fonts/$zip"
    rm -rf "$tmp"
    ok "$family installed"
}

hdr "Installing Nerd Fonts"
mkdir -p "$HOME/.local/share/fonts"
install_nerd_font Hack       "Hack Nerd Font"
install_nerd_font RobotoMono "RobotoMono Nerd Font"
install_nerd_font Iosevka    "Iosevka Nerd Font"
info "refreshing the font cache..."
fc-cache -f >/dev/null
# Say plainly whether the font the configs actually depend on is there.
if fc-list | grep -qi "Hack Nerd Font"; then
    ok "Hack Nerd Font is available -- bar glyphs will render"
else
    warn "Hack Nerd Font is still missing; icons in the bar will show as boxes"
fi

# ---------------------------------------------------------------- Dracula ---
# The GTK theme, its icon set and cursors, plus the desktop settings that
# name them. Delegated to ./theme.sh because vmware/install-vmware.sh is a
# self-contained second installer that needs exactly the same thing -- kept
# inline it would be written twice and drift apart on the first edit that
# touched only one of them.
#
# It needs no root, and papirus-icon-theme (installed above) is the fallback
# its icon set inherits from, so this is the right point to run it.
hdr "Installing the Dracula theme"
if [ -x "$REPO/theme.sh" ]; then
    "$REPO/theme.sh" || warn "theme.sh reported a problem -- the desktop works, it is just unthemed"
else
    warn "theme.sh not found in $REPO -- skipping the theme"
fi

# ------------------------------------------------------------------ pywal ---
# kali-clean ran `pip3 install pywal`. That fails on current Kali: Python is
# marked externally-managed (PEP 668), so pip refuses to write into the
# system site-packages. pipx gives it its own venv and puts `wal` on PATH.
hdr "Installing pywal"
if command -v wal >/dev/null 2>&1; then
    ok "already installed"
elif command -v pipx >/dev/null 2>&1; then
    pipx install pywal >/dev/null 2>&1 && ok "installed via pipx" \
        || warn "pipx could not install pywal -- skipping (it is optional)"
    pipx ensurepath >/dev/null 2>&1 || true
else
    pip3 install --user --break-system-packages pywal >/dev/null 2>&1 \
        && ok "installed via pip --break-system-packages" \
        || warn "could not install pywal -- skipping (it is optional)"
fi

# ------------------------------------------------------- config deployment --
# Back up FIRST, then recreate the directory, then copy in.
#
# The old script did this the other way round: it ran `mkdir -p` on every
# config directory, then moved the non-empty ones aside as a backup, and
# then copied into a path that no longer existed. On a fresh machine the
# directories were empty so nothing was moved and nobody noticed; on a
# re-install it moved the directory away and the copy failed, taking the
# rest of the script with it under `set -e`.
backup_and_make() {
    local d="$HOME/.config/$1"
    if [ -d "$d" ] && [ -n "$(ls -A "$d" 2>/dev/null)" ]; then
        mv "$d" "$d.backup.$STAMP"
        info "backed up ~/.config/$1 -> $1.backup.$STAMP"
    fi
    mkdir -p "$d"
}

# --------------------------------------------------------------- wallpaper --
hdr "Installing wallpapers"
mkdir -p "$HOME/.wallpaper"
cp -n "$REPO"/.wallpaper/* "$HOME/.wallpaper/" 2>/dev/null || true
install -m 755 "$REPO/.fehbg" "$HOME/.fehbg"
if [ -f "$HOME/.wallpaper/$WALLPAPER_NAME" ]; then
    ok "default wallpaper: ~/.wallpaper/$WALLPAPER_NAME"
    info "(John Martin, 'Le Pandemonium', Louvre)"
else
    warn "$WALLPAPER_NAME not found in the repo -- the config falls back to"
    warn "the next image in ~/.wallpaper, or to a flat #1C1D2B background"
fi

# -------------------------------------------------------------- i3blocks ---
# The pentest status blocks. i3blocks resolves a bare block name to
# /usr/share/i3blocks/$BLOCK_NAME, so these have to be there, not in $HOME.
# fish's `iface`/`mip` functions and its VPN/iface startup checks read from
# here too (see .config/fish/config.fish), regardless of which session gets
# installed, so this has to run for a Hyprland-only install as well -- not
# just under --i3. (waybar's own scripts under ~/.config/waybar/scripts
# detect the interface themselves and do not need this file.)
hdr "Installing i3blocks scripts"
info "installing i3blocks scripts -> /usr/share/i3blocks/"
sudo mkdir -p /usr/share/i3blocks
for f in "$REPO"/usr/share/i3blocks/*.sh; do
    sudo install -m 755 "$f" /usr/share/i3blocks/
done
# The interface name the ethernet/gateway blocks read. Default it to
# whatever actually carries the default route rather than a hardcoded
# eth0, which is wrong on most VMs (ens33, enp0s3...).
if [ ! -s /usr/share/i3blocks/iface ]; then
    detected=$(ip route show default 2>/dev/null | awk '/default/{print $5; exit}')
    printf '%s\n' "${detected:-eth0}" | sudo tee /usr/share/i3blocks/iface >/dev/null
    info "i3blocks iface = ${detected:-eth0}"
fi

# ---------------------------------------------------------------- i3 (X11) --
if [ "$INSTALL_I3" = true ]; then
    hdr "Installing i3 (X11)"
    # No i3-gaps source build. Gaps have been part of upstream i3 since
    # 4.22 -- Kali ships 4.25 with src/gaps.c compiled in -- so the whole
    # meson/ninja build kali-clean did, and the ~25 -dev packages it needed,
    # are gone. `gaps inner 2` in the config just works.
    # These four are X11-only and belong to the i3 session alone:
    #   feh          ~/.fehbg wallpaper (cannot paint a Wayland root window)
    #   flameshot    $mod+P screenshot (Hyprland uses grim + slurp)
    #   lxappearance GTK theming        (Hyprland uses nwg-look)
    #   unclutter    hide the pointer   (Hyprland: cursor:inactive_timeout)
    apt_install \
        i3 \
        i3-wm \
        i3status \
        i3blocks \
        rofi \
        arandr \
        compton \
        picom \
        xclip \
        feh \
        flameshot \
        lxappearance \
        unclutter \
        fonts-font-awesome

    hdr "Deploying i3 configuration"
    for d in i3 compton rofi; do backup_and_make "$d"; done
    cp -r "$REPO"/.config/i3/.      "$HOME/.config/i3/"
    cp -r "$REPO"/.config/compton/. "$HOME/.config/compton/"
    cp -r "$REPO"/.config/rofi/.    "$HOME/.config/rofi/"
    chmod +x "$HOME/.config/i3/clipboard_fix.sh" 2>/dev/null || true

    # i3-workspace-names-daemon puts an app glyph next to each workspace
    # number (i3/app-icons.json). pip, because it is not packaged.
    if ! command -v i3-workspace-names-daemon >/dev/null 2>&1; then
        pipx install i3-workspace-names-daemon >/dev/null 2>&1 \
            || pip3 install --user --break-system-packages i3-workspace-names-daemon >/dev/null 2>&1 \
            || warn "could not install i3-workspace-names-daemon (workspace icons will be off)"
    fi
    apt_install fonts-font-awesome
    ok "i3 configured"
fi

# --------------------------------------------------------- Hyprland (Wayland) --
if [ "$INSTALL_HYPRLAND" = true ]; then
    hdr "Installing Hyprland (Wayland)"
    apt_install \
        hyprland \
        xdg-desktop-portal-hyprland \
        xwayland \
        waybar \
        wofi \
        dunst \
        grim \
        slurp \
        wl-clipboard \
        swaybg \
        swaylock \
        swayidle \
        wireplumber \
        network-manager-gnome \
        blueman \
        mate-polkit \
        qt6ct

    # The Wayland-native replacements for the X11 tools kali-clean used.
    # None of these is load-bearing -- the desktop comes up without them --
    # so they go in their own call and a missing one is just a warning.
    hdr "Installing Wayland equivalents of the i3-kitty X11 tools"
    info "fuzzel    -> rofi           (launcher -- the fast one, see below)"
    info "cliphist  -> clipmenu        (clipboard history, SUPER+C)"
    info "nwg-look  -> lxappearance    (GTK theming)"
    info "wdisplays -> arandr          (monitor layout)"
    # fuzzel matters more than the rest: wofi re-matches ~345 desktop
    # entries and repaints its whole layer on every keystroke, which on a
    # software renderer is what makes SUPER+D stutter and drop keys.
    # fuzzel is a native Wayland client with an in-memory index.
    apt_install \
        fuzzel \
        cliphist \
        nwg-look \
        wdisplays \
        wlr-randr \
        wtype \
        hyprpicker

    if command -v fuzzel >/dev/null 2>&1; then
        ok "fuzzel installed -- SUPER+D will use it"
    else
        warn "fuzzel not installed; SUPER+D falls back to wofi, which is slower"
    fi

    # The pentest status-bar blocks read these. i3-kitty created them in
    # config.sh; without them the bar shows "no target"/"no domain", which
    # is correct but the files should exist so you can just echo into them.
    hdr "Creating the ~/.config/bin state files the status bar reads"
    mkdir -p "$HOME/.config/bin"
    for f in target.txt domain.txt ttl.txt target_sys.txt session.txt name.txt; do
        [ -e "$HOME/.config/bin/$f" ] || : > "$HOME/.config/bin/$f"
    done
    ok "~/.config/bin ready (target, domain, ttl, target_sys, session)"
    info "set one with:  echo 10.10.11.5 > ~/.config/bin/target.txt"
    info "start the session clock:  date +%s > ~/.config/bin/session.txt"

    hdr "Deploying Hyprland configuration"
    for d in hypr waybar wofi dunst fuzzel; do backup_and_make "$d"; done
    mkdir -p "$HOME/.config/hypr/scripts" "$HOME/.config/waybar/scripts"
    cp -r "$REPO"/.config/hypr/.   "$HOME/.config/hypr/"
    cp -r "$REPO"/.config/waybar/. "$HOME/.config/waybar/"
    cp -r "$REPO"/.config/wofi/.   "$HOME/.config/wofi/"
    cp -r "$REPO"/.config/dunst/.  "$HOME/.config/dunst/"
    cp -r "$REPO"/.config/fuzzel/. "$HOME/.config/fuzzel/"

    # Only hyprland.lua is deployed. Hyprland 0.51+ reads the Lua config;
    # 0.56 still loads a hyprland.conf but warns that support goes away in
    # 0.57. The .conf build of this same setup lives in legacy/ -- for
    # older Hyprland only, and never both files in ~/.config/hypr at once.
    HYPR_MINOR=$(Hyprland --version 2>/dev/null \
        | grep -oE 'Hyprland [0-9]+\.[0-9]+' | head -1 | cut -d. -f2)
    if [ -n "${HYPR_MINOR:-}" ] && [ "$HYPR_MINOR" -lt 51 ] 2>/dev/null; then
        warn "Hyprland 0.$HYPR_MINOR predates the Lua config -- installing legacy/hyprland.conf"
        rm -f "$HOME/.config/hypr/hyprland.lua"
        cp "$REPO/legacy/hyprland.conf" "$HOME/.config/hypr/hyprland.conf"
    else
        rm -f "$HOME/.config/hypr/hyprland.conf"
    fi

    chmod +x "$HOME"/.config/hypr/scripts/*.sh   2>/dev/null || true
    chmod +x "$HOME"/.config/waybar/scripts/*.sh 2>/dev/null || true

    # Firefox launcher override.
    #
    # Firefox is single-instance per profile and finds the running copy over
    # D-Bus. Kali uses dbus-user-session, which is ONE bus per user rather
    # than per login session, so a Firefox already running on an X11 session
    # is reachable from the Hyprland one -- and launching it here just makes
    # a window appear over there instead. This user-level .desktop shadows
    # the system entry so the launcher goes through scripts/firefox.sh,
    # which detects that case. Remove the file to undo.
    mkdir -p "$HOME/.local/share/applications"
    if [ -f "$REPO/.local/share/applications/firefox-esr.desktop" ]; then
        sed "s#/home/kermit/#$HOME/#g" \
            "$REPO/.local/share/applications/firefox-esr.desktop" \
            > "$HOME/.local/share/applications/firefox-esr.desktop"
        update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
        ok "Firefox launcher override installed"
    fi

    # The Hyprland config reuses kali-clean's VM clipboard fix.
    mkdir -p "$HOME/.config/i3"
    cp -n "$REPO/.config/i3/clipboard_fix.sh" "$HOME/.config/i3/" 2>/dev/null || true
    chmod +x "$HOME/.config/i3/clipboard_fix.sh" 2>/dev/null || true
    ok "Hyprland configured"
fi

# ------------------------------------------------------------------ kitty ---
hdr "Deploying Kitty configuration"
mkdir -p "$HOME/.config/kitty"
if [ -f "$HOME/.config/kitty/kitty.conf" ]; then
    cp "$HOME/.config/kitty/kitty.conf" "$HOME/.config/kitty/kitty.conf.backup.$STAMP"
    info "backed up kitty.conf -> kitty.conf.backup.$STAMP"
fi
cp -r "$REPO"/.config/kitty/. "$HOME/.config/kitty/"
# kitty.conf ends with `shell fish`. If fish is not installed, kitty opens a
# window that dies instantly -- and on this setup kitty is the rescue
# terminal, so that failure is worth catching here rather than at 3am.
if grep -qE '^\s*shell\s+fish' "$HOME/.config/kitty/kitty.conf" 2>/dev/null \
   && ! command -v fish >/dev/null 2>&1; then
    warn "kitty.conf sets 'shell fish' but fish is not installed."
    warn "Either: sudo apt install fish     -- or edit ~/.config/kitty/kitty.conf"
fi
ok "kitty configured"

# -------------------------------------------------------------- VMware bits --
if [ "$WANT_VMWARE" -eq 1 ]; then
    hdr "Deploying the VMware session launcher and login entries"
    if [ -x "$REPO/vmware/update-system.sh" ]; then
        "$REPO/vmware/update-system.sh"
    else
        warn "vmware/update-system.sh not found or not executable -- skipping"
    fi
fi

# --------------------------------------------- shell / editor / tmux ---
# These are window-manager agnostic, so they go on for both sessions.
hdr "Deploying fish, neovim and tmux configuration"
apt_install fish tmux neovim fzf ripgrep bat jq

mkdir -p "$HOME/.config/fish/functions" "$HOME/.config/nvim/lua"
for f in config.fish fish_variables; do
    [ -f "$HOME/.config/fish/$f" ] && cp "$HOME/.config/fish/$f" "$HOME/.config/fish/$f.bak.$STAMP"
    cp "$REPO/.config/fish/$f" "$HOME/.config/fish/$f"
done
cp "$REPO"/.config/fish/functions/*.fish "$HOME/.config/fish/functions/"
cp "$REPO/.config/nvim/init.lua"         "$HOME/.config/nvim/init.lua"
cp "$REPO/.config/nvim/lua/mappings.lua" "$HOME/.config/nvim/lua/mappings.lua"
[ -f "$HOME/.tmux.conf" ] && cp "$HOME/.tmux.conf" "$HOME/.tmux.conf.bak.$STAMP"
cp "$REPO/tmux.conf" "$HOME/.tmux.conf"
if [ ! -d "$HOME/.tmux-themepack" ]; then
    git clone -q --depth 1 https://github.com/jimeh/tmux-themepack.git "$HOME/.tmux-themepack" \
        || warn "could not clone tmux-themepack"
fi
cp "$REPO/basic.tmuxtheme" "$HOME/.tmux-themepack/basic.tmuxtheme" 2>/dev/null || true
ok "fish / neovim / tmux configured"

# kitty.conf ends with `shell fish`, so fish has to exist or kitty opens a
# window that dies immediately -- and kitty is the rescue terminal here.
if command -v fish >/dev/null 2>&1; then
    ok "fish present (kitty.conf sets 'shell fish')"
else
    warn "fish is NOT installed but kitty.conf sets 'shell fish' -- fix one or the other"
fi

# ------------------------------------------------------------- Oh My Zsh ---
if [ -z "$WANT_ZSH" ]; then
    if [ "$ASSUME_YES" -eq 1 ]; then
        WANT_ZSH=false
    else
        read -r -p "Would you like to install Oh My Zsh? (y/N): " a
        case "$a" in [yY]*) WANT_ZSH=true ;; *) WANT_ZSH=false ;; esac
    fi
fi
if [ "$WANT_ZSH" = true ]; then
    hdr "Installing Oh My Zsh"
    if [ -d "$HOME/.oh-my-zsh" ]; then
        ok "already installed"
    else
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended \
            || warn "Oh My Zsh install failed -- carrying on"
    fi
fi

# ------------------------------------------------------------------- done ---
hdr "Installation complete"

if [ "$INSTALL_HYPRLAND" = true ]; then
cat <<'HYPR'

  Hyprland
  --------
  Log out and pick "Hyprland" at the login screen.

  In a VMware guest, run the root-side deploy too (or pass --vmware):

      cd vmware && ./update-system.sh

  and the FIRST time pick "Hyprland (safe test)". It arms a 120-second
  dead-man's switch: press CTRL+ALT+O to keep the session, and if you
  cannot -- black screen, dead keyboard, anything -- it ends itself and
  returns you to the greeter. No power cycle.

  CTRL+ALT+F3 always gives you a text console; Hyprland handles that one
  internally through logind, so it works even if every keybind is broken.

  Keybindings (Super = Windows key) -- the same as kali-clean's i3:
    Super + Enter          terminal (kitty)
    Super + D              app launcher (wofi)
    Super + Shift + Q      close window
    Super + J/K/L/;        focus left/down/up/right
    Super + Shift + same   move window
    Super + H / V          split horizontal / vertical
    Super + S / W          group (i3's stacking / tabbed)
    Super + F              fullscreen
    Super + R              resize mode (Escape to leave)
    Super + Shift + P      screenshot (grim + slurp)
    Super + Shift + E      exit
    Ctrl + Alt + T         rescue terminal (works without Super)

  Looks: 3px borders, 10px rounded corners, blur behind kitty, waybar,
  wofi and dunst, and animated window open/close/move.

  Effects profiles, set on the session entry or the command line:
    HYPR_EFFECTS=soft   default -- tuned for software rendering
    HYPR_EFFECTS=full   everything, for a machine with a real GPU
    HYPR_EFFECTS=lite   rounding only, the panic button
HYPR
fi

if [ "$INSTALL_I3" = true ]; then
cat <<'I3'

  i3
  --
  Log out and pick "i3" at the login screen, then:
    lxappearance          and choose arc-dark
    wal -i ~/.wallpaper/John_Martin_Le_Pandemonium_Louvre.jpg   (optional colours)
I3
fi

echo
echo "  Wallpaper: ~/.wallpaper/$WALLPAPER_NAME"
echo "  Change it by editing ~/.fehbg (i3) or setting WALLPAPER=/path/to.jpg"
echo "  before the session starts (Hyprland)."
echo
echo "  See README.md for the full keymap and VMWARE-NOTES.md for the"
echo "  VMware-specific details."
echo
