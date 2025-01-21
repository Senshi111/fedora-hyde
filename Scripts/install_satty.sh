#!/bin/bash

set -e  # Exit on error
set -o pipefail  # Catch pipeline errors

REPO_URL="https://github.com/gabm/Satty.git"
INSTALL_DIR="Satty"

echo "Updating package lists and installing dependencies..."

# Fedora uses dnf instead of apt
sudo dnf update -y

# Install dependencies with dnf
sudo dnf install -y \
    git cargo \
    gtk4-devel libadwaita-devel \
    mesa-libEGL-devel mesa-libGLES-devel \
    wayland-devel xkbcommon-devel \
    libepoxy-devel

# Clone and build Satty
echo "Cloning Satty repository..."
git clone --depth=1 "$REPO_URL" "$INSTALL_DIR"

cd "$INSTALL_DIR"

echo "Building Satty with Cargo..."
cargo build --release

echo "Installing Satty..."
sudo install -Dm755 target/release/satty /usr/local/bin/satty

# Cleanup
echo "Cleaning up temporary files..."
cd ~
rm -rf "$INSTALL_DIR"

echo "Installation complete! Run 'satty' to test."

