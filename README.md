# CHAIN DIGITAL — <img src="https://raw.githubusercontent.com/chaindigital/logo/main/monad.png" width="28"/> Monad Tooling Suite

Monad is a high-performance Layer 1 blockchain engineered for speed without sacrificing security or decentralization, all while maintaining full compatibility with the existing Ethereum ecosystem.

Official documentation:
- 📘 [Monad Technical Documentation](https://docs.monad.xyz/)

---

# Monad Validator — Setup & Operations

This repository contains **operational scripts and workflows** for running a Monad validator  
across **testnet and mainnet** environments.

All scripts are designed to be:
- deterministic
- idempotent
- safe to re-run
- suitable for automated or manual execution

> ⚠️ This repository focuses on **validator and staking operations**.  
> OS hardening and hardware provisioning are intentionally out of scope.

---

## Repository Scope

This repo covers the full validator lifecycle:

1. Node preparation and preflight checks  
2. Validator key verification  
3. Validator onboarding (add-validator)  
4. Staking and control address roles  
5. Testnet → Mainnet transition  

Each section below references a **dedicated script**, with a clear execution command.

---

## Monad Setup & Upgrade Scripts

### 🛠️ Testnet Setup

Initial preparation of a Monad node for **testnet validator onboarding**.

**What this script does:**
- validates required binaries
- checks node sync status
- verifies keystore presence
- ensures control panel socket availability

**When to run:**
- after node installation
- before any staking or validator-related transactions

~~~bash
source <(curl -s https://raw.githubusercontent.com/chaindigital/monad/main/scripts/testnet-setup.sh)
~~~

---

### 🛠️ Mainnet Setup

Mainnet-specific preparation with stricter safety checks.

**What this script does:**
- enforces mainnet configuration flags
- validates chain-id
- performs additional consensus safety checks
- blocks execution if testnet artifacts are detected

**When to run:**
- before mainnet validator registration
- after migrating infrastructure from testnet

~~~bash
source <(curl -s https://raw.githubusercontent.com/chaindigital/monad/main/scripts/mainnet-setup.sh)
~~~

---

## Validator Preflight & Safety

### 🔍 Validator Preflight Check

Performs mandatory checks **before running `add-validator`**.

**What this script does:**
- confirms node is fully synced
- verifies SECP and BLS keystores
- validates control socket access
- prevents accidental validator registration on an unsynced node

**When to run:**
- immediately before validator onboarding

~~~bash
source <(curl -s https://raw.githubusercontent.com/chaindigital/monad/main/scripts/validator-preflight.sh)
~~~

---

### 🔑 Consensus Key Verification

Ensures that **on-chain validator keys match local node keys**.

**What this script does:**
- extracts local SECP and BLS public keys
- compares them with keys shown by the staking CLI
- aborts if any mismatch is detected

**Why this matters:**
Registering a validator with incorrect keys results in a **permanently unusable validator**.

~~~bash
source <(curl -s https://raw.githubusercontent.com/chaindigital/monad/main/scripts/verify-consensus-keys.sh)
~~~

---

## Staking & Validator Control

### 🧾 Address Roles Overview

Monad validator operations involve **multiple address roles**.

This repository distinguishes between:

- **Funded Address** — pays transaction fees and self-stake
- **Auth Address** — controls validator operations
- **Beneficiary Address** — receives rewards

See also:
[Monad Address & Validator Documentation](https://github.com/chaindigital/monad/tree/main/docs/address-roles.md)

