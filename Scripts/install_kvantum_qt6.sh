#!/bin/bash

# Exit script on any error
set -e

echo "Updating package list and installing dependencies..."
# Use dnf to install dependencies for Fedora
sudo dnf update -y
sudo dnf install -y \
    git cmake g++ qt6-qtbase-devel qt6-qttools-devel \
    qt6-qtsvg-devel kf6-kwindowsystem-devel \
    libX11-devel libXext-devel

echo "Cloning Kvantum repository..."
# Clone the Kvantum repository
git clone --depth=1 https://github.com/tsujan/Kvantum.git kvantum
cd kvantum/Kvantum

echo "Building Kvantum with Qt6 support..."
# Create a build directory and navigate into it
mkdir build && cd build

# Run cmake with Qt6 support and build Kvantum
cmake .. -DENABLE_QT6=ON
make -j$(nproc)

echo "Installing Kvantum..."
sudo make install

echo "Cleaning up..."
# Clean up
cd ../../..
rm -rf kvantum

echo "Installation completed. You can configure Kvantum using kvantummanager."
