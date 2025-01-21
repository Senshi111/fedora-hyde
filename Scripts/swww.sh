#!/bin/bash
#|---/ /+-------------------------------------------+---/ /|#
#|--/ /-| Script to build and install swww on Fedora |--/ /-|#
#|-/ /--| Maintainer: Your Name <you@example.com>    |-/ /--|#
#|/ /---+-------------------------------------------+/ /---|#

# Exit on error
set -e

# Variables
PKGNAME="swww"
PKGVER="0.9.5"
URL="https://github.com/LGFae/swww"
ARCHIVE="$PKGNAME-$PKGVER.tar.gz"
SRC_DIR="$PKGNAME-$PKGVER"

# Install dependencies
echo -e "\033[0;32m[INFO]\033[0m Installing build dependencies..."
sudo dnf install -y \
    gcc glibc-devel lz4 lz4-devel cargo rustc scdoc \
    bash-completion fish zsh elvish man-db wget

# Download source code
echo -e "\033[0;32m[INFO]\033[0m Downloading source code..."
wget -O "$ARCHIVE" "$URL/archive/v$PKGVER.tar.gz"

# Extract source code
echo -e "\033[0;32m[INFO]\033[0m Extracting source code..."
tar -xzf "$ARCHIVE"

# Prepare for build
cd "$SRC_DIR"
export RUSTUP_TOOLCHAIN=stable
cargo fetch --locked --target "$(rustc -vV | sed -n 's/host: //p')"

# Build
echo -e "\033[0;32m[INFO]\033[0m Building swww..."
export CARGO_TARGET_DIR=target
cargo build --frozen --release --all-features

# Generate manpages
echo -e "\033[0;32m[INFO]\033[0m Generating manpages..."
./doc/gen.sh

# Install binaries
echo -e "\033[0;32m[INFO]\033[0m Installing binaries and files..."
sudo install -Dm755 target/release/swww -t /usr/bin/
sudo install -Dm755 target/release/swww-daemon -t /usr/bin/

# Install shell completions
sudo install -Dm644 completions/swww.bash /usr/share/bash-completion/completions/swww
sudo install -Dm644 completions/swww.fish /usr/share/fish/vendor_completions.d/swww.fish
sudo install -Dm644 completions/_swww /usr/share/zsh/site-functions/_swww
sudo install -Dm644 completions/swww.elv /usr/share/elvish/lib/swww.elv

# Install documentation and manpages
sudo install -Dm644 -t /usr/share/doc/$PKGNAME ./*.md
sudo install -Dm644 -t /usr/share/man/man1 ./doc/generated/*.1

# Cleanup
echo -e "\033[0;32m[INFO]\033[0m Cleaning up..."
rm -rf "$SRC_DIR" "$ARCHIVE"

# Verification
echo -e "\033[0;32m[INFO]\033[0m Verifying installation..."
if command -v swww &>/dev/null && command -v swww-daemon &>/dev/null; then
    echo -e "\033[0;32m[SUCCESS]\033[0m swww installed successfully!"
else
    echo -e "\033[0;31m[ERROR]\033[0m Installation failed. Please check the logs."
    exit 1
fi
