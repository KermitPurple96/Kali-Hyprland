# Kali Hyprland Configuration

A modern, beautiful Hyprland setup for Kali Linux with rounded corners, blur effects, smooth animations, and an elegant green theme.

![Preview](field1.jpg)

## Features

- 🎨 **Rounded Corners** (12px radius)
- 💫 **Blur Background** for transparent windows (optimized for performance)
- ✨ **Smooth Animations** - Overshot bezier curves for satisfying window movements
- 🌿 **Green Theme** - Matching Kali Linux aesthetic (#43a047)
- ⚡ **Performance Optimized** - Hardware-accelerated with Wayland
- 🎯 **i3-like Keybindings** - Easy transition from i3wm

## What's Included

- **Hyprland** - Dynamic tiling Wayland compositor with built-in effects
- **Waybar** - Customizable status bar (replaces i3bar)
- **Wofi** - Application launcher (replaces rofi)
- **Kitty** - Terminal with transparency support
- **Dunst** - Notification daemon

## Installation

### Quick Install

```bash
# Install all dependencies
sudo apt install -y hyprland waybar wofi dunst grim slurp wl-clipboard swaylock swayidle xdg-desktop-portal-hyprland kitty

# Copy configuration files
cp -r .config/* ~/.config/

# Make sure kitty config exists
mkdir -p ~/.config/kitty
```

### Manual Installation

1. Install Hyprland and dependencies:
```bash
sudo apt update
sudo apt install -y hyprland waybar wofi dunst grim slurp wl-clipboard swaylock swayidle xdg-desktop-portal-hyprland
```

2. Copy configuration files:
```bash
cp -r .config/hypr ~/.config/
cp -r .config/waybar ~/.config/
cp -r .config/wofi ~/.config/
```

3. Start Hyprland:
```bash
Hyprland
```

## Keybindings

All keybindings use `Super` (Windows key) as the modifier.

### Essential
- `Super + Enter` - Open terminal (Kitty)
- `Super + D` - Application launcher (Wofi)
- `Super + Shift + Q` - Close window
- `Super + Shift + E` - Exit Hyprland
- `Super + F` - Fullscreen
- `Super + V` - Toggle floating

### Window Navigation (i3-style)
- `Super + J/K/I/O` - Move focus (left/down/up/right)
- `Super + Shift + J/K/I/O` - Move window
- `Super + Arrow Keys` - Alternative navigation

### Workspaces
- `Super + 1-9` - Switch to workspace
- `Super + Shift + 1-9` - Move window to workspace

### Resize Mode
- `Super + R` - Enter resize mode
  - `Arrow Keys` or `J/K/I/O` - Resize window
  - `Escape` or `Enter` - Exit resize mode

### Screenshots
- `Super + Shift + P` - Screenshot (select area)

### System
- `Super + Shift + R` - Reload Hyprland config

## Customization

### Change Theme Colors

Edit `~/.config/hypr/hyprland.conf`:
```conf
col.active_border = rgba(43a047ee)  # Active window border (green)
```

Edit `~/.config/waybar/style.css` to change bar colors.

### Adjust Blur Strength

Edit `~/.config/hypr/hyprland.conf`:
```conf
blur {
    size = 6        # Blur radius (higher = more blur)
    passes = 3      # Quality (higher = better but slower)
}
```

### Modify Animations

Edit `~/.config/hypr/hyprland.conf`:
```conf
animation = windows, 1, 5, overshot, slide  # 5 = speed
```

## Troubleshooting

### Hyprland won't start
- Make sure you're on a system with a compatible GPU
- Check `~/.config/hypr/hyprland.conf` for syntax errors

### Blur is laggy
- Reduce blur passes in config:
  ```conf
  passes = 2  # or 1 for minimal blur
  ```

### Waybar not showing
- Check if waybar is running: `ps aux | grep waybar`
- Restart: `killall waybar && waybar &`

## Tips

1. **First time?** The config is similar to i3, so muscle memory transfers easily
2. **Performance** - Hyprland uses GPU acceleration, so it's much smoother than i3+picom
3. **Customize** - All configs are in `~/.config/` - edit to your liking!

## Credits

- Author: KermitPurple96
- Based on Hyprland by vaxerski
- Inspired by Kali Linux default themes

## License

MIT License - Feel free to use and modify!
