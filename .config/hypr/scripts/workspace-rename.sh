#!/bin/sh
# i3-kitty:  bindsym $mod+n exec i3-input -F 'rename workspace to "N:%s"'
#
# Same idea for Hyprland. i3-input does not exist here, so the name is
# typed into the same launcher everything else uses, and the workspace
# keeps its number as a prefix ("3:web") so SUPER+3 still means something.
set -eu

# hyprctl's usage is `hyprctl [flags] <command>` -- the -j flag has to
# come BEFORE the command. `hyprctl activeworkspace -j` passes -j to the
# command as an argument instead, so no JSON came back, jq got nothing,
# $id stayed empty and the script exited without renaming anything.
# That is why SUPER+N and SUPER+B appeared to do nothing at all.
id=$(hyprctl -j activeworkspace 2>/dev/null | jq -r '.id // empty')
[ -n "$id" ] || { echo "could not determine the active workspace" >&2; exit 1; }

name=$(printf '' | "$(dirname "$0")/dmenu.sh" "Rename workspace $id to:")
[ -n "$name" ] || exit 0

# 0.56 takes a Lua expression; keep the legacy string form as a fallback.
hyprctl dispatch "hl.dsp.workspace.rename({ workspace = '$id', name = '$id:$name' })" >/dev/null 2>&1 \
    || hyprctl dispatch renameworkspace "$id" "$id:$name" >/dev/null 2>&1
