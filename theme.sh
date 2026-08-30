#!/usr/bin/env bash
# Kali-Hyprland -- the Dracula desktop theme, and the settings that make the
# desktop applications agree with it.
#
#   ./theme.sh              install and apply everything below
#   ./theme.sh --no-apply   fetch the theme files, change no settings
#   ./theme.sh --status     report what is present and what is set, then exit
#
# WHY THIS IS ITS OWN SCRIPT
# There are two independent installers -- ./install.sh for a bare-metal box
# and vmware/install-vmware.sh for a VMware guest -- and both need this. Kept
# inline it would have to be written twice and would drift apart on the first
# edit that touched only one of them. Both call this instead.
#
# NOTHING HERE NEEDS ROOT. The theme goes to ~/.themes and ~/.icons, and the
# settings are per-user. That is the reason it can be re-run at any time,
# including from inside a live session, without sudo.

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

APPLY=1; ONLY_STATUS=0
while [ $# -gt 0 ]; do
    case "$1" in
        --no-apply) APPLY=0 ;;
        --status)   ONLY_STATUS=1 ;;
        -h|--help)  sed -n '2,8p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "unknown option: $1" >&2; exit 1 ;;
    esac
    shift
done

c_ok=$'\033[32m'; c_warn=$'\033[33m'; c_hdr=$'\033[36m'; c_rst=$'\033[0m'
hdr()  { printf '\n%s==> %s%s\n' "$c_hdr" "$*" "$c_rst"; }
ok()   { printf '    %s%s%s\n' "$c_ok" "$*" "$c_rst"; }
warn() { printf '    %s%s%s\n' "$c_warn" "$*" "$c_rst"; }
inf()  { printf '    %s\n' "$*"; }

DRACULA_GTK_VER="v4.0.0"
GTK_URL="https://github.com/dracula/gtk/releases/download/$DRACULA_GTK_VER"
ICONS_URL="https://github.com/m4thewz/dracula-icons/archive/refs/heads/main.tar.gz"

# ------------------------------------------------------------------ status --
if [ "$ONLY_STATUS" -eq 1 ]; then
    hdr "Theme files"
    for d in "$HOME/.themes/Dracula" "$HOME/.icons/Dracula" "$HOME/.icons/Dracula-cursors"; do
        [ -d "$d" ] && ok "present  ${d/#$HOME/\~}" || warn "MISSING  ${d/#$HOME/\~}"
    done
    hdr "GTK"
    for f in "$HOME/.config/gtk-3.0/settings.ini" "$HOME/.config/gtk-4.0/gtk.css"; do
        [ -e "$f" ] && ok "present  ${f/#$HOME/\~}" || warn "MISSING  ${f/#$HOME/\~}"
    done
    hdr "Settings"
    for pair in \
        "org.gnome.desktop.interface gtk-theme" \
        "org.gnome.desktop.interface icon-theme" \
        "org.gnome.desktop.interface cursor-theme" \
        "org.gnome.desktop.interface color-scheme" \
        "org.nemo.desktop show-desktop-icons" \
        "org.cinnamon.desktop.default-applications.terminal exec"
    do
        set -- $pair
        if gsettings list-schemas 2>/dev/null | grep -qx "$1"; then
            printf '    %-56s %s\n' "$1 $2" "$(gsettings get "$1" "$2" 2>/dev/null)"
        else
            warn "$1 -- schema not installed"
        fi
    done
    exit 0
fi

# ------------------------------------------------------------- theme files --
# Neither the theme nor the icon set is packaged for Debian or Kali --
# `apt-cache search dracula` returns nothing related -- so both come from
# upstream. Every step is skipped when its target already exists, and a
# download failure warns instead of aborting: a themeless desktop is a
# cosmetic problem, and it must not take the rest of an install with it.
hdr "Installing the Dracula theme"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

if [ -d "$HOME/.themes/Dracula" ]; then
    ok "GTK theme already present"
elif curl -fsSL --retry 3 -o "$tmp/gtk.tar.xz" "$GTK_URL/Dracula.tar.xz"; then
    mkdir -p "$HOME/.themes"
    tar xf "$tmp/gtk.tar.xz" -C "$HOME/.themes"
    ok "GTK theme installed ($DRACULA_GTK_VER)"
else
    warn "could not download the GTK theme -- skipping"
fi

if [ -d "$HOME/.icons/Dracula-cursors" ]; then
    ok "cursors already present"
elif curl -fsSL --retry 3 -o "$tmp/cursors.tar.xz" "$GTK_URL/Dracula-cursors.tar.xz"; then
    mkdir -p "$HOME/.icons"
    tar xf "$tmp/cursors.tar.xz" -C "$HOME/.icons"
    ok "cursors installed"
else
    warn "could not download the cursors -- skipping"
fi

if [ -d "$HOME/.icons/Dracula" ]; then
    ok "icon theme already present"
elif curl -fsSL --retry 3 -o "$tmp/icons.tar.gz" "$ICONS_URL"; then
    tar xzf "$tmp/icons.tar.gz" -C "$tmp"
    mkdir -p "$HOME/.icons"
    rm -rf "$HOME/.icons/Dracula"
    mv "$tmp/dracula-icons-main" "$HOME/.icons/Dracula"

    # Upstream inherits from breeze-dark, Zafiro, Mint-X and elementary, and
    # Kali installs none of them. Anything the set is missing would fall all
    # the way through to hicolor and render as a blank sheet of paper.
    # Papirus-Dark is installed by install.sh and covers the gaps, so it goes
    # at the front of the chain.
    sed -i 's/^Inherits=.*/Inherits=Papirus-Dark,ubuntu-mono-dark,gnome,hicolor/' \
        "$HOME/.icons/Dracula/index.theme"
    gtk-update-icon-cache -f -t "$HOME/.icons/Dracula" >/dev/null 2>&1 || true
    ok "icon theme installed, inheriting from Papirus-Dark"
else
    warn "could not download the icon theme -- skipping"
fi

if [ "$APPLY" -eq 0 ]; then
    hdr "--no-apply: theme files only, no settings changed"
    exit 0
fi

# --------------------------------------------------------------------- GTK --
hdr "Wiring GTK"

# GTK3 reads the theme name out of this file; it is version-controlled, so
# copy it rather than editing in place.
mkdir -p "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0"
if [ -f "$REPO/.config/gtk-3.0/settings.ini" ]; then
    install -m 644 "$REPO/.config/gtk-3.0/settings.ini" "$HOME/.config/gtk-3.0/settings.ini"
    ok "~/.config/gtk-3.0/settings.ini"
fi
if [ -f "$REPO/.config/gtk-4.0/settings.ini" ]; then
    install -m 644 "$REPO/.config/gtk-4.0/settings.ini" "$HOME/.config/gtk-4.0/settings.ini"
    ok "~/.config/gtk-4.0/settings.ini"
fi

# GTK4 does not look in ~/.themes at all, so naming the theme is not enough:
# its CSS has to be handed over directly.
if [ -d "$HOME/.themes/Dracula/gtk-4.0" ]; then
    ln -sfn "$HOME/.themes/Dracula/gtk-4.0/gtk.css"      "$HOME/.config/gtk-4.0/gtk.css"
    ln -sfn "$HOME/.themes/Dracula/gtk-4.0/gtk-dark.css" "$HOME/.config/gtk-4.0/gtk-dark.css"
    ln -sfn "$HOME/.themes/Dracula/gtk-4.0/assets"       "$HOME/.config/gtk-4.0/assets"
    ok "GTK4 CSS symlinked (GTK4 ignores ~/.themes)"
fi

# ---------------------------------------------------------------- settings --
# gsettings writes through dconf, which needs a session bus. Running the
# installer from a plain TTY there is none, so borrow a throwaway one --
# dconf still writes to the same ~/.config/dconf/user either way.
hdr "Applying desktop settings"

if [ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ]; then
    RUN=()
elif command -v dbus-run-session >/dev/null 2>&1; then
    RUN=(dbus-run-session --)
    inf "no session bus -- using dbus-run-session"
else
    warn "no session bus and no dbus-run-session; settings cannot be written"
    exit 0
fi

# Skip silently when the schema is not installed. org.nemo and
# org.cinnamon.* arrive with nemo, and this script has to stay runnable on a
# box where the file manager was never installed.
have_schema() { "${RUN[@]}" gsettings list-schemas 2>/dev/null | grep -qx "$1"; }

setting() { # setting <schema> <key> <value>
    if ! have_schema "$1"; then
        warn "skipped $1 $2 -- schema not installed"
        return 0
    fi
    "${RUN[@]}" gsettings set "$1" "$2" "$3" 2>/dev/null \
        && printf '    %-52s %s\n' "$1 $2" "$3" \
        || warn "could not set $1 $2"
}

setting org.gnome.desktop.interface gtk-theme     'Dracula'
setting org.gnome.desktop.interface icon-theme    'Dracula'
setting org.gnome.desktop.interface cursor-theme  'Dracula-cursors'
setting org.gnome.desktop.interface cursor-size   '24'
setting org.gnome.desktop.interface color-scheme  'prefer-dark'

# Nemo would otherwise try to draw the desktop, which under a Wayland
# compositor is not its job.
setting org.nemo.desktop show-desktop-icons 'false'

# Nemo ships pointing "Open in Terminal" at gnome-terminal, which this setup
# does not install, so the menu entry silently did nothing.
setting org.cinnamon.desktop.default-applications.terminal exec     'kitty'
setting org.cinnamon.desktop.default-applications.terminal exec-arg '-e'

setting org.nemo.preferences show-full-path-titles       'true'
setting org.nemo.preferences show-open-in-terminal-toolbar 'true'
# Thumbnailing is pure CPU work, and this desktop is usually a VM with no 3D
# acceleration where the compositor is already software-rendering.
setting org.nemo.preferences thumbnail-threads '2'

# Apply the cursor to a running session too, so a re-run takes effect without
# a logout. Harmless when Hyprland is not running.
if command -v hyprctl >/dev/null 2>&1 && [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
    hyprctl setcursor Dracula-cursors 24 >/dev/null 2>&1 && ok "cursor applied to the live session"
fi

hdr "Done"
inf "run ./theme.sh --status to see what is set"
