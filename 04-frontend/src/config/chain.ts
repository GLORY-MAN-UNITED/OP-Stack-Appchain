import { defineChain } from "viem";

const envChainId = Number(import.meta.env.VITE_L2_CHAIN_ID || 901);

export const paymentChain = defineChain({
  id: Number.isFinite(envChainId) ? envChainId : 901,
  name: import.meta.env.VITE_L2_CHAIN_NAME || "Payment Appchain Local",
  nativeCurrency: {
    name: import.meta.env.VITE_L2_NATIVE_NAME || "Ether",
    symbol: import.meta.env.VITE_L2_NATIVE_SYMBOL || "ETH",
    decimals: Number(import.meta.env.VITE_L2_NATIVE_DECIMALS || 18),
  },
  rpcUrls: {
    default: {
      http: [import.meta.env.VITE_L2_RPC_URL || "http://127.0.0.1:8545"],
    },
  },
  blockExplorers: import.meta.env.VITE_L2_BLOCK_EXPLORER_URL
    ? {
        default: {
          name: "Payment Appchain Explorer",
          url: import.meta.env.VITE_L2_BLOCK_EXPLORER_URL,
        },
      }
    : undefined,
});

export const networkTodoItems = [
  "TODO from teammate 1: L2 RPC URL",
  "TODO from teammate 1: Chain ID",
  "TODO from teammate 1: Chain name",
  "TODO from teammate 1: native currency name / symbol / decimals",
  "TODO from teammate 1: MetaMask add-network configuration",
  "TODO from teammate 1: demo account gas source or faucet/bridge steps",
];
