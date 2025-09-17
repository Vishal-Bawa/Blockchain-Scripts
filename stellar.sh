#!/bin/bash
set -euo pipefail

# === Variables (change if needed) ===
STELLAR_USER="stellar-core"
STELLAR_DB="stellar_core"
STELLAR_DB_USER="stellar"
STELLAR_DB_PASS="YourStrongPassword123"
STELLAR_DATA_DIR="/var/lib/stellar"
STELLAR_CFG="/etc/stellar/stellar-core.cfg"

# === Step 1: System update ===
apt update && apt upgrade -y

# === Step 2: Install dependencies ===
apt install -y build-essential cmake git libpq-dev pkg-config bison flex doxygen \
    libssl-dev wget unzip python3 python3-pip postgresql postgresql-contrib curl jq

# === Step 3: Install Stellar Core from repo ===
install -d /etc/apt/keyrings
curl -fsSL https://apt.stellar.org/SDF.asc -o /etc/apt/keyrings/SDF.asc
chmod a+r /etc/apt/keyrings/SDF.asc
echo "deb [signed-by=/etc/apt/keyrings/SDF.asc] https://apt.stellar.org $(lsb_release -cs) stable" \
  | tee /etc/apt/sources.list.d/SDF.list
apt update && apt install -y stellar-core

# === Step 4: Setup PostgreSQL database and user ===
sudo -u postgres psql -tc "SELECT 1 FROM pg_roles WHERE rolname='${STELLAR_DB_USER}'" | grep -q 1 || \
    sudo -u postgres psql -c "CREATE USER ${STELLAR_DB_USER} WITH PASSWORD '${STELLAR_DB_PASS}';"

sudo -u postgres psql -tc "SELECT 1 FROM pg_database WHERE datname='${STELLAR_DB}'" | grep -q 1 || \
    sudo -u postgres psql -c "CREATE DATABASE ${STELLAR_DB} OWNER ${STELLAR_DB_USER};"

# === Step 5: Setup Stellar Core system user ===
id -u ${STELLAR_USER} &>/dev/null || adduser --system --home ${STELLAR_DATA_DIR} --no-create-home --group ${STELLAR_USER}
mkdir -p ${STELLAR_DATA_DIR}
chown -R ${STELLAR_USER}:${STELLAR_USER} ${STELLAR_DATA_DIR}

# === Step 6: Configure stellar-core.cfg ===
cat > ${STELLAR_CFG} <<EOF
HTTP_PORT=11626
PUBLIC_HTTP_PORT=true
DATABASE="postgresql://${STELLAR_DB_USER}:${STELLAR_DB_PASS}@localhost/${STELLAR_DB}"
NETWORK_PASSPHRASE="Public Global Stellar Network ; September 2015"
CATCHUP_RECENT=0
UNSAFE_QUORUM=false
FAILURE_SAFETY=1
LOG_FILE_PATH="/var/log/stellar/stellar-core.log"

# Example peer
KNOWN_PEERS=["core-live-a.stellar.org:11625","core-live-b.stellar.org:11625"]

[HISTORY.h1]
get="curl -sf https://history.stellar.org/prd/core-live/core_live_001/{0} -o {1}"
EOF

mkdir -p /var/log/stellar
chown ${STELLAR_USER}:${STELLAR_USER} /var/log/stellar

# === Step 7: Initialize stellar-core DB ===
sudo -u ${STELLAR_USER} stellar-core --conf ${STELLAR_CFG} new-db
sudo -u ${STELLAR_USER} stellar-core --conf ${STELLAR_CFG} new-hist h1

# === Step 8: Enable and start stellar-core ===
systemctl daemon-reload
systemctl enable stellar-core
systemctl restart stellar-core

echo "✅ Stellar Core full node setup complete."
echo "Check sync status: curl -s http://localhost:11626/info | jq"

