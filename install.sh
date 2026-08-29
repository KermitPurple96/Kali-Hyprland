#!/bin/bash

# Kali Hyprland Complete Configuration Installer
# Author: KermitPurple96
# Repository: https://github.com/KermitPurple96/Kali-Hyprland

set -e

echo "╦ ╦╦ ╦╔═╗╦═╗╦  ╔═╗╔╗╔╔╦╗"
echo "╠═╣╚╦╝╠═╝╠╦╝║  ╠═╣║║║ ║║"
echo "╩ ╩ ╩ ╩  ╩╚═╩═╝╩ ╩╝╚╝═╩╝"
echo ""
echo "Kali Hyprland Complete Configuration Installer"
echo "==============================================="
echo ""

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo "️  Please do not run this script as root!"
    echo "Run it as your regular user. It will ask for sudo when needed."
    exit 1
fi

# Ask user which setup they want
echo "Which setup would you like to install?"
echo "1) Hyprland (Wayland) - Modern, smooth, recommended"
echo "2) i3-gaps (X11) - Classic setup from kali-clean"
echo "3) Both (you can choose at login)"
echo ""
read -p "Enter your choice (1/2/3): " choice

case $choice in
    1)
        INSTALL_HYPRLAND=true
        INSTALL_I3=false
        ;;
    2)
        INSTALL_HYPRLAND=false
        INSTALL_I3=true
        ;;
    3)
        INSTALL_HYPRLAND=true
        INSTALL_I3=true
        ;;
    *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
esac

echo ""
echo " Updating system..."
sudo apt update && sudo apt upgrade -y

# Common packages
echo ""
echo " Installing common packages..."
sudo apt install -y \
    flameshot \
    feh \
    lxappearance \
    python3-pip \
    unclutter \
    papirus-icon-theme \
    imagemagick \
    thunar \
    kitty

# Fonts
echo ""
echo " Installing Nerd Fonts..."
mkdir -p ~/.local/share/fonts/

if [ ! -f ~/.local/share/fonts/Iosevka ]; then
    echo "Downloading Iosevka Nerd Font..."
    wget -q https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/Iosevka.zip
    unzip -q Iosevka.zip -d ~/.local/share/fonts/
    rm Iosevka.zip
fi

if [ ! -f ~/.local/share/fonts/RobotoMono ]; then
    echo "Downloading RobotoMono Nerd Font..."
    wget -q https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/RobotoMono.zip
    unzip -q RobotoMono.zip -d ~/.local/share/fonts/
    rm RobotoMono.zip
fi

fc-cache -fv

# Install i3-gaps setup
if [ "$INSTALL_I3" = true ]; then
    echo ""
    echo " Installing i3-gaps and related packages..."
    sudo apt install -y \
        arandr \
        arc-theme \
        i3blocks \
        i3status \
        i3 \
        i3-wm \
        rofi \
        cargo \
        compton \
        libxcb-shape0-dev \
        libxcb-keysyms1-dev \
        libpango1.0-dev \
        libxcb-util0-dev \
        libxcb1-dev \
        libxcb-icccm4-dev \
        libyajl-dev \
        libev-dev \
        libxcb-xkb-dev \
        libxcb-cursor-dev \
        libxkbcommon-dev \
        libxcb-xinerama0-dev \
        libxkbcommon-x11-dev \
        libstartup-notification0-dev \
        libxcb-randr0-dev \
        libxcb-xrm0 \
        libxcb-xrm-dev \
        autoconf \
        meson \
        libxcb-render-util0-dev \
        libxcb-shape0-dev \
        libxcb-xfixes0-dev

    # Install Alacritty
    echo " Installing Alacritty..."
    if ! command -v alacritty &> /dev/null; then
        wget -q https://github.com/barnumbirr/alacritty-debian/releases/download/v0.10.0-rc4-1/alacritty_0.10.0-rc4-1_amd64_bullseye.deb
        sudo dpkg -i alacritty_0.10.0-rc4-1_amd64_bullseye.deb || sudo apt install -f -y
        rm alacritty_0.10.0-rc4-1_amd64_bullseye.deb
    fi

    # Install pywal
    echo " Installing pywal..."
    pip3 install pywal

    echo ""
    echo " Creating i3 configuration directories..."
    mkdir -p ~/.config/i3
    mkdir -p ~/.config/compton
    mkdir -p ~/.config/rofi
    mkdir -p ~/.config/alacritty

    echo " Copying i3 configuration files..."

    # Backup existing configs
    for dir in i3 compton rofi alacritty; do
        if [ -d ~/.config/$dir ] && [ "$(ls -A ~/.config/$dir)" ]; then
            echo "️  Backing up existing $dir config..."
            mv ~/.config/$dir ~/.config/$dir.backup.$(date +%Y%m%d_%H%M%S)
        fi
    done

    cp -r .config/i3/* ~/.config/i3/
    cp -r .config/compton/* ~/.config/compton/
    cp -r .config/rofi/* ~/.config/rofi/
    cp -r .config/alacritty/* ~/.config/alacritty/
    cp .fehbg ~/.fehbg
    cp -r .wallpaper ~/.wallpaper

    chmod +x ~/.config/i3/clipboard_fix.sh
    chmod +x ~/.fehbg
fi

# Install Hyprland setup
if [ "$INSTALL_HYPRLAND" = true ]; then
    echo ""
    echo " Installing Hyprland and related packages..."
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
        xdg-desktop-portal-hyprland

    echo ""
    echo " Creating Hyprland configuration directories..."
    mkdir -p ~/.config/hypr
    mkdir -p ~/.config/waybar
    mkdir -p ~/.config/wofi

    echo " Copying Hyprland configuration files..."

    # Backup existing configs
    for dir in hypr waybar wofi; do
        if [ -d ~/.config/$dir ] && [ "$(ls -A ~/.config/$dir)" ]; then
            echo "️  Backing up existing $dir config..."
            mv ~/.config/$dir ~/.config/$dir.backup.$(date +%Y%m%d_%H%M%S)
        fi
    done

    cp -r .config/hypr/* ~/.config/hypr/
    cp -r .config/waybar/* ~/.config/waybar/
    cp -r .config/wofi/* ~/.config/wofi/
fi

# Install Kitty config
echo ""
echo " Copying Kitty configuration..."
mkdir -p ~/.config/kitty
if [ -f ~/.config/kitty/kitty.conf ]; then
    echo "️  Backing up existing Kitty config..."
    mv ~/.config/kitty/kitty.conf ~/.config/kitty/kitty.conf.backup.$(date +%Y%m%d_%H%M%S)
fi
cp -r .config/kitty/* ~/.config/kitty/

# Install Oh My Zsh (optional)
read -p "Would you like to install Oh My Zsh? (y/n): " install_zsh
if [[ $install_zsh == "y" || $install_zsh == "Y" ]]; then
    echo ""
    echo " Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

echo ""
echo " Installation complete!"
echo ""

if [ "$INSTALL_I3" = true ] && [ "$INSTALL_HYPRLAND" = true ]; then
    echo "Both i3 and Hyprland have been installed!"
    echo ""
    echo "To use i3:"
    echo "  - Log out and select 'i3' from your display manager"
    echo "  - Run: pywal -i ~/.wallpaper/yourimage.jpg (to set colors)"
    echo "  - Run: lxappearance (and select arc-dark theme)"
    echo ""
    echo "To use Hyprland:"
    echo "  - Log out and select 'Hyprland' from your display manager"
    echo "  - Or run: Hyprland"
elif [ "$INSTALL_HYPRLAND" = true ]; then
    echo "Hyprland has been installed!"
    echo ""
    echo "To start Hyprland:"
    echo "  1. Log out of your current session"
    echo "  2. Select 'Hyprland' from your display manager"
    echo "  3. Or run: Hyprland"
    echo ""
    echo "Keybindings (Super = Windows key):"
    echo "  Super + Enter       - Terminal"
    echo "  Super + D           - App launcher"
    echo "  Super + Shift + Q   - Close window"
    echo "  Super + Shift + E   - Exit Hyprland"
elif [ "$INSTALL_I3" = true ]; then
    echo "i3-gaps has been installed!"
    echo ""
    echo "To start i3:"
    echo "  1. Log out of your current session"
    echo "  2. Select 'i3' from your display manager"
    echo ""
    echo "Post-install steps:"
    echo "  - Run: pywal -i ~/.wallpaper/yourimage.jpg (to set colors)"
    echo "  - Run: lxappearance (and select arc-dark theme)"
fi

echo ""
echo "For more info, see README.md"
echo ""
echo "Enjoy your new setup! "
