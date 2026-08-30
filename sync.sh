#!/usr/bin/env bash
# Capture the live configuration back into this repo, commit and push.
#
#   ./sync.sh                 capture -> commit -> push
#   ./sync.sh --dry-run       show what would change, touch nothing
#   ./sync.sh --no-push       commit locally, do not push
#   ./sync.sh -m "message"    use your own commit message
#   ./sync.sh --status        just show what differs, then exit
#
# WHY THIS EXISTS
# install.sh deploys repo -> ~/.config. Nothing went the other way, so any
# tweak made directly in ~/.config (a colour, a keybind, a gap) lived only
# on this machine and was one reinstall away from being lost. This closes
# that loop.
#
# It only ever copies the files listed in the manifest below, so nothing
# unrelated in ~/.config can wander into the repo.

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO"

DRY=0; PUSH=1; MSG=""; ONLY_STATUS=0
while [ $# -gt 0 ]; do
    case "$1" in
        --dry-run)  DRY=1 ;;
        --no-push)  PUSH=0 ;;
        --status)   ONLY_STATUS=1; DRY=1 ;;
        -m|--message) shift; MSG="${1:-}" ;;
        -h|--help)  sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "unknown option: $1" >&2; exit 1 ;;
    esac
    shift
done

c_ok=$'\033[32m'; c_warn=$'\033[33m'; c_hdr=$'\033[36m'; c_rst=$'\033[0m'
hdr() { printf '\n%s==> %s%s\n' "$c_hdr" "$*" "$c_rst"; }
ok()  { printf '    %s%s%s\n' "$c_ok" "$*" "$c_rst"; }
inf() { printf '    %s\n' "$*"; }

# --- manifest: repo path == path under $HOME, unless mapped after a colon -
FILES="
.config/hypr/hyprland.lua
.config/kitty/kitty.conf
.config/kitty/color.ini
.config/kitty/diff.conf
.config/waybar/config
.config/waybar/style.css
.config/wofi/config
.config/wofi/style.css
.config/fuzzel/fuzzel.ini
.config/dunst/dunstrc
.config/fish/config.fish
.config/fish/functions/fish_prompt.fish
.config/fish/functions/tmux-help.fish
.config/i3/config
.config/i3/i3blocks.conf
.config/i3/app-icons.json
.config/rofi/config.rasi
.config/compton/compton.conf
.config/nvim/init.lua
.config/nvim/lua/mappings.lua
.fehbg
tmux.conf:.tmux.conf
"
DIRS="
.config/hypr/scripts
.config/waybar/scripts
"

changed=0; changed_list=""

capture() { # capture <repo-path> <home-path>
    local r="$1" h="$HOME/$2"
    [ -e "$h" ] || return 0
    if [ ! -e "$r" ] || ! diff -q "$r" "$h" >/dev/null 2>&1; then
        printf '    %-46s %schanged%s\n' "$r" "$c_warn" "$c_rst"
        changed=1; changed_list="$changed_list $r"
        [ "$DRY" -eq 1 ] || { mkdir -p "$(dirname "$r")"; cp -p "$h" "$r"; }
    fi
}

hdr "Comparing live configuration with the repo"
while read -r entry; do
    [ -n "$entry" ] || continue
    case "$entry" in
        *:*) capture "${entry%%:*}" "${entry##*:}" ;;
        *)   capture "$entry" "$entry" ;;
    esac
done <<< "$FILES"

while read -r d; do
    [ -n "$d" ] || continue
    [ -d "$HOME/$d" ] || continue
    for h in "$HOME/$d"/*; do
        [ -f "$h" ] || continue
        capture "$d/$(basename "$h")" "$d/$(basename "$h")"
    done
done <<< "$DIRS"

# The Firefox override is stored with a literal home path; normalise it so a
# machine-specific path never lands in the repo.
FFO="$HOME/.local/share/applications/firefox-esr.desktop"
if [ -f "$FFO" ]; then
    tmp="$(mktemp)"
    sed "s#$HOME/#/home/kermit/#g" "$FFO" > "$tmp"
    if ! diff -q ".local/share/applications/firefox-esr.desktop" "$tmp" >/dev/null 2>&1; then
        printf '    %-46s %schanged%s\n' ".local/share/applications/firefox-esr.desktop" "$c_warn" "$c_rst"
        changed=1
        [ "$DRY" -eq 1 ] || { mkdir -p .local/share/applications; cp "$tmp" .local/share/applications/firefox-esr.desktop; }
    fi
    rm -f "$tmp"
fi

if [ "$changed" -eq 0 ]; then ok "nothing changed live -- repo already matches"; fi

if [ "$ONLY_STATUS" -eq 1 ]; then
    hdr "Uncommitted in git"; git status --short || true; exit 0
fi

if [ "$DRY" -eq 1 ]; then
    hdr "Dry run -- nothing was copied, committed or pushed"; exit 0
fi

# --- commit ------------------------------------------------------------
if [ -z "$(git status --porcelain)" ]; then
    hdr "Nothing to commit"; ok "working tree clean"
else
    hdr "Committing"
    git add -A
    if [ -z "$MSG" ]; then
        n=$(git diff --cached --name-only | wc -l)
        MSG="Sync live configuration ($n file(s))

Captured from ~/.config by sync.sh:
$(git diff --cached --name-only | sed 's/^/  - /')"
    fi
    git commit -q -m "$MSG"
    ok "$(git log --oneline -1)"
fi

# --- push --------------------------------------------------------------
if [ "$PUSH" -eq 1 ]; then
    hdr "Pushing to origin"
    branch="$(git rev-parse --abbrev-ref HEAD)"
    if git push origin "$branch"; then ok "pushed $branch"
    else echo "    push failed -- is the remote reachable / credentials set?" >&2; exit 1; fi
else
    inf "--no-push: not pushed"
fi

hdr "Done"
git status -sb | head -1
