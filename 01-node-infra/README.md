# 01. Node & Infra

This folder owns the OP Stack deployment and node operations work.

## Layout

- `scripts/` bootstrap and environment checks
- `notes/` planning and deployment checklists
- `config/` runtime configuration
- `data/` local chain data
- `logs/` service logs
- `artifacts/` generated outputs
- `reports/` notes and result summaries

## Scope

- Deploy and maintain the testnet
- Configure Sequencer and RPC services
- Debug L1-L2 bridge flows
- Keep all bootstrap and validation scripts here

## Quick Start

1. Run `scripts/bootstrap.ps1`
2. Run `scripts/doctor.ps1`
3. Fill in `.env`
4. Put deployment assets under the folders above

## MVP Decision

- Use a local single-machine OP Stack setup first.
- Use Sepolia only as the L1 testnet and benchmark reference.
- Do not deploy to a server unless local resources become a bottleneck.
- See `notes/inputs-needed.md` for the exact checklist.

## Required Values For Sepolia

- `L1_RPC_URL`
- `PRIVATE_KEY`
- `ADMIN_ADDRESS`
