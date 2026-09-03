#!/bin/sh
# Shared by every custom/* waybar script: each one calls save_field on its
# own interval (5-10s), which does two things with the value:
#
#   - writes it to disk, so a module's on-click handler (copy-field.sh) can
#     hand back exactly what it is showing right now, without recomputing;
#   - if it actually changed and is not a placeholder, pushes it into
#     cliphist directly (bypassing the live clipboard, so it never steals
#     whatever you last copied elsewhere) -- so by the time you press
#     SUPER+C, the IP/gateway/domain/target are already sitting in the
#     history to pick, with nothing to click first.
#
#   . "$(dirname "$0")/fields-clipboard.sh"
#   save_field vpn "$ip"

FIELD_DIR="${XDG_RUNTIME_DIR:-/tmp}/waybar-fields"
mkdir -p "$FIELD_DIR" 2>/dev/null

# is_placeholder <value> -- true for a module's "nothing to show" state.
# Shared so a placeholder never lands in the clipboard OR in cliphist.
is_placeholder() {
    case "$1" in
        ''|'no domain'|'no target'|'no system'|Disconnected|'No gateway'|offline|unknown)
            return 0 ;;
        *) return 1 ;;
    esac
}

save_field() {  # save_field <name> <value>
    old=$(cat "$FIELD_DIR/$1" 2>/dev/null)
    printf '%s' "$2" > "$FIELD_DIR/$1" 2>/dev/null

    [ "$2" = "$old" ] && return 0
    is_placeholder "$2" && return 0
    command -v cliphist >/dev/null 2>&1 || return 0
    # Bare value, no "Label: " prefix -- it goes straight into cliphist so
    # pasting it works without editing it back down first.
    printf '%s' "$2" | cliphist store >/dev/null 2>&1
}

# field_value <name> -- prints the field's value and returns 0, or returns 1
# with nothing printed if it is unset or a placeholder.
field_value() {
    val=$(cat "$FIELD_DIR/$1" 2>/dev/null)
    is_placeholder "$val" && return 1
    printf '%s' "$val"
}
