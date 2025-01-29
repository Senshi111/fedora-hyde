#!/bin/bash

# Ensure the script is run as root or with sudo
if [[ $EUID -ne 0 ]]; then
   echo "Please run as root or with sudo."
   exit 1
fi
 sudo dnf install -y \
             https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
 sudo dnf install -y \
             https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

 sudo dnf copr enable solopasha/hyprland -y
 # Define the repository configuration content
REPO_CONTENT="[copr:copr.fedorainfracloud.org:errornointernet:packages]
name=Copr repo for packages owned by errornointernet
baseurl=https://download.copr.fedorainfracloud.org/results/errornointernet/packages/fedora-\$releasever-\$basearch/
type=rpm-md
skip_if_unavailable=True
gpgcheck=1
gpgkey=https://download.copr.fedorainfracloud.org/results/errornointernet/packages/pubkey.gpg
repo_gpgcheck=0
enabled=1
enabled_metadata=1
exclude=kernel*"

# Define the target file path
REPO_FILE="/etc/yum.repos.d/errornointernet.repo"

# Check if the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root or with sudo."
    exit 1
fi

# Create the repository file
echo "$REPO_CONTENT" > "$REPO_FILE"

# Set appropriate permissions
chmod 644 "$REPO_FILE"

echo "Repository configuration added successfully."

# Define the repository content for nobara-testing with exclude=kernel*
REPO_CONTENT="[copr:copr.fedorainfracloud.org:lionheartp:nobara-testing]
name=Copr repo for nobara-testing owned by lionheartp
baseurl=https://download.copr.fedorainfracloud.org/results/lionheartp/nobara-testing/fedora-\$releasever-\$basearch/
type=rpm-md
skip_if_unavailable=True
gpgcheck=1
gpgkey=https://download.copr.fedorainfracloud.org/results/lionheartp/nobara-testing/pubkey.gpg
repo_gpgcheck=0
enabled=1
enabled_metadata=1
exclude=kernel*

[copr:copr.fedorainfracloud.org:lionheartp:nobara-testing:ml]
name=Copr repo for nobara-testing owned by lionheartp (i386)
baseurl=https://download.copr.fedorainfracloud.org/results/lionheartp/nobara-testing/fedora-\$releasever-i386/
type=rpm-md
skip_if_unavailable=True
gpgcheck=1
gpgkey=https://download.copr.fedorainfracloud.org/results/lionheartp/nobara-testing/pubkey.gpg
repo_gpgcheck=0
cost=1100
enabled=1
enabled_metadata=1
exclude=kernel*"

# Define the target file path
REPO_FILE="/etc/yum.repos.d/lionheartp-nobara-testing.repo"

# Check if the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root or with sudo."
    exit 1
fi

# Create the repository file
echo "$REPO_CONTENT" > "$REPO_FILE"

# Set appropriate permissions
chmod 644 "$REPO_FILE"

echo "Repository configuration for nobara-testing with kernel exclusion added successfully."

# Update package list
echo "Updating package list..."
dnf update -y || { echo "Failed to update package list. Exiting."; exit 1; }

# List of packages to install
packages=(
    ark
    alsa-firmware
    pipewire
    wireplumber
    network-manager-applet
    brightnessctl
    qt6-qtwayland
    dunst
    rofi-wayland
    swayidle
    wlogout
    grim
    slurp
    polkit-kde
    xdg-desktop-portal-gtk
    ImageMagick
    pavucontrol
    qt6-qtbase-devel
    ffmpegthumbs
    qt5-qtimageformats
    qt6-qtbase
    kvantum
    qt5ct
    qt6ct
    waybar
    parallel
    dolphin
    sddm
    firefox
    kde-cli-tools
    fastfetch
    wl-clipboard
    go
    xdg-utils
    swappy
    alsa-sof-firmware
    google-noto-emoji-fonts
    google-noto-emoji-color-fonts
    pamixer
    bluez
    bluez-tools
    blueman
    python3-cairo
    NetworkManager-wifi
    iwl*
    lm_sensors
    cava
    polkit-qt6-1
    lsd
    pipx
    hyprland
    hypridle
    hyprlock
    google-noto-fonts-all
    satty
    scdoc
    nwg-look
    mangohud
    swaylock-effects
    swww
)

# Remove duplicates
unique_packages=($(echo "${packages[@]}" | tr ' ' '\n' | sort -u))

# Install packages
echo "Installing packages..."
for pkg in "${unique_packages[@]}"; do
    if ! dnf install -y "$pkg"; then
        echo -e "\033[0;31m[error]\033[0m Failed to install $pkg. Skipping..."
    else
        echo -e "\033[0;32m[success]\033[0m Successfully installed $pkg."
    fi
done

# Install Visual Studio Code
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
sudo dnf install -y code
sudo pipx install --global hyprshade
pipx ensurepath
echo "Installation complete!"

