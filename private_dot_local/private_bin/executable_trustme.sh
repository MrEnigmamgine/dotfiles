#!/usr/bin/env bash

# Configuration
CERT_URL="http://pki.a-squirrel.run/root.crt"
CERT_NAME="yggdrasil-ca-root.crt"

# Check for root/sudo
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (use sudo)"
  exit 1
fi

# Define the things to check for
ANCHOR_DIRS=(
    "/etc/ca-certificates/trust-source/anchors" # Arch
    "/etc/pki/trust/anchors"                   # Tumbleweed
    "/usr/local/share/ca-certificates"         # Debian / Ubuntu
    "/etc/pki/ca-trust/source/anchors"         # RHEL / CentOS / Rocky
)

UPDATE_CMDS=(
    "update-ca-trust extract"  # RHEL / CentOS / Rocky
    "update-ca-certificates"   # Debian / Ubuntu
)

# Try to find valid CA anchor directory
TARGET_DIR=""
for dir in "${ANCHOR_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        TARGET_DIR="$dir"
        break
    fi
done
if [ -z "$TARGET_DIR" ]; then
    echo "Error: CA anchor directory not found. Check your distribution's docs and install manually."
    exit 1
fi

# Try to find the valid update command
UPDATE_CMD=""
for cmd in "${UPDATE_CMDS[@]}"; do
    if command -v $cmd &> /dev/null; then
        UPDATE_CMD="$cmd"
        break
    fi
done
if [ -z "$UPDATE_CMD" ]; then
    echo "Error: CA update command not found. Check your distribution's docs and install manually."
    exit 1
fi

# Download the certificate
echo "Downloading certificate from $CERT_URL..."
if ! curl -fL -o "$TARGET_DIR/$CERT_NAME" "$CERT_URL"; then
    echo "Error: Failed to download certificate. Check the URL and your network connection."
    exit 1
fi

# Update the CA trust store
echo "Updating CA trust store with $UPDATE_CMD..."
if ! $UPDATE_CMD; then
    echo "Error: Failed to update CA trust store. Check the command and try again."
    exit 1
fi
