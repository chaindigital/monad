#!/usr/bin/env bash
set -euo pipefail

echo "=== Monad Consensus Key Verification ==="

CONFIG_DIR="/home/monad/monad-bft/config"

fail() {
  echo "❌ $1"
  exit 1
}

echo "[1/3] Extracting local public keys"

SECP_PUB=$(monad-keystore show \
  --keystore-path "$CONFIG_DIR/id-secp" \
  | grep -i "public key" | awk '{print $NF}')

BLS_PUB=$(monad-keystore show \
  --keystore-path "$CONFIG_DIR/id-bls" \
  | grep -i "public key" | awk '{print $NF}')

[[ -n "$SECP_PUB" ]] || fail "Failed to extract SECP public key"
[[ -n "$BLS_PUB"  ]] || fail "Failed to extract BLS public key"

echo ""
echo "Local consensus keys:"
echo "  SECP: $SECP_PUB"
echo "  BLS : $BLS_PUB"

echo ""
echo "[2/3] Manual verification step"
echo "Compare these keys with the output of your staking CLI:"
echo ""
echo "  staking-sdk-cli validator info <your-auth-address>"
echo ""
echo "Keys MUST match exactly."

echo ""
read -rp "Do the on-chain keys match these values? (yes/no): " CONFIRM

[[ "$CONFIRM" == "yes" ]] || fail "Key mismatch detected — aborting"

echo "[3/3] Verification confirmed"

echo ""
echo "🎯 Consensus key verification: PASSED"
echo "Safe to proceed with validator registration."
