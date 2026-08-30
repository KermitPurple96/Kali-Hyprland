# Kali Hyprland Configuration

A complete Kali Linux desktop configuration repository with both **Hyprland** (modern Wayland) and **i3-gaps** (classic X11) setups. Choose your preferred environment or install both!

![Preview](field1.jpg)

> ### Running in a VMware VM? Read this first.
>
> Hyprland 0.56 (what Kali ships) needs extra work in a VM, and the plain
> install below is **not** enough — you get a desktop where the mouse works and
> the keyboard is dead, with no way out but powering off the guest.
>
> ```bash
> cd vmware && ./install-vmware.sh
> ```
>
> Root cause, every change, and the dead ends already ruled out are written up
> in **[VMWARE-NOTES.md](VMWARE-NOTES.md)**. Two things that bite immediately:
> the config format is now **Lua** (`hyprland.lua`; a `hyprland.conf` still
> loads on 0.56 but prints *"support for which will be removed in Hyprland
> 0.57"*), and `fix-hyprland-vmware.sh` is obsolete — it sets wlroots variables
> that 0.56 does not use.

##  Two Setups in One Repository

### Hyprland (Wayland) - Recommended ⭐
Modern, smooth, GPU-accelerated compositor with built-in effects.

**The look is [kali-clean](https://github.com/KermitPurple96/kali-clean)'s**,
down to the hex values — same palette, same `gaps inner 2 / outer 4`, same bar
layout, same keybindings — plus the three things i3 could never do:

| | |
|---|---|
| **Rounded corners** | 10px, on every window |
| **Blur** | behind kitty, the bar, the launcher and notifications |
| **Animations** | window open/close/move, workspace slide, 100ms focus border |
| **Borders** | 1px — lime `#00FF00` focused, `#333333` everywhere else |

The wallpaper is John Martin's *Le Pandemonium* (Louvre), installed to
`~/.wallpaper/John_Martin_Le_Pandemonium_Louvre.jpg` and picked up by both
sessions — `swaybg` under Hyprland, `feh` via `~/.fehbg` under i3.

**The palette, straight out of the kali-clean i3 config:**

| Role | Hex | Where it came from |
|---|---|---|
| Ground | `#1C1D2B` | i3bar `background` |
| Raised | `#282A3E` | `focused_workspace` |
| Text | `#E6FFF5` | `statusline` |
| Accent | `#82c8ff` | `client.focused` |
| Inactive | `#333333` | `client.unfocused` |
| Urgent | `#900000` | `client.urgent` |
| VPN up | `#3BB92D` | i3blocks `[iface]` `color=` |

**Built for a machine with no GPU.** In a VMware guest, "Accelerate 3D
graphics" is often not an option at all — on many hosts the VM simply stops
booting with it on — so this config assumes `vmwgfx` reports *"Available
shader model: Legacy"*, there is no GLES 3.x, and Hyprland renders through
**llvmpipe on the CPU**. The effects stay; they are just chosen with the
per-pixel cost in mind.

One config, three profiles, selected with an environment variable:

| `HYPR_EFFECTS` | Blur | Shadows | Window anims | Workspace anims |
|---|---|---|---|---|
| `soft` **(default)** | 1 pass, size 4, xray, cached | — | yes, 300ms | — |
| `full` | 2 passes, size 6, noise + vibrancy | yes | yes, 500ms | slidevert |
| `lite` | — | — | — | — |

Rounded corners are in all three. `soft` is the default because it is the one
that makes sense without a GPU; `full` is there for real hardware.

**Why those particular cuts?** Software rendering cost is *damaged pixels ×
passes over them*:

- **blur passes are a multiplier** — one pass costs about half of two
- **`new_optimizations`** caches blur for surfaces that have not changed, so a
  still terminal costs nothing per frame. It is on in every profile.
- **`xray`** lets floating windows blur the wallpaper instead of re-blurring
  the windows stacked under them
- **noise and vibrancy** are extra per-pixel maths on top of the blur itself
- **workspace animations redraw every pixel on screen** for their whole
  duration, and it is the action you trigger most often — so `soft` switches
  workspaces instantly and keeps the animations that are bounded to one
  window's box
- **shadows** are overdraw around every window for the smallest visual return

In a VM, `vmware/install-vmware.sh` installs a **"Hyprland (lite)"** entry at
the login screen. Everything else — colours, keybinds, bar, launcher — is
identical across all three.

**Measuring instead of guessing:** start a session with `HYPR_OVERLAY=1` for
Hyprland's frame-timing overlay, change one value in `hyprland.lua`, and press
`Super + Shift + C` to reload.

**Also kept from the VM work:**
- `debug.vfr` on, so idle frames aren't redrawn. Biggest single CPU win in a VM.
- A terminal opens at login no matter what, and the rescue keybinds avoid
  `SUPER` — so a broken session is still recoverable.

**Components:**
- Hyprland (compositor + WM)
- Waybar (status bar)
- Wofi (app launcher)
- Kitty (terminal)
- Dunst (notifications)
- mate-polkit (authentication agent) — VM profile autostarts it

### i3-gaps (X11) - Classic Setup
Traditional tiling window manager setup from the original kali-clean repo.

**Features:**
- Classic i3 tiling workflow
- Compton compositor
- Rofi launcher
- Alacritty terminal
- Pywal color schemes

**Components:**
- i3 (window manager — gaps are built into upstream i3 since 4.22, so this
  is the plain Kali `i3` package, not a source build of `i3-gaps`)
- i3blocks (status bar)
- Compton (compositor)
- Rofi (app launcher)
- Alacritty (terminal)

##  Testing it without risking a black screen

Read this before you log out. There are three independent escapes, and they
fail in different ways on purpose.

### 1. `Ctrl + Alt + F3` — the one that always works

Switches to a text console. This is **not** a keybind in this config, and
deliberately so: Hyprland handles `Ctrl+Alt+F1..F12` internally in
`CKeybindManager::handleVT`, called straight from `onKeyEvent`. That path
never consults the active submap or any user keybind, and it performs the
switch through **libseat → logind**, so it needs no root. It keeps working
when every other binding in this file is broken.

Verified on this machine, not assumed:

| Link in the chain | Checked |
|---|---|
| `Ctrl+Alt+F3` produces the `XF86_Switch_VT_3` keysym | `symbols/pc` includes `srvr_ctrl(fkey2vt)`, key type `CTRL+ALT` |
| Hyprland acts on that keysym | binary range-checks `0x1008fe01` then calls `Aquamarine::CSession::switchVT` |
| the switch needs no root | `switchVT` → `libseat_switch_session` |
| a login prompt appears on VT3 | `autovt@.service → getty@.service`, logind `NAutoVTs=6` |
| the submap cannot block it | `handleInternalKeybinds` contains zero references to submap state |

Once you have a console:

```bash
pkill -x Hyprland     # then Ctrl+Alt+F7 to return to the login screen
```

Install the session entries (and `swaybg`) with the one script that only
touches root-owned files — no `apt upgrade`, no waiting:

```bash
cd Kali-Hyprland/vmware && ./update-system.sh
```

It also deletes `hyprland-uwsm.desktop`. `uwsm` is not packaged in Kali, so
that entry can never start; picking it drops you back at the greeter, which
looks exactly like a crash. The Hyprland package puts it back on upgrade, so
re-run the script after one.

### 2. "Hyprland (safe test)" — use this the first time

A login-screen entry that arms a **120-second dead-man's switch**
(`HYPR_SAFETY=120`). Press **`Ctrl + Alt + O`** to keep the session. If you
do not — because the screen is black, or the keyboard never bound, or a
keybind failed to register — it ends the session itself and hands you back to
the display manager.

Confirming is a *keybind* rather than a click on purpose: pressing it proves
the two things that have actually failed on this machine both work (libinput
bound a keyboard, and binds registered), and seeing its notification proves
rendering works. If any of those is broken you cannot confirm, which is
exactly when you want the auto-exit.

### 3. `Ctrl + Alt + Backspace` — clean exit on demand

A normal rescue bind, `submap_universal`, so it works from inside resize mode
too. Needs working keybinds, so it is the weakest of the three — but it is
the tidiest when things *are* working.

> **Recovering a stuck session from the host is never necessary.** If input is
> dead, `~/hyprland-diag.txt` says so in plain words within ~12 seconds, and
> `~/hyprland-last.log` survives a power-off. See
> [VMWARE-NOTES.md](VMWARE-NOTES.md).

##  Quick Install

### One-Line Installation

```bash
git clone https://github.com/KermitPurple96/Kali-Hyprland
cd Kali-Hyprland
chmod +x install.sh
./install.sh
```

The installer will ask you which setup you want:
1. **Hyprland only** - Modern Wayland setup
2. **i3** - Classic X11 setup
3. **Both** - Install both, choose at login

### Unattended installation

Every prompt has a flag, so the whole desktop can go on in one command with
no questions asked:

```bash
./install.sh --hyprland          # Hyprland only
./install.sh --i3                # i3 only
./install.sh --both              # both, pick at the login screen
./install.sh --all               # both + Oh My Zsh + the VMware session entries
```

| Flag | Effect |
|---|---|
| `--hyprland` / `--i3` / `--both` | choose the session type without being asked |
| `--all` | `--both` plus Oh My Zsh plus `--vmware` |
| `-y`, `--yes` | answer yes to every prompt |
| `--no-zsh` | never install Oh My Zsh |
| `--vmware` | also run `vmware/update-system.sh` (session launcher + login entries) |
| `--skip-upgrade` | skip `apt upgrade`, still does `apt update` |
| `-h`, `--help` | usage |
| `NERD_VER=v3.4.0 ./install.sh` | pull a different Nerd Fonts release (default `v2.1.0`) |

The installer is safe to run more than once: it moves any existing
`~/.config/{hypr,waybar,wofi,dunst,i3,compton,rofi,alacritty}` aside as
`<name>.backup.<timestamp>` before writing the new one, and a package that
does not exist on your Kali release is reported and skipped rather than
taking the rest of the install down with it.

### What it installs

Everything kali-clean installed, plus the Wayland replacements for the parts
of it that are X11-only:

| kali-clean (X11) | Kali-Hyprland (Wayland) | For |
|---|---|---|
| `feh` | `swaybg` | wallpaper |
| `rofi` | `wofi` | app launcher |
| `i3blocks` + `i3bar` | `waybar` | status bar |
| `compton` | built into Hyprland | blur, rounding, shadows |
| `flameshot` | `grim` + `slurp` | screenshots |
| `lxappearance` | `nwg-look` | GTK theming |
| `arandr` | `wdisplays`, `wlr-randr` | monitor layout |
| `alacritty` | `kitty` | terminal |
| `unclutter` | `cursor_inactive_timeout` | hiding the pointer |

Shared by both: `flameshot`, `feh`, `arc-theme`, `papirus-icon-theme`,
`imagemagick`, `thunar`, `kitty`, `pavucontrol`, `brightnessctl`,
`playerctl`, `pywal`, and the Hack / RobotoMono / Iosevka Nerd Fonts.

> **On fonts.** The Debian package `fonts-hack` is *not* Hack Nerd Font. It
> has the letterforms but none of the patched glyphs, so every icon in the
> bar renders as an empty box. The installer fetches the real Nerd Font
> build from the nerd-fonts releases and then tells you whether
> `Hack Nerd Font` is actually available.

> **On i3 gaps.** There is no `i3-gaps` source build any more. Gaps have been
> part of upstream i3 since 4.22 and Kali ships 4.25, so `gaps inner 2` in
> the config just works — which also removes the ~25 `-dev` packages and the
> meson/ninja compile that kali-clean needed.

##  What's Included

### Hyprland Configuration

**Which config file does Hyprland read?** This decides everything below.

| Hyprland | Reads | In this repo |
|---|---|---|
| **0.51+** (Kali ships 0.56) | `~/.config/hypr/hyprland.`**`lua`** | `.config/hypr/hyprland.lua` |
| pre-0.51 | `~/.config/hypr/hyprland.conf` | `legacy/hyprland.conf` |

0.56 still loads a `hyprland.conf`, but it prints *"You are using the .conf
config format, support for which will be removed in Hyprland 0.57"* — so the
`.lua` is the one that is maintained here, and the `.conf` is kept only so the
repo still works on an older Hyprland. **Never put both in `~/.config/hypr`.**
Check your version with `hyprctl version`.

```
.config/
├── hypr/
│   ├── hyprland.lua       # The config. Hyprland 0.51+
│   └── scripts/
│       ├── wallpaper.sh   # swaybg; the Wayland stand-in for ~/.fehbg
│       ├── screenshot.sh  # grim + slurp; stands in for flameshot gui
│       ├── exit.sh        # wofi; stands in for i3-nagbar
│       ├── safety-net.sh  # HYPR_SAFETY dead-man's switch (CTRL+ALT+O)
│       └── polkit-agent.sh # starts whichever agent this box shipped
├── waybar/
│   ├── config             # i3blocks, module for module
│   ├── style.css          # the i3bar `colors {}` block, in GTK CSS
│   └── scripts/vpn.sh     # i3blocks [iface] instance=tun0
├── wofi/
│   ├── config             # geometry from kali-clean's rofi config
│   └── style.css          # Wofi styling
├── dunst/
│   └── dunstrc            # notifications, same palette
└── kitty/
    └── kitty.conf         # 0.80 alpha + background_blur -- see below

legacy/
└── hyprland.conf          # the same setup in the pre-0.51 .conf format
```

### i3-gaps Configuration
```
.config/
├── i3/
│   ├── config             # i3 configuration
│   ├── i3blocks.conf      # Status bar config
│   └── clipboard_fix.sh   # Clipboard fix script
├── compton/
│   └── compton.conf       # Compositor config
├── rofi/
│   └── config             # Rofi launcher config
├── alacritty/
│   └── alacritty.yml      # Terminal configuration
└── .wallpaper/            # Wallpaper directory
```

## ⌨️ Keybindings

`Super` (Windows key) is the modifier in both setups. **The Hyprland map is
kali-clean's i3 map**, key for key, so muscle memory carries straight over.

Note the focus row: kali-clean uses the vim row *shifted one key right* —
`j`=left, `k`=down, `l`=up, `;`=right. On a Spanish layout `ñ` sits where a US
keyboard puts `;`, so both are bound.

### Rescue binds — deliberately not on `SUPER`

A VMware host can grab the Super key, and a bind that fails to register leaves
you with no way out but powering off the guest. These always work:

| Key | Action |
|---|---|
| `Ctrl + Alt + T` | Terminal |
| `Alt + Return` | Terminal |
| `Ctrl + Alt + Backspace` | Exit Hyprland cleanly |
| `Ctrl + Alt + O` | Confirm a `HYPR_SAFETY` test session is usable |

They stay live inside the resize submap too (`submap_universal`).

`Ctrl + Alt + F3` is **not** in this table because it is not a keybind at all
— Hyprland handles VT switching internally, below the keybind layer. That is
what makes it the escape of last resort. See
[Testing it without risking a black screen](#-testing-it-without-risking-a-black-screen).

### Hyprland — mirroring kali-clean's i3

| Key | Action | i3 line it came from |
|---|---|---|
| `Super + Return` | Terminal (kitty) | `exec alacritty` |
| `Super + Shift + Return` | File manager (thunar) | *new* |
| `Super + Shift + Q` | Close window | `kill` |
| `Super + D` | App launcher (wofi) | `exec "rofi -show run"` |
| `Super + J / K / L / ;` | Focus left / down / up / right | `focus left` … |
| `Super + ←↓↑→` | Focus, arrow keys | `focus left` … |
| `Super + Shift + J/K/L/;` | Move window | `move left` … |
| `Super + H` | Split horizontal (next window opens right) | `split h` |
| `Super + V` | Split vertical (next window opens below) | `split v` |
| `Super + E` | Toggle split | `layout toggle split` |
| `Super + S` / `Super + W` | Group — Hyprland's one primitive for i3's stacking *and* tabbed | `layout stacking` / `layout tabbed` |
| `Super + Tab` / `Super + Shift + Tab` | Next / previous window in the group | *new* |
| `Super + F` | Fullscreen | `fullscreen toggle` |
| `Super + Shift + Space` | Toggle floating | `floating toggle` |
| `Super + Space` | Cycle floating windows | `focus mode_toggle` |
| `Super + A` | Focus last window — see the note below | `focus parent` (no exact equivalent) |
| `Super + P` | Pseudo-tile | *dwindle extra* |
| `Super + C` | Center window | *dwindle extra* |
| `Super + 1..0` | Switch workspace | `workspace 1` … |
| `Super + Shift + 1..0` | Move window to workspace | `move container to workspace 1` … |
| `Super + Scroll` | Cycle workspaces | *new* |
| `Super + R` | **Resize mode** — `Escape`/`Return` to leave | `mode "resize"` |
| `Super + Ctrl + Shift + ←↓↑→` | Resize without entering the mode | same binds in i3 |
| `Super + Shift + C` / `Super + Shift + R` | Reload config (Hyprland re-reads in place; there is no separate restart) | `reload` / `restart` |
| `Super + Shift + E` | Exit, with a wofi confirmation | `i3-nagbar … i3-msg exit` |
| `Super + Shift + P` | Screenshot region → clipboard **and** `~/Pictures` | `exec flameshot gui` |
| `Print` | Whole screen → clipboard | *new* |
| `Super + Left-drag` | Move window | `floating_modifier $mod` |
| `Super + Right-drag` | Resize window | `floating_modifier $mod` |
| `XF86Audio*` | Volume / mute via `wpctl` | *new* |

Inside resize mode the same `j/k/l/;` and arrow keys resize by 20px, exactly
as i3's `resize shrink width 10 px or 10 ppt` block did.

**Every binding in kali-clean's i3 config is accounted for above except one.**
`$mod+a` (*focus parent*) has no true Hyprland equivalent. i3 builds a tree of
containers and `$mod+a` walks up it, so the next command applies to the parent
instead of the window; dwindle has no addressable parent container, and 0.56
ships no `focusparent` dispatcher — the `hl.dsp` surface in
`/usr/share/hypr/stubs/hl.meta.lua` lists `focus`, `window.*`, `group.*`,
`workspace.*` and `cursor.*`, and nothing that walks a tree.

So `Super + A` is bound to the nearest genuinely useful thing instead —
`hl.dsp.focus({ last = true })`, jump back to the window you came from. If
what you wanted the parent for was *"treat these windows as one unit"*, that
is `Super + S` / `Super + W` (groups).

Keyboard layout is `es`. Change `kb_layout` in `.config/hypr/hyprland.lua` —
it is the only machine-specific line in the file.

### i3-gaps

Identical to the table above, minus the Hyprland-only extras (groups replace
stacking/tabbed, `Super + P` is pseudo-tile rather than screenshot).

##  Customization

### Hyprland

All of this lives in `~/.config/hypr/hyprland.lua`.

#### Change colours
The palette is five named locals at the top of the file, so one edit changes
the borders, the groupbar and anything else that uses them:

```lua
local accent   = "rgba(82c8ffff)"   -- i3: client.focused
local inactive = "rgba(333333ff)"   -- i3: client.unfocused
```

Waybar, wofi and dunst carry the same hexes in their own stylesheets
(`~/.config/waybar/style.css`, `~/.config/wofi/style.css`,
`~/.config/dunst/dunstrc`) — change them there to match.

#### Adjust blur
```lua
blur = {
    enabled = true,
    size    = 6,   -- blur radius (1-20)
    passes  = 2,   -- quality (1-4, higher = slower)
},
```

Kitty's translucency is what blur has to work with, and it is set in
`~/.config/kitty/kitty.conf` (`background_opacity 0.80`) — **not** with a
window rule. Setting both multiplies them and the terminal goes murky.

**Kitty asks for the blur itself, too.** `background_blur 1` is set in
`kitty.conf`. That option is often described as macOS-only, and that is out
of date: kitty takes effect on "macOS and Wayland, when the compositor
supports the background blur extension", and Hyprland 0.56 implements it —

```console
$ strings /usr/bin/Hyprland | grep ext_background
ext_background_effect_manager_v1
ext_background_effect_surface_v1
```

Two things worth knowing about that line:

- the integer is a blur *radius* only on macOS. On Wayland it is a flag, so
  `1` is the honest value and a bigger number buys nothing — the radius comes
  from `decoration:blur:size`.
- it does **not** stack into a double blur. It is a request to blur the
  region behind the surface, which the compositor is already doing.

Under a compositor without the extension the line is simply ignored, never an
error.

#### Border thickness and the focus colour
One global covers every window, Wayland-native and XWayland alike — there
are no per-app border rules to write:

```lua
general = {
    border_size = 1,              -- 1 is the minimum that still draws
    col = { active_border = focus },   -- focus = rgba(00ff00ff)
}
```

`border_size = 0` removes the border altogether, and with it the focus
indicator and the drag-to-resize edge, so 1 is the practical floor. At that
width the colour has to be bright to register at all, which is why the
focused border is full-intensity lime rather than a muted green.

`focus` is deliberately a separate colour from `accent`: the bar, the
launcher and notifications keep kali-clean's `#82c8ff`, and lime means one
thing only — *this window has focus*. The same 1px lime is mirrored in
`~/.config/i3/config` (`border pixel 1`, `client.focused #00FF00`) so both
sessions look identical, and in `~/.config/wofi/style.css`, since the
launcher does hold focus while it is open. `~/.config/dunst/dunstrc` thins
to `frame_width = 1` but keeps the blue palette, because a notification is
never the focused window.

#### Animation speed — `speed` is in DECISECONDS
This is the unit that catches people out. `speed = 10` is a **one second**
animation, not a fast one. The focus border was on `speed = 10`, which is
why moving between windows with `SUPER+arrow` looked like it lagged: the
border was doing a full one-second crossfade from grey to lime.

Per-profile timings now live in the `FX` table at the top of the config:

| | `soft` (default) | `full` | `lite` |
|---|---|---|---|
| `border_speed` — focus feedback | 1 (100ms) | 2 | 1 |
| `ws_speed` — workspace slide | 2 (200ms) | 4 | — |
| `anim_speed` — window open/close/move | 3 (300ms) | 5 | off |
| workspace animation | on | on | off |
| `blur_size` | 5 | 8 | off |

Workspace switching redraws every pixel on screen for the whole animation,
so on a CPU renderer the lever that keeps it affordable is **duration, not
curve** — 200ms is few enough frames for llvmpipe to composite while still
reading as a slide. It also uses `wind` rather than an overshoot bezier: an
overshoot travels past the target and comes back, which means compositing
extra full-screen frames for an effect you barely notice.

#### Modify animations
```lua
hl.curve("overshot", { type = "bezier", points = { {0.13, 0.99}, {0.29, 1.10} } })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 5, bezier = "overshot", style = "popin 80%" })
--                    ^                            ^                  ^                   ^
--                    |                            |                  |                   └─ style
--                    |                            |                  └───────────────────── curve
--                    |                            └──────────────────────────────────────── deciseconds
--                    └───────────────────────────────────────────────────────────────────── what to animate
```

`speed` is in *deciseconds* — `speed = 5` is 500ms.

#### Change profile
Start the session with `HYPR_EFFECTS=soft` (default), `full` or `lite` — in a
VM, pick the **"Hyprland (lite)"** login entry for the last one. Colours,
gaps, borders, keybindings and rounded corners are the same in all three.

The profiles are a table at the top of `hyprland.lua`, so retuning one is a
single edit:

```lua
soft = {
    blur = true,  blur_size = 4, blur_passes = 1,
    blur_xray = true,  blur_popups = false,
    ...
},
```

### i3-gaps

#### Set Wallpaper & Colors
```bash
# Generate a colour scheme from the wallpaper.
# NOTE the command is `wal`, not `pywal` -- pywal is the package name.
wal -i ~/.wallpaper/John_Martin_Le_Pandemonium_Louvre.jpg

# Or set the wallpaper directly with feh
feh --bg-fill ~/.wallpaper/John_Martin_Le_Pandemonium_Louvre.jpg
```

`~/.fehbg` is what re-applies it on every login; edit that one line to
change the wallpaper permanently. Under Hyprland the equivalent is
`~/.config/hypr/scripts/wallpaper.sh`, which takes the first image it finds
in `~/.wallpaper/` and can be overridden per-session with
`WALLPAPER=/path/to/image.jpg`.

#### Change Theme
```bash
# Run appearance settings
lxappearance
# Select arc-dark theme
```

##  Manual Installation

### Install Dependencies

**For Hyprland:**
```bash
sudo apt install -y hyprland waybar wofi dunst grim slurp \
    wl-clipboard swaybg swaylock swayidle xdg-desktop-portal-hyprland \
    xwayland kitty thunar mate-polkit wireplumber \
    network-manager-gnome fonts-hack papirus-icon-theme
```

Three of these are easy to miss and each breaks something visible:

| Package | Without it |
|---|---|
| `swaybg` | no wallpaper at all — feh cannot paint a Wayland root window |
| `mate-polkit` | anything asking for authentication fails with no prompt |
| `wireplumber` | the volume keys do nothing (`wpctl` is what they call) |

`fonts-hack` backs the `Hack Nerd Font` the bar, launcher, groupbar and
terminal all ask for.

**For i3-gaps:**
```bash
sudo apt install -y i3 i3blocks rofi compton alacritty feh \
    arandr arc-theme lxappearance python3-pip
pip3 install pywal
```

### Copy Configurations

```bash
# Copy desired configs
cp -r .config/hypr   ~/.config/   # Hyprland (hyprland.lua + scripts/)
cp -r .config/waybar ~/.config/   # Waybar
cp -r .config/wofi   ~/.config/   # Wofi
cp -r .config/dunst  ~/.config/   # Dunst
cp -r .config/kitty  ~/.config/   # Kitty
cp -r .config/i3     ~/.config/   # i3 (Hyprland reuses clipboard_fix.sh)
cp -r .wallpaper     ~/           # wallpaper.sh looks in ~/.wallpaper

chmod +x ~/.config/hypr/scripts/*.sh ~/.config/waybar/scripts/*.sh \
         ~/.config/i3/clipboard_fix.sh
```

On a Hyprland older than 0.51, delete `~/.config/hypr/hyprland.lua` and use
`legacy/hyprland.conf` instead.

##  Troubleshooting

### Hyprland won't start
- Ensure you have a compatible GPU (Intel, AMD, or NVIDIA with proper drivers)
- Check logs: `cat $XDG_RUNTIME_DIR/hypr/*/hyprland.log`
- Verify config: `hyprctl configerrors`
- **In a VM:** see [VMWARE-NOTES.md](VMWARE-NOTES.md). The runtime log above
  lives on tmpfs and is destroyed by a power-off, which is exactly how a broken
  session ends — so `vmware/start-hyprland-vmware` mirrors it to
  `~/hyprland-last.log`, which survives.

### Mouse works but the keyboard is completely dead
A startup race, not a config problem, and the single worst failure mode in a
VM: libinput enumerates `/dev/input` once and never retries, so if logind
hasn't made the session `Active` yet the keyboard is dropped for good. The
mice usually win the race, so the desktop looks alive while no key ever lands.

`vmware/start-hyprland-vmware` fixes it by waiting for `Active=yes` first.
To confirm which way a session went, read the bottom of `~/hyprland-diag.txt`:

```
OK:     libinput bound a keyboard (refused 1 device(s))
BROKEN: libinput bound no keyboard, so typing cannot work.
```

Do **not** diagnose this with `hyprctl devices` — it has returned an empty
list in a session whose mice demonstrably worked. Full writeup in
[VMWARE-NOTES.md](VMWARE-NOTES.md).

### Picking "Hyprland" at the login screen just returns to the login screen
You most likely selected **Hyprland (uwsm-managed)**. `uwsm` isn't packaged in
Kali, so that entry can never start. Pick plain **Hyprland**;
`vmware/install-vmware.sh` deletes the dead entry outright.

### Everything is sluggish
You are on software rendering — expected in this guest, and what the default
`soft` profile is built for. Confirm it:

```bash
grep '^renderer:' ~/hyprland-last.log        # what the session actually used
grep '^effects:'  ~/hyprland-last.log        # which profile was active
journalctl -k -b | grep -i 'shader model'    # vmwgfx's own verdict
```

`Available shader model: Legacy` means no GLES 3.x and therefore llvmpipe.

**Do not try to fix this by enabling "Accelerate 3D graphics" in the VM
settings.** On many hosts that option prevents the VM from booting at all,
and nothing here needs it.

What to do instead, in order:

1. Log out, pick the **"Hyprland (lite)"** session. If that is smooth, the
   cost is in blur/animations and you can tune `soft` between the two.
2. Start with `HYPR_OVERLAY=1` and watch the frame timings while you change
   one value at a time in `~/.config/hypr/hyprland.lua` (`Super + Shift + C`
   reloads).
3. The cheapest wins, in order of effect: drop `blur_passes` to `1` (already
   the case in `soft`), then `blur_size` to `3`, then set `blur = false` and
   keep the animations, which are usually not the problem.
4. Lower the guest resolution. Software rendering cost is linear in pixels,
   and a VMware guest auto-fits to whatever the window is — a smaller window
   is genuinely a faster desktop.

### Waybar not showing
```bash
killall waybar
waybar &
```

### i3 clipboard issues
The clipboard fix script should run automatically. If not:
```bash
~/.config/i3/clipboard_fix.sh
```

### Pywal not working
Current Kali marks its Python as externally managed (PEP 668), so the old
`pip3 install pywal` now fails with *"error: externally-managed-environment"*.
Use pipx, which gives it its own venv and still puts `wal` on `PATH`:

```bash
sudo apt install pipx
pipx install pywal
pipx ensurepath          # adds ~/.local/bin to PATH

# last resort, if you really want it in the user site-packages:
pip3 install --user --break-system-packages pywal
export PATH="$HOME/.local/bin:$PATH"
```

The command is `wal`, not `pywal`.

##  Comparison: Hyprland vs i3-gaps

| Feature | Hyprland | i3-gaps |
|---------|----------|---------|
| Display Server | Wayland | X11 |
| Rounded Corners |  Built-in |  Needs separate tool |
| Blur |  Fast, built-in | ️ Slow with picom/compton |
| Animations |  Smooth | ️ Limited |
| Performance |  High |  Good |
| Stability |  Very stable |  Very stable |
| Tearing |  No tearing | ️ Can occur |
| Learning Curve |  Medium |  Medium |
| App Compatibility | ️ Most apps (XWayland) |  All X11 apps |
| Gaming |  Good |  Good |
| VM Support |  Works, see [VMWARE-NOTES.md](VMWARE-NOTES.md) |  Excellent |

**Recommendation:**
- **Physical machine → Hyprland** (better performance, modern features)
- **Virtual machine → either**; for Hyprland run `vmware/install-vmware.sh` first, and expect the `soft` profile rather than `full`

##  Tips

1. **First time with Hyprland?** The keybindings are kali-clean's i3 map, key for key, so muscle memory transfers.
2. **Performance:** Hyprland is normally GPU-accelerated. In a VM without host 3D it renders on the CPU through llvmpipe instead — which is why the default `soft` profile exists, and why it cuts full-screen animations rather than the effects you actually look at. Do not chase this by enabling 3D acceleration in the VM settings; on many hosts the VM then will not boot.
3. **Missing wallpaper?** Copy your images to `~/.wallpaper/` — and make sure `swaybg` is installed, or nothing can paint a Wayland background at all.
4. **Customize!** All configs are in `~/.config/` - edit to your liking
5. **Switch between setups:** Both can be installed - just select at login screen

##  Repository Structure

```
Kali-Hyprland/
├── .config/
│   ├── hypr/           # hyprland.lua + scripts/
│   ├── waybar/         # config, style.css, scripts/vpn.sh
│   ├── wofi/           # Wofi config
│   ├── dunst/          # Notification theme
│   ├── i3/             # i3 config
│   ├── compton/        # Compton config
│   ├── rofi/           # Rofi config
│   ├── alacritty/      # Alacritty config
│   └── kitty/          # Kitty config
├── legacy/
│   └── hyprland.conf   # Same setup, pre-0.51 .conf format
├── vmware/             # VMware guest deploy
│   ├── install-vmware.sh       # Full deploy: packages + configs + sessions
│   ├── update-system.sh        # Just the root-owned half (fast, no apt upgrade)
│   ├── start-hyprland-vmware   # Session launcher (fixes the input race)
│   ├── hyprland.desktop        # LightDM session entry
│   ├── hyprland-test.desktop   # 120s dead-man's switch -- use this first
│   ├── hyprland-lite.desktop   # Same config, HYPR_EFFECTS=lite
│   ├── hyprland-diag.desktop   # Self-exiting diagnostic session
│   └── 02-default-session.conf # Make Hyprland the LightDM default
├── .wallpaper/         # Wallpaper directory
├── .fehbg              # Wallpaper setter script
├── install.sh          # Installation script
├── VMWARE-NOTES.md     # VM root-cause writeup
├── README.md           # This file
└── field1.jpg          # Preview image
```

##  Contributing

Feel free to submit issues, fork the repository, and create pull requests for any improvements!

##  License

MIT License - Feel free to use and modify!

##  Credits

- **Author:** KermitPurple96
- **Hyprland:** by [vaxerski](https://github.com/hyprwm/Hyprland)
- **i3-gaps:** by [Airblader](https://github.com/Airblader/i3)
- **Original i3 setup:** From [kali-clean](https://github.com/KermitPurple96/kali-clean)
- **Inspired by:** Kali Linux default themes

##  Support

- **Issues:** https://github.com/KermitPurple96/Kali-Hyprland/issues
- **Hyprland Wiki:** https://wiki.hyprland.org
- **i3 User's Guide:** https://i3wm.org/docs/userguide.html

---

**Enjoy your beautiful Kali Linux setup! **

*Generated with [Claude Code](https://claude.com/claude-code)*
