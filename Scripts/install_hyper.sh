#!/bin/bash

set -e  # Exit on error

HYPER_RPM_URL="https://releases.hyper.is/download/rpm"
TEMP_RPM="/tmp/hyper.rpm"

# Check for required dependencies
if ! command -v curl &> /dev/null; then
    echo "Error: curl is not installed. Install it using: sudo dnf install curl"
    exit 1
fi

if ! command -v rpm &> /dev/null; then
    echo "Error: rpm is not installed. It should be available by default on Fedora."
    exit 1
fi

# Download the latest Hyper .rpm package
echo "Downloading Hyper..."
curl -L "$HYPER_RPM_URL" -o "$TEMP_RPM"

# Install Hyper
echo "Installing Hyper..."
sudo dnf install -y "$TEMP_RPM"

# Check if there are missing dependencies and install them
echo "Fixing missing dependencies..."
sudo dnf install -y $(sudo dnf repoquery --requires "$TEMP_RPM" | grep -v "provides")

# Clean up
rm -f "$TEMP_RPM"

echo "Hyper installation complete! You can launch it by running: hyper"


