#!/usr/bin/env bash
set -euo pipefail

echo "=== Monad Validator Preflight Check ==="

CONTROL_SOCKET="/home/monad/monad-bft/controlpanel.sock"
CONFIG_DIR="/home/monad/monad-bft/config"

fail() {
  echo "❌ $1"
  exit 1
}

ok() {
  echo "✅ $1"
}

echo "[1/5] Checking control panel socket"
[[ -S "$CONTROL_SOCKET" ]] || fail "Control socket not found: $CONTROL_SOCKET"
ok "Control socket present"

echo "[2/5] Checking node sync status"
SYNC_STATUS=$(monad-debug-node \
  --control-panel-ipc-path "$CONTROL_SOCKET" \
  status 2>/dev/null | jq -r '.sync_info.catch_up')

[[ "$SYNC_STATUS" == "false" ]] || fail "Node is still syncing"
ok "Node fully synced"

echo "[3/5] Checking keystore presence"

[[ -f "$CONFIG_DIR/id-secp" ]] || fail "SECP keystore not found"
[[ -f "$CONFIG_DIR/id-bls"  ]] || fail "BLS keystore not found"

ok "SECP and BLS keystores found"

echo "[4/5] Checking node configuration"
[[ -f "$CONFIG_DIR/node.toml" ]] || fail "node.toml not found"
ok "node.toml present"

echo "[5/5] Basic safety checks passed"

echo ""
echo "🎯 Preflight result: OK"
echo "You may proceed with validator onboarding (add-validator)."
