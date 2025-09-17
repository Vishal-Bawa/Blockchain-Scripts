#!/bin/bash
set -euo pipefail

# Rippled upgrade script
# Location suggestion: /usr/local/bin/upgrade-rippled.sh
# Usage: sudo bash upgrade-rippled.sh

TS=$(date +%F_%H-%M-%S)
BACKUP_FILE="/root/rippled-config-backup-${TS}.tar.gz"

echo "🔎 Checking current version..."
rippled --version || /opt/ripple/bin/rippled --version || true

echo "🛑 Stopping rippled service..."
systemctl stop rippled.service

echo "📦 Backing up config and data to $BACKUP_FILE ..."
tar -czvf "$BACKUP_FILE" /etc/opt/ripple /opt/ripple /var/lib/rippled || true

echo "⬆️ Updating rippled package..."
apt -y update
apt -y upgrade rippled

echo "🔄 Reloading systemd and restarting rippled..."
systemctl daemon-reload
systemctl start rippled.service

echo "✅ Rippled service status:"
systemctl status rippled.service --no-pager

echo "🔎 New version:"
/opt/ripple/bin/rippled --version || rippled --version || true

echo "📜 Following logs (Ctrl+C to stop):"
journalctl -u rippled -f

