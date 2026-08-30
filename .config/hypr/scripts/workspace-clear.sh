#!/bin/sh
# i3-kitty:  bindsym $mod+b  -- clear the workspace name, back to its number.
set -eu

# hyprctl's usage is `hyprctl [flags] <command>` -- the -j flag has to
# come BEFORE the command. `hyprctl activeworkspace -j` passes -j to the
# command as an argument instead, so no JSON came back, jq got nothing,
# $id stayed empty and the script exited without renaming anything.
# That is why SUPER+N and SUPER+B appeared to do nothing at all.
id=$(hyprctl -j activeworkspace 2>/dev/null | jq -r '.id // empty')
[ -n "$id" ] || { echo "could not determine the active workspace" >&2; exit 1; }

hyprctl dispatch "hl.dsp.workspace.rename({ workspace = '$id', name = '$id' })" >/dev/null 2>&1 \
    || hyprctl dispatch renameworkspace "$id" "$id" >/dev/null 2>&1
