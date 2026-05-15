# 01. Node & Infra

This folder owns the OP Stack deployment and node operations work for `Option 2` in [requirement.md](../requirement.md).

## Layout

- `deployer/` L1 deployment workspace driven by `op-deployer`
- `sequencer/` local `op-geth` and `op-node` runtime files
- `batcher/` batch submission runtime files
- `proposer/` output proposal runtime files
- `scripts/` PowerShell automation
- `notes/` planning, alignment, and input checklists
- `docker-compose.yml` local runtime for sequencer, batcher, and proposer
- `.env.example` root configuration template

## Scope

- Deploy a basic OP Stack appchain
- Use Sepolia as the L1 testnet
- Run sequencer, batcher, and proposer locally
- Prepare the infra needed for the payment app and later TPS / fee benchmarking

## Quick Start

1. Run `scripts/bootstrap.ps1`
2. Run `scripts/doctor.ps1`
3. Fill in `.env`
4. Run `scripts/download-op-deployer.ps1`
5. Run `scripts/test-network.ps1`
6. Run `scripts/setup-rollup.ps1`
7. Run `scripts/up.ps1`

## MVP Decision

- Use a local single-machine OP Stack setup first.
- Use Sepolia only as the L1 testnet and benchmark reference.
- Do not deploy to a server unless local resources become a bottleneck.
- See `notes/inputs-needed.md` for the exact checklist.
- See `notes/requirement-alignment.md` for how this folder maps to the course requirement.
- See `notes/deployment-status.md` for the current deployed Sepolia testnet details.

## Required Values For Sepolia

- `L1_RPC_URL`
- `L1_DEPLOY_RPC_URL` optional fallback if your main provider rejects large deployment transactions
- `L1_BEACON_URL`
- `PRIVATE_KEY`
- `ADMIN_ADDRESS`

For the simplest demo, use one funded Sepolia wallet for `ADMIN_ADDRESS`, `PRIVATE_KEY`, batcher, proposer, and sequencer roles. If role-specific addresses are left blank, `scripts/setup-rollup.ps1` uses `ADMIN_ADDRESS` for those roles.

Use `scripts/setup-rollup.ps1 -Reset` only when you intentionally want to create a new deployment state and spend Sepolia ETH again.

## Scripts

- `scripts/bootstrap.ps1` creates local folders and copies `.env`
- `scripts/doctor.ps1` validates tools, daemon state, and env completeness
- `scripts/download-op-deployer.ps1` downloads `op-deployer v0.6.0-rc.2` for the Dockerized local setup and also tries to download the optional latest Windows binary
- `scripts/test-network.ps1` validates Sepolia RPC, Beacon API, wallet balance, and Docker
- `scripts/setup-rollup.ps1` initializes `op-deployer`, deploys L1 contracts, copies configs, and prepares local runtime files
- `scripts/up.ps1` starts the local runtime with Docker Compose
- `scripts/down.ps1` stops the local runtime
- `scripts/status.ps1` shows container state
- `scripts/logs.ps1` tails service logs
