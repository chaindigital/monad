# Address Roles in Monad Validator Operations

Monad validator operations rely on **strict separation of address roles**.
This separation is critical for security, operational safety, and long-term maintainability.

This document explains **why multiple addresses are used**, what each role controls,
and how they are expected to be used in practice.

---

## Overview

A Monad validator typically uses **three distinct addresses**:

1. Funded Address  
2. Auth Address  
3. Beneficiary Address  

Each address has a **non-overlapping responsibility domain**.

Mixing these roles is technically possible but **strongly discouraged**.

---

## Funded Address

**Purpose:**  
Pays for transaction fees and provides the validator’s self-stake.

**Used for:**
- Paying gas for `add-validator`, `delegate`, `undelegate`, etc.
- Providing the required `MIN_VALIDATE_STAKE`
- Funding future staking-related transactions

**Security model:**
- Hot wallet or semi-hot wallet
- Must be funded, but does **not** need validator control authority

**Best practices:**
- Keep balance minimal but sufficient
- Do NOT use this address as the auth address
- Can be rotated without affecting validator ownership

---

## Auth Address

**Purpose:**  
Controls validator identity and staking authority.

**Used for:**
- `add-validator`
- Validator configuration updates
- Staking and delegation control
- Validator lifecycle actions

**Security model:**
- High-trust address
- Must be tightly protected
- Loss of this key may result in permanent loss of validator control

**Important:**
- The `--auth-address` flag refers to **this address**
- It does **not** need to hold MON
- It does **not** receive rewards

**Best practices:**
- Cold wallet or hardware wallet
- Never reused for funding or rewards
- Treated as a governance / control key

---

## Beneficiary Address

**Purpose:**  
Receives validator rewards.

**Used for:**
- Block rewards
- Staking rewards
- Validator income accounting

**Security model:**
- Read-only from validator perspective
- No operational authority

**Best practices:**
- Separate accounting address
- Can be a multisig
- Can be changed without affecting validator control

---

## Why Role Separation Matters

Separating address roles provides:

- Reduced blast radius in case of key compromise
- Cleaner accounting and reward tracking
- Safer operational workflows
- Easier audits and incident response

Example failure scenarios avoided:
- Funding wallet compromised → validator control remains safe
- Reward address exposed → no staking authority lost
- Operator rotation → no need to migrate funds or keys

---

## Common Anti-Patterns

❌ Using the same address for all roles  
❌ Using the funded address as the auth address  
❌ Keeping auth-address funded “just in case”  
❌ Storing auth-address keys on the validator node  

---

## Typical Validator Setup

| Role | Wallet Type |
|---|---|
| Funded Address | Hot / Ops wallet |
| Auth Address | Cold wallet / Hardware wallet |
| Beneficiary Address | Accounting / Treasury wallet |

---

## Summary

- **Funded Address** → pays fees and self-stake  
- **Auth Address** → controls the validator  
- **Beneficiary Address** → receives rewards  

This repository assumes **strict role separation** and all scripts,
examples, and operational guidance are written with this model in mind.

Always verify addresses and roles **before executing irreversible actions**
such as `add-validator` on mainnet.
