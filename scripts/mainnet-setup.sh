#!/usr/bin/env bash
set -euo pipefail

echo "=== Monad Mainnet Full Node Installation ==="

### CONFIG ###
MONAD_VERSION="0.12.7"
MF_BUCKET="https://bucket.monadinfra.com"
TRIEDB_DRIVE="/dev/nvme1n1"   # ⚠️ CHANGE THIS
OTEL_VERSION="0.139.0"

### SAFETY ###
if [[ $EUID -ne 0 ]]; then
  echo "Run as root"
  exit 1
fi

echo "[1/14] System update"
apt update
apt upgrade -y
apt install -y curl nvme-cli aria2 jq ufw gpg

echo "[2/14] Configure Monad APT repo"
mkdir -p /etc/apt/keyrings
cat <<EOF > /etc/apt/sources.list.d/category-labs.sources
Types: deb
URIs: https://pkg.category.xyz/
Suites: noble
Components: main
Signed-By: /etc/apt/keyrings/category-labs.gpg
EOF

curl -fsSL https://pkg.category.xyz/keys/public-key.asc \
  | gpg --dearmor --yes -o /etc/apt/keyrings/category-labs.gpg

apt update
apt install -y monad=${MONAD_VERSION}
apt-mark hold monad

echo "[3/14] Create monad user"
id monad &>/dev/null || useradd -m -s /bin/bash monad

echo "[4/14] Create directory structure"
mkdir -p /home/monad/monad-bft/{config,ledger}
mkdir -p /home/monad/monad-bft/config/{forkpoint,validators}

echo "[5/14] Configure TrieDB disk"
echo "⚠️ Formatting ${TRIEDB_DRIVE}"
parted -s $TRIEDB_DRIVE mklabel gpt
parted -s $TRIEDB_DRIVE mkpart triedb 0% 100%

PARTUUID=$(lsblk -o PARTUUID $TRIEDB_DRIVE | tail -n 1)
echo "ENV{ID_PART_ENTRY_UUID}==\"$PARTUUID\", MODE=\"0666\", SYMLINK+=\"triedb\"" \
  > /etc/udev/rules.d/99-triedb.rules

udevadm trigger
udevadm control --reload
udevadm settle
ls -l /dev/triedb

echo "[6/14] Ensure 512B LBA"
nvme id-ns -H $TRIEDB_DRIVE | grep 'LBA Format' | grep '(in use)' || \
  nvme format --lbaf=0 $TRIEDB_DRIVE

echo "[7/14] Initialize TrieDB"
systemctl start monad-mpt
journalctl -u monad-mpt -n 20 --no-pager

echo "[8/14] Firewall setup"
ufw allow ssh
ufw allow 8000
ufw allow 8001
ufw --force enable

iptables -I INPUT -p udp --dport 8000 -m length --length 0:1400 -j DROP || true

echo "[9/14] Install OTEL Collector"
OTEL_PKG="otelcol_${OTEL_VERSION}_linux_amd64.deb"
curl -fsSL "https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v${OTEL_VERSION}/${OTEL_PKG}" \
  -o /tmp/${OTEL_PKG}
dpkg -i /tmp/${OTEL_PKG}

cp /opt/monad/scripts/otel-config.yaml /etc/otelcol/config.yaml
systemctl restart otelcol

echo "[10/14] Fetch mainnet configs"
curl -o /home/monad/.env \
  ${MF_BUCKET}/config/mainnet/latest/.env.example

curl -o /home/monad/monad-bft/config/node.toml \
  ${MF_BUCKET}/config/mainnet/latest/full-node-node.toml

echo "[11/14] Generate keystore password"
sed -i "s|^KEYSTORE_PASSWORD=$|KEYSTORE_PASSWORD='$(openssl rand -base64 32)'|" /home/monad/.env
source /home/monad/.env

mkdir -p /opt/monad/backup
echo "Keystore password: ${KEYSTORE_PASSWORD}" \
  > /opt/monad/backup/keystore-password-backup

echo "[12/14] Generate BLS & SECP keys"
monad-keystore create \
  --key-type secp \
  --keystore-path /home/monad/monad-bft/config/id-secp \
  --password "${KEYSTORE_PASSWORD}" \
  > /opt/monad/backup/secp-backup

monad-keystore create \
  --key-type bls \
  --keystore-path /home/monad/monad-bft/config/id-bls \
  --password "${KEYSTORE_PASSWORD}" \
  > /opt/monad/backup/bls-backup

grep "public key" /opt/monad/backup/* \
  | tee /home/monad/pubkeys.txt

echo "[13/14] Permissions"
chown -R monad:monad /home/monad /opt/monad

echo "[14/14] Enable services"
systemctl enable monad-bft monad-execution monad-rpc

echo "✅ Monad mainnet full node installed"
echo "➡️ Next steps:"
echo "   Follow the official hard-reset & snapshot restore guide:"
echo "   https://docs.monad.xyz/node-ops/node-recovery/hard-reset"
echo ""
echo "Then start the node:"
echo "   systemctl start monad-bft monad-execution monad-rpc"
