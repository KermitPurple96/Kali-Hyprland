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
> Hyprland 0.56 reads **`hyprland.lua`** and ignores `hyprland.conf` outright,
> and `fix-hyprland-vmware.sh` is obsolete (it sets wlroots variables that 0.56
> does not use).

##  Two Setups in One Repository

### Hyprland (Wayland) - Recommended ⭐
Modern, smooth, GPU-accelerated compositor with built-in effects.

**Features:**
-  **Rounded Corners** (12px radius)
-  **Blur Background** - Optimized dual_kawase blur
-  **Smooth Animations** - Overshot bezier curves
-  **Kali Green Theme** (#43a047)
-  **High Performance** - Hardware-accelerated, no freezing
-  **i3-like Keybindings** - Easy transition from i3

**Components:**
- Hyprland (compositor + WM)
- Waybar (status bar)
- Wofi (app launcher)
- Kitty (terminal)
- Dunst (notifications)

### i3-gaps (X11) - Classic Setup
Traditional tiling window manager setup from the original kali-clean repo.

**Features:**
- Classic i3 tiling workflow
- Compton compositor
- Rofi launcher
- Alacritty terminal
- Pywal color schemes

**Components:**
- i3-gaps (window manager)
- i3blocks (status bar)
- Compton (compositor)
- Rofi (app launcher)
- Alacritty (terminal)

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
2. **i3-gaps only** - Classic X11 setup
3. **Both** - Install both, choose at login

##  What's Included

### Hyprland Configuration
```
.config/
├── hypr/
│   └── hyprland.conf      # Main Hyprland config (pre-0.56 only; 0.56 uses hyprland.lua)
├── waybar/
│   ├── config             # Waybar configuration
│   └── style.css          # Waybar styling
├── wofi/
│   ├── config             # Wofi launcher config
│   └── style.css          # Wofi styling
└── kitty/
    └── kitty.conf         # Terminal configuration
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

Both setups use `Super` (Windows key) as the main modifier.

### Essential (Same for Both)
- `Super + Enter` - Open terminal
- `Super + D` - Application launcher
- `Super + Shift + Q` - Close window
- `Super + Shift + E` - Exit WM/compositor
- `Super + F` - Fullscreen
- `Super + V` - Toggle floating (Hyprland) / Toggle tiling (i3)

### Window Navigation
- `Super + J/K/I/O` - Move focus (left/down/up/right)
- `Super + Shift + J/K/I/O` - Move window
- `Super + Arrow Keys` - Alternative navigation

### Workspaces
- `Super + 1-9` - Switch to workspace
- `Super + Shift + 1-9` - Move window to workspace

### Hyprland Specific
- `Super + R` - Resize mode
- `Super + Shift + P` - Screenshot (grim + slurp)
- `Super + Shift + R` - Reload config

### i3 Specific
- `Super + H` - Split horizontal
- `Super + V` - Split vertical
- `Super + S` - Stacking layout
- `Super + W` - Tabbed layout
- `Super + E` - Toggle split layout

##  Customization

### Hyprland

#### Change Colors
Edit `~/.config/hypr/hyprland.conf` (on Hyprland 0.56 edit `hyprland.lua` instead):
```conf
col.active_border = rgba(43a047ee)  # Active border (green)
col.inactive_border = rgba(333333aa) # Inactive border
```

#### Adjust Blur
```conf
blur {
    size = 6        # Blur radius (1-20)
    passes = 3      # Quality (1-4, higher = slower)
}
```

#### Modify Animations
```conf
animation = windows, 1, 5, overshot, slide
#                    ^  ^  ^         ^
#                    |  |  |         └─ Animation type
#                    |  |  └─────────── Bezier curve
#                    |  └────────────── Speed (1-10)
#                    └───────────────── Enabled (1/0)
```

### i3-gaps

#### Set Wallpaper & Colors
```bash
# Set wallpaper and generate color scheme
pywal -i ~/.wallpaper/yourimage.jpg

# Or use feh directly
feh --bg-scale ~/path/to/wallpaper.jpg
```

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
    wl-clipboard swaylock swayidle xdg-desktop-portal-hyprland kitty
```

**For i3-gaps:**
```bash
sudo apt install -y i3 i3blocks rofi compton alacritty feh \
    arandr arc-theme lxappearance python3-pip
pip3 install pywal
```

### Copy Configurations

```bash
# Copy desired configs
cp -r .config/hypr ~/.config/     # Hyprland
cp -r .config/waybar ~/.config/   # Waybar
cp -r .config/i3 ~/.config/       # i3
cp -r .config/kitty ~/.config/    # Kitty
# ... etc
```

##  Troubleshooting

### Hyprland won't start
- Ensure you have a compatible GPU (Intel, AMD, or NVIDIA with proper drivers)
- Check logs: `cat ~/.local/share/hyprland/hyprland.log`
- Verify config: `hyprland --check`

### Blur is laggy
Reduce blur quality in `~/.config/hypr/hyprland.conf`:
```conf
passes = 2  # or even 1
size = 4    # reduce from 6
```

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
```bash
pip3 install --user pywal
# Make sure ~/.local/bin is in PATH
export PATH="$HOME/.local/bin:$PATH"
```

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
- **Virtual machine → either**; for Hyprland run `vmware/install-vmware.sh` first

##  Tips

1. **First time with Hyprland?** The keybindings are similar to i3, so muscle memory transfers!
2. **Performance tip:** Hyprland uses GPU acceleration, much smoother than i3+picom
3. **Missing wallpaper?** Copy your images to `~/.wallpaper/` directory
4. **Customize!** All configs are in `~/.config/` - edit to your liking
5. **Switch between setups:** Both can be installed - just select at login screen

##  Repository Structure

```
Kali-Hyprland/
├── .config/
│   ├── hypr/           # Hyprland config
│   ├── waybar/         # Waybar config
│   ├── wofi/           # Wofi config
│   ├── i3/             # i3 config
│   ├── compton/        # Compton config
│   ├── rofi/           # Rofi config
│   ├── alacritty/      # Alacritty config
│   └── kitty/          # Kitty config
├── vmware/             # VMware guest deploy (Hyprland 0.56)
│   ├── install-vmware.sh       # Run this in a VM
│   ├── start-hyprland-vmware   # Session launcher (fixes the input race)
│   ├── hyprland.lua            # Hyprland 0.56 config (Lua, not .conf)
│   ├── hyprland.desktop        # LightDM session entry
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
