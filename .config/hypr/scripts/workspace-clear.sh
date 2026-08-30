#!/bin/sh
# i3-kitty:  bindsym $mod+b  -- clear the workspace name, back to its number.
set -eu

id=$(hyprctl activeworkspace -j 2>/dev/null | jq -r '.id // empty')
[ -n "$id" ] || { echo "could not determine the active workspace" >&2; exit 1; }

hyprctl dispatch "hl.dsp.workspace.rename({ workspace = '$id', name = '$id' })" >/dev/null 2>&1 \
    || hyprctl dispatch renameworkspace "$id" "$id" >/dev/null 2>&1
