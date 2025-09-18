#!/bin/bash
set -e

echo "Stopping sui.service..."
sudo systemctl stop sui.service

# Backup old binary if exists
if [ -f /usr/local/bin/sui-node ]; then
    BACKUP_NAME="old-sui-node-$(date +%Y%m%d-%H%M%S)"
    echo "Backing up current sui-node binary to $BACKUP_NAME..."
    sudo mv /usr/local/bin/sui-node "/usr/local/bin/$BACKUP_NAME"
fi
# Work in /tmp to avoid file conflicts
TMP_DIR=$(mktemp -d)
cd "$TMP_DIR"

# Download new version
echo "Downloading Sui v1.56.2..."
wget -q https://github.com/MystenLabs/sui/releases/download/mainnet-v1.56.2/sui-mainnet-v1.56.2-ubuntu-x86_64.tgz

# Extract
echo "Extracting Sui..."
tar -xvzf sui-mainnet-v1.56.2-ubuntu-x86_64.tgz


# Find and move the sui-node binary
if [ -d sui-mainnet-v1.56.2-ubuntu-x86_64.tgz ]; then
    cd sui-mainnet-v1.56.2-ubuntu-x86_64.tgz
fi

if [ -f sui-node ]; then
    sudo mv sui-node /usr/local/bin/
else
    echo "❌ Error: sui-node binary not found after extraction."
    exit 1
fi

cd /usr/local/bin/
chmod +x sui-node

# Clean up temp dir
rm -rf "$TMP_DIR"

# Start service
echo "Starting sui.service..."
sudo systemctl start sui.service

# Show service status
echo "--------------------------------------------------"
sudo systemctl status sui.service --no-pager

# Show version
echo "--------------------------------------------------"
echo "✅ Sui Version:"
sui-node --version

