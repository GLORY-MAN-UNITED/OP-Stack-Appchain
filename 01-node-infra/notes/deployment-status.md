# Deployment Status

Date: 2026-05-15

## Result

The local OP Stack appchain is deployed and running.

- L1: Ethereum Sepolia
- L2 chain ID: `61091`
- Local L2 RPC: `http://localhost:8545`
- Local rollup RPC: `http://localhost:8547`
- Deployment transaction: `0x7f7b1f1036b392122900a9ca3c22fb8ea84208bf7a68cb6d6efb0cead9fa0dee`
- SystemConfigProxy: `0xcfa802ec1973a2f40d715df39582f6fe61595dc4`
- DisputeGameFactoryProxy: `0xf328b35415aa79a1b279881d739fbbe78e04f041`

## Runtime Images

- `op-geth`: `v1.101702.2`
- `op-node`: `v1.18.0`
- `op-batcher`: `v1.16.8`
- `op-proposer`: `v1.16.0`

## Verification

- `op-geth` returns L2 chain ID `0xeea3` (`61091`).
- `op-node` is sequencing unsafe L2 blocks.
- `op-batcher` published and confirmed calldata batches on Sepolia.
- `op-proposer` connected to the DisputeGameFactory and started.

## Notes

`op-deployer v0.6.0-rc.2` is used for setup. Older `op-deployer v0.0.10` produced a single OP chain deployment transaction above the current Sepolia per-transaction gas cap, so it is not suitable for this setup.
