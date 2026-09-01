# Hyprland on Kali inside VMware — what had to change, and why

Everything here is what it took to get Hyprland 0.56.2 usable in a VMware guest
on Kali (kernel 7.1.5, LightDM, no host 3D acceleration). Reproduce a fresh box
with:

```bash
git clone https://github.com/KermitPurple96/Kali-Hyprland
cd Kali-Hyprland/vmware
./install-vmware.sh
```

Verified working 2026-08-30.

---

## The bug that actually mattered: dead keyboard, live mouse

**Symptom.** Hyprland starts, you see the desktop, the cursor moves — and not a
single keystroke ever arrives. No way to open a terminal, no way to exit; the
only way out is powering off the VM. Intermittent: same config, same machine,
sometimes fine.

**Root cause.** A startup race between LightDM's VT switch and Hyprland's input
enumeration. From the failing session's log:

```
[libinput] event0  - not using input device '/dev/input/event0'   <- AT Translated Set 2 keyboard
[libinput] event1  - not using input device '/dev/input/event1'
[libinput] event4  - not using input device '/dev/input/event4'
[libinput] event3  - VirtualPS/2 VMware VMMouse: device is a pointer
[libinput] event2  - VirtualPS/2 VMware VMMouse: device is a pointer
Session is not active, waiting for 5s
...
ERR ]: BUG THIS: setKeyboardFocus without a valid keyboard set
```

The chain:

1. libinput enumerates `/dev/input` **exactly once**, at compositor startup.
2. logind refuses to hand device fds to a session that is not yet `Active` on
   the seat.
3. LightDM switches the VT **asynchronously**, so Hyprland can start before the
   session goes Active.
4. Any device libinput could not open at that instant is dropped **and never
   retried** — no udev `add` event ever arrives for a node that already existed.

The two PS/2 mice happened to win the race, so the pointer worked and the
session looked alive while no key could ever land. That is the whole illusion.

**Fix.** Block until logind reports `Active=yes` before launching Hyprland,
capped at 15s. In `vmware/start-hyprland-vmware`:

```bash
SESSION="${XDG_SESSION_ID:-auto}"
for _ in $(seq 1 150); do
    ACTIVE=$(loginctl show-session "$SESSION" -p Active --value 2>/dev/null)
    [ "$ACTIVE" = "yes" ] && break
    sleep 0.1
done
```

**Dead end, recorded so it isn't chased again.** The failure was first blamed on
`follow_mouse` / focus config, because the "Hyprland (diagnostic)" session
appeared to work while the plain one did not. Both entries run the *same*
launcher and differ only by `HYPR_DIAG_EXIT=45` — the diagnostic runs simply won
the coin flip. `follow_mouse` was never involved.

---

## Config format: Hyprland 0.56 wants Lua

Kali's `hyprland 0.56.2+ds-1` autogenerates and loads
**`~/.config/hypr/hyprland.lua`**. It will still read a `hyprland.conf`, but
the binary carries this string and prints it when it does:

```
You are using the .conf config format, support for which will be removed in
Hyprland 0.57.
```

So the maintained config in this repo is `.config/hypr/hyprland.lua`. The
`.conf` build of the same setup is parked in `legacy/` for anyone on a
Hyprland older than 0.51, which is where Lua arrived. **Never keep both files
in `~/.config/hypr`.**

Things worth knowing about the Lua config, all of them things that cost time:

- **`vfr` lives under `debug`, not `misc`.** Wrong section = silently ignored.
- **Two config keys that existed in the `.conf` era are gone in 0.56** and are
  rejected outright: `dwindle:pseudotile` (now only the dispatcher and the
  `pseudo` window rule) and `gestures:workspace_swipe` (gestures are declared
  with `hl.gesture()` now). Check any key against
  `strings /usr/bin/Hyprland | grep '^section:'` before trusting it.
- **Effects are tuned for llvmpipe, not switched off.** `HYPR_EFFECTS`
  selects one of three profiles; `soft` is the default and the one that
  matters here:

  | | `soft` (default) | `full` | `lite` |
  |---|---|---|---|
  | blur | 1 pass, size 4, xray | 2 passes, size 6 | off |
  | shadows | off | on | off |
  | window animations | 300ms | 500ms | off |
  | workspace animations | **off** | slidevert | off |
  | rounding | 10px | 10px | 10px |

  The reasoning, which is the part worth keeping: software rendering cost is
  *damaged pixels × passes over them*. `new_optimizations` (on everywhere)
  caches blur for surfaces that have not changed, so a still terminal is free
  after the frame that drew it. Blur passes are a straight multiplier. Noise
  and vibrancy are extra per-pixel maths on top. And workspace animations
  redraw **every pixel on screen** for their whole duration — the single most
  expensive thing in the config, attached to the action you take most often,
  which is why `soft` drops that one and keeps the ones bounded to a window.

  `HYPR_OVERLAY=1` turns on Hyprland's frame-timing overlay, so this can be
  measured rather than argued about.

- **Do not "fix" performance by enabling 3D acceleration in VMware.** On many
  hosts the guest then refuses to boot at all. This config assumes it stays
  off and is built accordingly; the launcher already detects `Available
  shader model: Legacy` and forces llvmpipe.
- `enable_stdout_logs = true` + `disable_logs = false` are what make the session
  log survive; see "Evidence" below.
- Autostart opens a **kitty terminal at login**, unconditionally. If keybinds
  ever break again you get a usable window instead of a blank screen.
- **Rescue binds deliberately avoid SUPER**, since the VMware host can grab it:
  - `CTRL+ALT+T` — terminal
  - `ALT+Return` — terminal
  - `CTRL+ALT+BackSpace` — clean exit
  They carry `submap_universal = true`, so they still work from inside the
  `SUPER+R` resize mode.
- `kb_layout = "es"`. Change this if you deploy elsewhere.

---

## Renderer: llvmpipe only when the host really has no 3D

vmwgfx reports `Available shader model: Legacy` when host 3D acceleration is
off. There is no GLES 3.x in that state and Hyprland exits immediately. The
launcher reads that from the kernel log and forces software rendering **only**
in that case, so a properly accelerated host still gets hardware:

```bash
SHADER=$(journalctl -k -b | grep -o 'shader model: [A-Za-z0-9._]*' | tail -1)
case "$SHADER" in
    *[Ll]egacy*|"") export LIBGL_ALWAYS_SOFTWARE=1 GALLIUM_DRIVER=llvmpipe ;;
esac
```

Also set, for Aquamarine — 0.56 is **not** wlroots, so the old `WLR_*` variables
from the previous `fix-hyprland-vmware.sh` do nothing:

```bash
[ -e /dev/dri/card0 ] && export AQ_DRM_DEVICES=/dev/dri/card0
export AQ_NO_MODIFIERS=1
export AQ_NO_ATOMIC=1
```

In principle, turning host 3D acceleration **on** in the VM's VMware settings
removes the llvmpipe fallback and the `drm: Failed to update renderer state`
log spam. **In practice it is not available here** — on this host the guest
stops booting entirely with it enabled — so llvmpipe is the permanent, normal
state and the desktop config is tuned for it rather than treating it as a
degraded mode.

That `drm:` spam is cosmetic either way. It was never the input fault.

---

## The guest never resized to the VMware window

**Symptom.** The desktop renders at 1280x800 and stays there no matter how the
VMware window is resized — a fixed rectangle with dead space around it. Nothing
in the logs complains.

**Root cause.** open-vm-tools does only the first half of a guest resize. The
host pushes the new window size down through vmwgfx, which publishes it as the
preferred — first — mode on the virtual connector, and that part works:

```
$ head -1 /sys/class/drm/card0-Virtual-1/modes
1716x1271                      <- the live VMware window, tracked correctly
$ hyprctl monitors | sed -n 2p
1280x800@60.00000 at 0x0       <- what Hyprland is actually driving
```

The second half is missing. `vmware-user` applies that mode with **xrandr**, an
X11 call with no Wayland equivalent, so under Hyprland nothing ever consumes
the new preferred mode. Note the two lists disagree: `hyprctl monitors`
reports `availableModes` without `1716x1271` at all, because Hyprland
enumerated the connector once at startup and the dynamic mode appeared after.

**Fix.** `scripts/vmware-autofit.sh`, autostarted from `hyprland.lua`: poll the
connector's preferred mode and apply it whenever Hyprland's differs.

Two things it has to get right, both found the hard way:

- **`hyprctl keyword` does not work on a Lua config.** It fails with
  `keyword can't work with non-legacy parsers. Use eval.` The way in is
  `hyprctl eval` calling `hl.monitor()`:

  ```bash
  hyprctl eval 'hl.monitor({output="Virtual-1", mode="1716x1271@60", position="0x0", scale=1})'
  ```

  A mode absent from `availableModes` is still accepted, which is the whole
  reason this works.

- **Compare against Hyprland's live mode, not against the last mode applied.**
  Hyprland re-runs the `mode = "preferred"` monitor rule on config reload
  (`SUPER+SHIFT+R`) and on output hotplug, snapping straight back to 1280x800
  while the connector's preferred mode never changed. A watcher that cached
  what it last set would see "nothing to do" and make that revert permanent.
  Reading the live value each tick re-fixes it on the next second.

The script holds a `flock` on `$XDG_RUNTIME_DIR/vmware-autofit.lock`, so a
second copy exits silently rather than fighting the first over the output.

---

## Host<->guest copy/paste silently did nothing

**Symptom.** `clipboard_fix.sh` runs, `vmtoolsd -n vmusr` is alive and well —
and copying text in a guest window never shows up on the host, nor the other
way around. No error anywhere; it just does nothing.

**Root cause.** `vmtoolsd` only ever speaks X11: it watches the `CLIPBOARD`
selection on XWayland's `:0`. That is the whole story in an i3 (pure X11)
session, but every client in a Hyprland session is Wayland-native by
default — `hyprctl clients` reports `xwayland: 0` for kitty, Firefox,
everything — and Hyprland does not bridge the native Wayland clipboard to
XWayland's on its own. Confirmed by hand:

```
$ echo -n test | wl-copy && DISPLAY=:0 xclip -selection clipboard -o
Error: target STRING not available     <- Wayland write, invisible to X11

$ echo -n test | DISPLAY=:0 xclip -selection clipboard && wl-paste
(stale value from the previous wl-copy)  <- X11 write, invisible to Wayland
```

Neither direction crosses on its own, in either direction, so `vmtoolsd`
never sees anything a real (Wayland-native) window puts on the clipboard,
and nothing it pulls from the host ever reaches those windows either.

**Fix.** `scripts/vmware-clipboard-bridge.sh`, autostarted from
`hyprland.lua` right after `clipboard_fix.sh`: mirrors the two clipboards
both ways.

- **Wayland -> X11** is event-driven: `wl-paste --type text --watch` runs a
  callback on every change, which pushes it into `xclip -selection
  clipboard` on `:0`.
- **X11 -> Wayland** has to poll. `wl-clipboard` has no equivalent of X11's
  XFixes selection-owner-change event to hook, so this reconciles on an
  interval instead — the same tradeoff `vmware-autofit.sh` already makes
  for the display-resize gap above.
- A shared "last value" file (`$XDG_RUNTIME_DIR/vmware-clipboard-bridge.last`)
  stops the two legs echoing each other's own writes back and forth forever.

Same `flock` pattern as `vmware-autofit.sh`, on its own lock file, so a
second copy exits silently instead of stacking watchers.

The monitor rule in `hyprland.lua` stays at `mode = "preferred"`. It is the
right thing on real hardware, and the watcher corrects it here.

---

## Escaping a session you cannot use: `Ctrl+Alt+F3`

The failure that started all of this — a desktop that renders but takes no
keystrokes — has no in-session escape, because every escape *is* a keystroke.
VT switching is the exception, and it is worth knowing exactly why it holds.

`Ctrl+Alt+F3` is **not** bound in `hyprland.lua`, and must not be. Hyprland
handles it internally:

```
CKeybindManager::onKeyEvent
  └─ handleInternalKeybinds          <- zero references to submap state
       └─ handleVT                   <- range-checks XF86Switch_VT_1 (0x1008fe01)
            └─ Aquamarine::CSession::switchVT
                 └─ libseat_switch_session   <- logind does it; no root needed
```

Three consequences, all of them the point:

- it ignores the active submap, so being stuck in `SUPER+R` resize mode does
  not trap you;
- it ignores every user keybind, so a broken `hl.bind` cannot shadow it;
- it needs no root, because logind performs the switch on the session's behalf.

The keysym itself comes from `symbols/pc`, which includes
`srvr_ctrl(fkey2vt)` — `key.type = "CTRL+ALT"`, with `XF86_Switch_VT_3` at
level 5 of `<FK03>`. Every layout includes `pc`, so `kb_layout = "es"` gets it
like any other.

A login prompt appears on VT3 because `autovt@.service` is symlinked to
`getty@.service` and logind's default `NAutoVTs=6` spawns a getty on demand
for VTs 1–6. From there:

```bash
pkill -x Hyprland     # then Ctrl+Alt+F7 back to the display manager
```

**What it does not cover:** if libinput never bound a keyboard, no keystroke
reaches Hyprland at all, `Ctrl+Alt+F3` included. Nothing inside the session
can help there — recovering means powering the VM off. The evidence written
to `~/hyprland-diag.txt` and `~/hyprland-last.log` (below) is what survives
that, and it is what the input-race fix at the top of these notes prevents.

---

## Stale compositors hold the input lease

A Hyprland that crashed, or was launched from inside X, keeps its libseat lease
on the keyboard and mouse and starves the next session. The launcher kills any
survivor (plus stray waybar/hyprpaper) before starting.

---

## Evidence that survives a power-off

A session you cannot type in is one you can only end by powering off the VM —
which destroys the runtime log, since `/run/user/1000/hypr/<id>/hyprland.log`
is tmpfs. So:

- **`~/hyprland-last.log`** — stdout captured live by the launcher. Survives a
  hard power-off.
- **`~/hyprland-diag.txt`** — a watchdog fires 12s in, from *outside* the
  compositor, and `sync`s. Ends with a plain-language verdict so a recurrence
  needs no log reading:

  ```
  OK: libinput bound a keyboard (refused 1 device(s))
  BROKEN: libinput bound no keyboard, so typing cannot work.
  ```

  The verdict keys off libinput's own `is tagged by udev as: Keyboard` line,
  **not** `hyprctl devices` — `hyprctl devices` returned a completely empty list
  in a session whose mice demonstrably worked, so it cannot be trusted as a
  detector here. (`BUG THIS: setKeyboardFocus without a valid keyboard set`
  confirms the failure too, but only prints at shutdown, far too late.)

---

## Session entries

| File | What it is |
|---|---|
| `hyprland.desktop` | Normal session. `Exec=/usr/local/bin/start-hyprland-vmware` |
| `hyprland-diag.desktop` | `HYPR_DIAG_EXIT=45` — dumps diagnostics and **quits by itself after 45s**, so a broken-input session can be ended without power-cycling the VM |
| `hyprland-uwsm.desktop` | **Deleted.** `uwsm` is not packaged in Kali, so this entry drops you straight back to the greeter |

LightDM is pointed at Hyprland by default via
`/etc/lightdm/lightdm.conf.d/02-default-session.conf`. Note LightDM prefers
`~/.dmrc` once you've logged in at least once, so the installer sets both.

---

## Packages

Beyond what `install.sh` already covers:

```
hyprland xdg-desktop-portal-hyprland xwayland
waybar wofi dunst kitty nemo
grim slurp wl-clipboard swaylock swayidle
mate-polkit wireplumber
```

`mate-polkit` supplies `/usr/libexec/polkit-mate-authentication-agent-1`, which
the Lua config autostarts — without it, anything asking for authentication just
fails with no prompt. `wireplumber` provides the `wpctl` the volume binds call.

---

## Superseded

`fix-hyprland-vmware.sh` (the old root-level script) is **obsolete**. It set
`WLR_RENDERER_ALLOW_SOFTWARE` / `WLR_NO_HARDWARE_CURSORS` / `GBM_BACKEND`, which
are wlroots variables that Hyprland 0.56 ignores entirely, and it did nothing
about the input race — the one thing that actually broke the desktop. Use
`vmware/install-vmware.sh`.
