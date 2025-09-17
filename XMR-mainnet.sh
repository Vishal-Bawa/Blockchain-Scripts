#!/bin/bash
set -e

# === CONFIG ===
VERSION="v0.18.4.2"
FILE="monero-linux-x64-v0.18.4.2.tar.bz2"

# === PREPARE SERVER ===
apt update && apt upgrade -y
apt install -y curl wget gnupg bzip2 tar ufw

# ensure mount point exists
mkdir -p /data/monero/logs

# === DOWNLOAD MONERO BINARIES ===
cd /tmp
curl -LO "https://downloads.getmonero.org/cli/${FILE}"

# === VERIFY SIGNATURE ===
# import maintainer key
curl https://raw.githubusercontent.com/monero-project/monero/master/utils/gpg_keys/binaryfate.asc | gpg --import

# download hashes
curl -s https://www.getmonero.org/downloads/hashes.txt > /tmp/hashes.txt
gpg --verify /tmp/hashes.txt

# check SHA-256
sha256sum "$FILE" | awk '{print $1}' > /tmp/myhash.txt
grep -Ff /tmp/myhash.txt /tmp/hashes.txt || { echo "Hash mismatch! Aborting."; exit 1; }

# === INSTALL BINARIES ===
tar -xvf "$FILE"
EXDIR=$(tar -tf "$FILE" | head -1 | cut -d/ -f1)
mv "${EXDIR}"/* /usr/local/bin/

# === CONFIGURE MONEROD ===
mkdir -p /etc/monero

tee /etc/monero/monerod.conf > /dev/null <<'EOF'
# blockchain location
data-dir=/data/monero

# pruning (saves space; uncomment to enable)
#prune-blockchain=1
#sync-pruned-blocks=1

check-updates=disabled
enable-dns-blocklist=1

# logs
log-file=/data/monero/logs/monero.log
log-level=0
max-log-file-size=2147483648

# restricted RPC (wallet connections)
rpc-restricted-bind-ip=0.0.0.0
rpc-restricted-bind-port=18089
rpc-ssl=autodetect

# ZMQ (optional)
zmq-pub=tcp://127.0.0.1:18083

disable-rpc-ban=1
out-peers=12
in-peers=48
limit-rate-up=1048576
limit-rate-down=1048576
max-txpool-weight=2684354560
EOF

# === SYSTEMD SERVICE ===
tee /etc/systemd/system/monerod.service > /dev/null <<'EOF'
[Unit]
Description=Monero Daemon
After=network-online.target

[Service]
ExecStart=/usr/local/bin/monerod --detach --config-file /etc/monero/monerod.conf --pidfile /run/monerod.pid
ExecStartPost=/bin/sleep 0.1
PIDFile=/run/monerod.pid
Type=forking
Restart=on-failure
RestartSec=30
RuntimeDirectory=monero
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# reload systemd, enable service
systemctl daemon-reload
systemctl enable --now monerod

# === FIREWALL ===
ufw allow 18080/tcp   # P2P
ufw allow 18089/tcp   # RPC
ufw reload

echo "=== Installation complete! ==="
echo "Check status with: systemctl status monerod"
echo "Follow logs with: tail -f /data/monero/logs/monero.log"
