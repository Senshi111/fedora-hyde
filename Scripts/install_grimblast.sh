#!/bin/bash

set -e  # Exit on error
set -o pipefail  # Catch pipeline errors

REPO_URL="https://github.com/hyprwm/contrib.git"
INSTALL_DIR="$HOME/grimblast_install"

echo "Updating package lists and installing dependencies..."
# Use dnf to install dependencies for Fedora
sudo dnf update -y
sudo dnf install -y grim slurp wl-clipboard gcc make git

# Clone and build Grimblast
echo "Cloning Grimblast repository..."
git clone --depth=1 "$REPO_URL" "$INSTALL_DIR"

cd "$INSTALL_DIR/grimblast"

echo "Compiling Grimblast..."
make

echo "Installing Grimblast..."
sudo make install

# Cleanup
echo "Cleaning up temporary files..."
cd ~
rm -rf "$INSTALL_DIR"

echo "Installation complete! Run 'grimblast' to test."
