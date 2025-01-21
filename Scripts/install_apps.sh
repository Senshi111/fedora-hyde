#!/bin/bash

# Function to install packages
install_packages() {
    sudo dnf install -y "$@"
}

# Add repositories and update the system here if needed

# Install required packages
install_packages \
    pipewire \
    wireplumber \
    network-manager-applet \
    brightnessctl \
    qt6-qtwayland \
    dunst \
    rofi-wayland \
    swayidle \
    wlogout \
    grim \
    slurp \
    polkit-kde \
    xdg-desktop-portal-gtk \
    ImageMagick \
    pavucontrol \
    qt6-qtbase-devel \
    ffmpegthumbs \
    qt5-qtimageformats \
    qt6-qtbase \
    kvantum \
    qt5ct \
    qt6ct \
    waybar \
    parallel \
    dolphin \
    sddm \
    firefox \
    kde-cli-tools \
    fastfetch \
    wl-clipboard \
    go \
    xdg-utils \
    swappy \
    alsa-sof-firmware \
    google-noto-emoji-fonts \
    google-noto-emoji-color-fonts \
    pamixer \
    bluez \
    bluez-tools \
    blueman \
    python3-cairo \
    NetworkManager-wifi \
    iwl* \
    lm_sensors \
    cava \
    polkit-qt6-1 \
    lsd \
    neofetch \
    pipx

# Install dependencies for wlroots
export PATH=$PATH:/usr/local/go/bin

# Enable COPR repository for additional packages
#sudo dnf copr enable -y alebastr/sway-extras

# Install the additional package
#sudo dnf install -y swww

# sudo dnf install -y \
#             https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
# sudo dnf install -y \
#             https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm


# Install Google Chrome
# sudo dnf install -y fedora-workstation-repositories
# sudo dnf config-manager --set-enabled google-chrome
# sudo dnf install -y google-chrome-stable

# Install Visual Studio Code
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
sudo dnf install -y code
sudo pipx install --global hyprshade
