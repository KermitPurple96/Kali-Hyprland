#!/bin/bash

# Kali Hyprland Configuration Installer
# Author: KermitPurple96

set -e

echo "╦ ╦╦ ╦╔═╗╦═╗╦  ╔═╗╔╗╔╔╦╗"
echo "╠═╣╚╦╝╠═╝╠╦╝║  ╠═╣║║║ ║║"
echo "╩ ╩ ╩ ╩  ╩╚═╩═╝╩ ╩╝╚╝═╩╝"
echo ""
echo "Kali Hyprland Configuration Installer"
echo "======================================"
echo ""

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo "⚠️  Please do not run this script as root!"
    echo "Run it as your regular user. It will ask for sudo when needed."
    exit 1
fi

# Install dependencies
echo "📦 Installing Hyprland and dependencies..."
sudo apt update
sudo apt install -y \
    hyprland \
    waybar \
    wofi \
    dunst \
    grim \
    slurp \
    wl-clipboard \
    swaylock \
    swayidle \
    xdg-desktop-portal-hyprland \
    kitty \
    thunar

echo ""
echo "📁 Creating configuration directories..."
mkdir -p ~/.config/hypr
mkdir -p ~/.config/waybar
mkdir -p ~/.config/wofi
mkdir -p ~/.config/kitty

echo ""
echo "📝 Copying configuration files..."

# Backup existing configs
if [ -d ~/.config/hypr ]; then
    echo "⚠️  Backing up existing Hyprland config..."
    mv ~/.config/hypr ~/.config/hypr.backup.$(date +%Y%m%d_%H%M%S)
fi

if [ -d ~/.config/waybar ]; then
    echo "⚠️  Backing up existing Waybar config..."
    mv ~/.config/waybar ~/.config/waybar.backup.$(date +%Y%m%d_%H%M%S)
fi

if [ -d ~/.config/wofi ]; then
    echo "⚠️  Backing up existing Wofi config..."
    mv ~/.config/wofi ~/.config/wofi.backup.$(date +%Y%m%d_%H%M%S)
fi

# Copy new configs
cp -r .config/hypr ~/.config/
cp -r .config/waybar ~/.config/
cp -r .config/wofi ~/.config/

echo ""
echo "✅ Installation complete!"
echo ""
echo "To start Hyprland:"
echo "  1. Log out of your current session"
echo "  2. Select 'Hyprland' from your display manager"
echo "  3. Or run: Hyprland"
echo ""
echo "Keybindings:"
echo "  Super + Enter       - Terminal"
echo "  Super + D           - App launcher"
echo "  Super + Shift + Q   - Close window"
echo "  Super + Shift + E   - Exit Hyprland"
echo ""
echo "For more info, see README.md"
