# Deployer

This directory holds the `op-deployer` workdir and generated L1 deployment artifacts.

- `.deployer/intent.toml` is created by `scripts/setup-rollup.ps1`
- `.deployer/state.json` records deployed L1 contract addresses
- `.deployer/genesis.json` and `.deployer/rollup.json` are copied into `sequencer/`
