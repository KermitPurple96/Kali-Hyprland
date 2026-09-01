# Kali-Hyprland

The [i3-kitty](https://github.com/KermitPurple96/i3-kitty) desktop, moved to
Wayland. Same palette, same gaps, the same keybindings — plus the three
things i3 could never do: real window animations, rounded corners and blur.

Both sessions are supported: **Hyprland** (Wayland) and the original **i3**
(X11). You pick one at the login screen.

| | |
|---|---|
| **Compositor** | Hyprland 0.56 (Lua config) |
| **Bar** | Waybar — the i3blocks pentest modules, ported |
| **Launcher** | fuzzel (falls back to wofi, then rofi) |
| **Terminal** | kitty |
| **Notifications** | dunst |
| **Wallpaper** | swaybg — John Martin, *Le Pandemonium* |
| **Clipboard** | cliphist |
| **Shell** | fish |

---

## 1. Installation

```bash
git clone https://github.com/KermitPurple96/Kali-Hyprland
cd Kali-Hyprland
```

There are five scripts. You normally run the first two, plus the third if
you are in a VM. `theme.sh` is called for you by both installers; run it by
hand only to re-apply or change the theme.

### `./install.sh` — the desktop

```bash
./install.sh                 # interactive: Hyprland, i3, or both
./install.sh --hyprland      # no questions asked
./install.sh --i3
./install.sh --both
./install.sh --all           # both + Oh My Zsh + the VMware session entries
```

| Flag | Effect |
|---|---|
| `--hyprland` / `--i3` / `--both` | choose the session without being asked |
| `--all` | `--both` + Oh My Zsh + `--vmware` |
| `-y`, `--yes` | answer yes to every prompt |
| `--no-zsh` | never install Oh My Zsh |
| `--vmware` | also run `vmware/update-system.sh` |
| `--skip-upgrade` | skip `apt upgrade` (still does `apt update`) |
| `NERD_VER=v3.4.0 ./install.sh` | different Nerd Fonts release (default `v2.1.0`) |

Safe to re-run: existing `~/.config/{hypr,waybar,wofi,dunst,fuzzel,i3,…}`
are moved aside as `<name>.backup.<timestamp>` first, and a package missing
from your Kali release is reported and skipped instead of aborting the run.

It installs the desktop, the fonts, the configs, and the Wayland
replacements for the X11 tools — fuzzel for rofi, cliphist for clipmenu,
nwg-look for lxappearance, wdisplays for arandr, grim+slurp for flameshot.

> **On fonts.** The Debian package `fonts-hack` is *not* Hack Nerd Font — it
> has the letterforms but none of the patched glyphs, so every icon in the
> bar renders as a tofu box. The installer fetches the real Nerd Font build
> and then tells you whether `Hack Nerd Font` actually ended up available.

### `./tools.sh` — the tooling

i3-kitty's `config.sh`, reworked for a Hyprland box.

```bash
./tools.sh                 # everything
./tools.sh --apt           # distro packages only
./tools.sh --python        # pipx / uv
./tools.sh --go --rust --npm
./tools.sh --bin           # release binaries: lsd, bat, rustscan, kerbrute, jump…
./tools.sh --git           # ~/dev checkouts and personal scripts
./tools.sh --wordlists
./tools.sh --dry-run       # print what would happen, change nothing
./tools.sh --voided        # what was dropped for Hyprland, and why
```

Every step checks for what it installs first, so re-running is cheap.

**No security tool was cut.** What *was* dropped is the X11 desktop
scaffolding: `config.sh` names 141 apt packages and 41 of them exist only to
support an i3 desktop — `i3`/`i3blocks`, `compton`, `rofi`/`dmenu`,
`xsel`/`xdotool`, `unclutter`, `arandr`, `lxappearance`, `flameshot`, `feh`,
`fonts-font-awesome`, `snapd`, plus the whole i3-gaps build chain (`meson`,
`ninja-build`, `autoconf` and ~25 `libxcb-*-dev`) for a compile that upstream
i3 made unnecessary in 4.22. Choose the i3 session in `install.sh` and they
all come back — they live in that branch now.

`tools.sh` also deliberately does **not** reboot, does **not** run `chsh`,
and does **not** start BloodHound's `docker-compose up` in the foreground.

### `vmware/update-system.sh` — the root-owned half

Only needed in a VMware guest. Installs the session launcher, the login
entries (including the safe-test one), the apt hook, and swaybg.

```bash
cd vmware && ./update-system.sh
```

### `./theme.sh` — the Dracula theme and desktop settings

Both installers call this, so you do not normally run it yourself. It exists
as its own script because there are two of them — `install.sh` and the
self-contained `vmware/install-vmware.sh` — and inlining it would mean
writing it twice.

```bash
./theme.sh                # fetch the theme, wire GTK, apply the settings
./theme.sh --status       # report what is present and what is set
./theme.sh --no-apply     # fetch the theme files, change no settings
```

**It needs no root** — the theme lands in `~/.themes` and `~/.icons` and every
setting is per-user — so it is safe to re-run from inside a live session.
Anything already in place is skipped, and a failed download warns rather than
aborting: an unthemed desktop must not take an install down with it.

See [GTK theme — Dracula](#gtk-theme--dracula) for what it installs and the
two upstream quirks it works around.

---

### `./sync.sh` — capture live changes back into the repo

`install.sh` copies repo → `~/.config`. This goes the other way, so a tweak
you make directly in `~/.config` does not live only on that machine.

```bash
./sync.sh                 # capture → commit → push
./sync.sh --status        # just show what differs
./sync.sh --dry-run
./sync.sh --no-push
./sync.sh -m "message"
```

It only touches the files in its manifest, so nothing unrelated wanders in.

---

## 2. First run — do not lose your session

To test without logging out of your current desktop at all, start the session
from a free VT:

```
CTRL+ALT+F3        log in there
/usr/local/bin/start-hyprland-vmware
CTRL+ALT+F7        back to where you were
```

`CTRL+ALT+F3` normally gives you a console even from inside Hyprland — it is
handled internally through logind. The one case it does *not* cover is
libinput failing to bind a keyboard at all, since then no keystroke reaches
Hyprland; that leaves powering the VM off.

If input dies, `~/hyprland-diag.txt` states the verdict in plain words within
~12 seconds, and `~/hyprland-last.log` survives a hard power-off.

---

## 3. Keybindings

`SUPER` is the Windows key. These mirror i3-kitty's `i3/config` one for one.

### Rescue — deliberately not on SUPER

If the host grabs the Super key, or a bind fails to register, these still work.

| Key | Action |
|---|---|
| `CTRL + ALT + T` | Terminal |
| `ALT + Enter` | Terminal |
| `CTRL + ALT + Backspace` | Exit Hyprland cleanly |
| `CTRL + ALT + F3` | Text console (handled by logind, needs no bind) |

### Launching

| Key | Action |
|---|---|
| `SUPER + Enter` | Terminal (kitty) |
| `SUPER + D` | App launcher (fuzzel) |
| `SUPER + SHIFT + Enter` | File manager (nemo) |
| `SUPER + SHIFT + F` | Firefox (via the session-aware wrapper) |
| `SUPER + SHIFT + Q` | Close window |

### Focus and movement — `j / k / i / o`

Not the `j/k/l/;` row: i3-kitty puts *up* and *right* on `i` and `o`, and
kitty's own `ctrl+j/k/i/o` window navigation matches.

| Key | Action |
|---|---|
| `SUPER + J / K / I / O` | Focus left / down / up / right |
| `SUPER + ← ↓ ↑ →` | Focus, arrow keys |
| `SUPER + SHIFT + J/K/I/O` | Move window |
| `SUPER + SHIFT + ← ↓ ↑ →` | Move window, arrow keys |
| `SUPER + A` | Focus the last window (i3's `focus parent` has no equivalent) |

### Layout

| Key | Action |
|---|---|
| `SUPER + H` | Split horizontal — next window opens to the right |
| `SUPER + V` | Split vertical — next window opens below |
| `SUPER + E` | Toggle split |
| `SUPER + S` / `SUPER + W` | Group — Hyprland's one primitive for i3's stacking *and* tabbed |
| `SUPER + Tab` / `SUPER + SHIFT + Tab` | Next / previous in the group |
| `SUPER + F` | Fullscreen |
| `SUPER + P` | Pseudo-tile |
| `SUPER + SHIFT + ,` | Centre window |

### Floating — the two are easy to confuse

| Key | Action |
|---|---|
| `SUPER + SHIFT + Espacio` | **Float / unfloat** the window, then size it to 55% × 40% of the screen and centre it |
| `SUPER + Espacio` | **Only moves focus** between the tiled windows and the floating ones (i3's `focus mode_toggle`) — changes no window |

### Workspaces

| Key | Action |
|---|---|
| `SUPER + 1…0` | Switch workspace |
| `SUPER + SHIFT + 1…0` | Move window to workspace |
| `SUPER + Rueda ↑ / ↓` | Previous / next workspace |
| `SUPER + N` | Rename the workspace (prompt) |
| `SUPER + B` | Clear the name, back to its number |

### Resizing

| Key | Action |
|---|---|
| `SUPER + CTRL + J/I/K/O` | Resize by 1 px |
| `SUPER + CTRL + ← ↑ ↓ →` | Resize by 1 px |
| `SUPER + CTRL + SHIFT + J/I/K/O` | Resize by 20 px |
| `SUPER + CTRL + SHIFT + ← ↑ ↓ →` | Resize by 20 px |
| `SUPER + R` | Enter resize mode — then `j/i/k/o` or arrows, `Esc`/`Enter` to leave |
| `SUPER + Clic izq` (drag) | Move window |
| `SUPER + Clic der` (drag) | Resize window |

### Session, clipboard, screenshots

| Key | Action |
|---|---|
| `SUPER + C` | Clipboard history (cliphist + fuzzel) |
| `SUPER + SHIFT + C` | Reload the config |
| `SUPER + SHIFT + R` | Reload the config (i3's "restart") |
| `SUPER + SHIFT + E` | Exit, with a confirmation prompt |
| `SUPER + SHIFT + P` | Screenshot a region → clipboard **and** `~/Pictures` |
| `ImprPant` | Whole screen → clipboard |
| `XF86Audio*` | Volume / mute via `wpctl` |

### kitty

Only **one** binding is added to kitty — `super+shift+t` — precisely so
nothing of kitty's own is shadowed. Everything else below is kitty's default.

| Key | Action |
|---|---|
| `SUPER + SHIFT + T` | New tab |
| `CTRL + SHIFT + T` | New tab (kitty default) |
| `CTRL + SHIFT + ALT + T` | **Rename the tab** (kitty default) |
| `CTRL + SHIFT + 1…9` | Jump to tab N |
| `CTRL + SHIFT + O` / `CTRL + SHIFT + J` | Next / previous tab |
| `CTRL + J / K / I / O` | Move between kitty splits |
| `CTRL + SHIFT + N` | Browse scrollback in nvim |
| `CTRL + SHIFT + Z` | Toggle stack layout |
| `F1`…`F4` | Copy/paste buffers a and b |

> `SUPER + SHIFT + R` cannot be used for renaming tabs: Hyprland binds it to
> reload, and the compositor sees every key first. That is why renaming lives
> on kitty's default `CTRL+SHIFT+ALT+T`.

---

## 4. The bar

Waybar, with i3-kitty's i3blocks modules ported one for one — same order,
same glyphs, same colours.

| Module | Source | Reads |
|---|---|---|
| VPN | `vpn_status.sh` | `tun0`, then `tap0` |
| Ethernet | `ethernet_status.sh` | `/usr/share/i3blocks/iface`, else the default route |
| Gateway | `access_point.sh` | default route |
| Domain | `domain.sh` | `~/.config/bin/domain.txt` |
| Target OS | `target_sys.sh` | `~/.config/bin/ttl.txt` + `target_sys.txt` |
| Target | `target.sh` | `~/.config/bin/target.txt` |
| Session | `session.sh` | `~/.config/bin/session.txt` (epoch) |
| CPU / RAM / Disk / Clock | i3blocks built-ins | — |

Set them from a shell:

```bash
echo 10.10.11.5   > ~/.config/bin/target.txt
echo lab.local    > ~/.config/bin/domain.txt
echo windows      > ~/.config/bin/ttl.txt
date +%s          > ~/.config/bin/session.txt   # starts the session clock
```

---

## 5. Look and feel

| | |
|---|---|
| Borders | 1 px, lime `#00FF00` focused, `#333333` otherwise |
| Corners | 10 px rounded |
| Gaps | 4 px between windows, 10 px against the screen edge |
| Blur | behind kitty, the bar and notifications — **not** the launcher |
| Animations | window open/close/move, 200 ms workspace slide, 100 ms focus border |
| Terminal | black at 0.55 opacity, with `background_blur` |

### GTK theme — Dracula

Neither the theme nor its icon set is packaged for Debian or Kali, so
`./theme.sh` fetches both from upstream into directories that need no root:

| | Where | From |
|---|---|---|
| GTK 2/3/4 theme | `~/.themes/Dracula` | `dracula/gtk` release `v4.0.0` |
| Icons | `~/.icons/Dracula` | `m4thewz/dracula-icons` |
| Cursors | `~/.icons/Dracula-cursors` | `dracula/gtk` release |

Two things `theme.sh` has to fix up, both invisible until they bite:

- **The icon theme's fallback chain is wrong for this box.** Upstream inherits
  from `breeze-dark, Zafiro, Mint-X, elementary` and none of them are
  installed here, so any icon Dracula lacks falls through to `hicolor` and
  renders as a blank sheet of paper. It rewrites `Inherits=` to put
  `Papirus-Dark` — which `install.sh` already pulls in — at the front.
- **GTK4 ignores `~/.themes` entirely.** GTK3 reads the theme name out of
  `.config/gtk-3.0/settings.ini`, but a GTK4 app has to be handed the CSS, so
  it symlinks `gtk.css`, `gtk-dark.css` and `assets` into
  `~/.config/gtk-4.0/`.

Nemo logs `Current gtk theme is not known to have nemo support (Dracula)` on
every start. That is not a failure: Dracula ships no Nemo-specific CSS, so
Nemo layers its own `nemo-style-fallback.css` on top, which is the normal path
for any third-party theme and looks right.

Swap the whole thing out from `gtk-theme-name` / `gtk-icon-theme-name` in
`.config/gtk-3.0/settings.ini`, plus `XCURSOR_THEME` in `hyprland.lua`.

### File manager — Nemo

Thunar was Kali's default and this repo's original choice; Nemo replaces it
for one reason, and it is worth being precise about where that feature lives.
**Nemo does not implement SFTP, FTP or SMB — GVfs does.** "File → Connect to
Server" is a front end to it, so the backends are a hard dependency:

```
nemo nemo-fileroller gvfs-backends gvfs-fuse
```

`gvfs-backends` supplies `gvfsd-sftp`, `-ftp`, `-smb`, `-dav`, `-nfs` and
`-mtp`. `gvfs-fuse` is the part worth understanding: without it a remote share
is reachable only by GVfs-aware applications, so Nemo could browse it while
kitty, vim and every script could not. With it, `gvfsd-fuse` mounts everything
under `/run/user/$UID/gvfs/`, as a real path any program can open.

Two settings `theme.sh` applies, neither of which is a default:

- `org.nemo.desktop show-desktop-icons false` — Nemo would otherwise try to
  draw the desktop, which under a Wayland compositor is not its job.
- `org.cinnamon.desktop.default-applications.terminal exec` → `kitty`. Nemo
  ships pointing "Open in Terminal" at `gnome-terminal`, which is not
  installed here, so the entry silently did nothing.

### Effects profiles

Set `HYPR_EFFECTS` on the session entry or the command line:

| | Blur | Shadows | Window anims | Workspace anims |
|---|---|---|---|---|
| `soft` *(default)* | 1 pass, r=5 | no | yes | yes (200 ms) |
| `full` | 2 passes, r=8 | yes | yes | yes (400 ms) |
| `lite` | no | no | no | no |

`soft` is tuned for software rendering: this VM has no 3D acceleration, so
Hyprland renders through llvmpipe on the CPU. Do **not** enable "Accelerate
3D graphics" in the VM settings to chase performance — on many hosts the VM
then refuses to boot, and this config does not need it.

### Things you are most likely to change

| What | Where |
|---|---|
| Focus colour | `local focus` in `.config/hypr/hyprland.lua` |
| Border thickness | `general.border_size` |
| Gaps | `general.gaps_in` / `gaps_out` |
| Floating window size | `FLOAT_W` / `FLOAT_H`, above the `SUPER+SHIFT+space` bind |
| Launcher size | `width` (in **characters**) and `lines` in `.config/fuzzel/fuzzel.ini` |
| Terminal transparency | `background_opacity` in `.config/kitty/kitty.conf` |
| Wallpaper | `~/.fehbg` (i3) or `WALLPAPER=/path/to.jpg` (Hyprland) |
| Keyboard layout | `kb_layout` — the only machine-specific line in the config |

Reload with `SUPER + SHIFT + C`.

---

## 6. Troubleshooting

**The desktop is slow.** Log out and pick "Hyprland (lite)". To see where the
time goes, start a session with `HYPR_OVERLAY=1` for the frame-timing
overlay, change one value, and reload.

**Mouse works, keyboard dead.** The original bug this repo was built around:
libinput enumerates `/dev/input` once, at startup, and drops anything it
cannot open at that instant — and logind refuses device fds to a session that
is not yet Active. The launcher waits for `Active=yes` before starting
Hyprland, which closes the race. `~/hyprland-diag.txt` says which happened.

**Bar icons are empty boxes.** Hack Nerd Font is missing —
`fc-list | grep -i "hack nerd"` should not be empty. Re-run `./install.sh`.

**Firefox opens on the other screen.** Firefox is single-instance per profile
and finds the running copy over D-Bus, and Kali's `dbus-user-session` gives
one bus per *user*, not per login session. So while an X11 session is also
logged in, a launch here just makes a window appear over there.
`scripts/firefox.sh` detects that and starts an independent instance on its
own profile. With Hyprland as the only session it never happens.

**Picking Hyprland at the greeter returns you to the greeter.** The
`hyprland-uwsm.desktop` entry the package ships cannot work — uwsm is not
packaged in Kali. `vmware/update-system.sh` removes it.

**Pywal.** Kali marks its Python externally-managed (PEP 668), so
`pip3 install pywal` fails. Use `pipx install pywal`. The command is `wal`.

---

## 7. Layout

```
install.sh                 desktop installer
tools.sh                   tooling installer (config.sh, reworked)
sync.sh                    capture ~/.config back into the repo
.config/
├── hypr/
│   ├── hyprland.lua       the config (Hyprland 0.51+)
│   └── scripts/           wallpaper, screenshot, launcher, dmenu, clipboard,
│                          exit, firefox, workspace-rename/clear, polkit
├── waybar/                bar + the seven pentest scripts
├── fuzzel/  wofi/  dunst/ launcher and notifications
├── kitty/   fish/  nvim/  terminal, shell, editor
├── i3/  compton/  rofi/   the X11 session
└── …
legacy/hyprland.conf       same setup in the pre-0.51 .conf format
vmware/                    session launcher, login entries, apt hook
usr/share/i3blocks/        the pentest blocks, for the i3 session
```

**Which config file does Hyprland read?** 0.51+ reads `hyprland.lua`. 0.56
still loads a `hyprland.conf` but warns that support goes away in 0.57, so
only the `.lua` is deployed; `legacy/` is for older installs. Never keep both
in `~/.config/hypr`.

---

## Credits

Wallpaper: John Martin, *Le Pandemonium* (Louvre).
Original i3 setup: [i3-kitty](https://github.com/KermitPurple96/i3-kitty),
which in turn started from [kali-clean](https://github.com/KermitPurple96/kali-clean).
