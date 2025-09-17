#!/bin/bash

set -e

echo "🔄 Starting Tezos node update..."

# Step 1: Prepare working directory
cd /data
mkdir -p new_version
cd new_version

echo "⬇️ Downloading Tezos binary..."
wget -O octez-binaries-23.2-linux-x86_64.tar.gz https://gitlab.com/tezos/tezos/-/package_files/200923183/download

echo "📦 Extracting archive..."
tar -xvf octez-binaries-23.2-linux-x86_64.tar.gz

# Step 2: Stop existing Tezos node
echo "🛑 Stopping Tezos service..."
systemctl stop tezos.service

# Step 3: Replace old binary
echo "🔁 Updating binary..."
cd /usr/local/bin/
mv -v octez-node old-octez-node

cd /data/new_version/octez-x86_64
mv -v octez-node /usr/local/bin/

# Step 4: Start Tezos node again
echo "🚀 Starting Tezos service..."
systemctl start tezos.service

# Step 5: Check service status and version
echo "📊 Tezos service status:"
systemctl status tezos.service --no-pager

echo "🧾 Tezos node version:"
octez-node --version

