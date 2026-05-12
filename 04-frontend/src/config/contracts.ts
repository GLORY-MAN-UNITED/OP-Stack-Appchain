import type { Abi, Address } from "viem";

export const paymentContractAddress = (import.meta.env
  .VITE_PAYMENT_CONTRACT_ADDRESS || "") as Address;

export const mockErc20Address = (import.meta.env
  .VITE_MOCK_ERC20_ADDRESS || "") as Address;

export const hasPaymentContract = /^0x[a-fA-F0-9]{40}$/.test(
  paymentContractAddress,
);

export const hasMockTokenContract = /^0x[a-fA-F0-9]{40}$/.test(mockErc20Address);

// TODO from teammate 2: replace this ABI with the deployed Payment contract ABI.
// Current assumption: payment flow is approve(token, amount) -> sendPayment(merchant, amount, memo).
export const paymentAbi = [
  {
    type: "function",
    name: "sendPayment",
    stateMutability: "nonpayable",
    inputs: [
      { name: "merchant", type: "address" },
      { name: "amount", type: "uint256" },
      { name: "memo", type: "string" },
    ],
    outputs: [],
  },
  {
    type: "function",
    name: "getUserPayments",
    stateMutability: "view",
    inputs: [{ name: "user", type: "address" }],
    outputs: [
      {
        name: "",
        type: "tuple[]",
        components: [
          { name: "payer", type: "address" },
          { name: "merchant", type: "address" },
          { name: "amount", type: "uint256" },
          { name: "timestamp", type: "uint256" },
          { name: "memo", type: "string" },
        ],
      },
    ],
  },
  {
    type: "function",
    name: "getMerchantPayments",
    stateMutability: "view",
    inputs: [{ name: "merchant", type: "address" }],
    outputs: [
      {
        name: "",
        type: "tuple[]",
        components: [
          { name: "payer", type: "address" },
          { name: "merchant", type: "address" },
          { name: "amount", type: "uint256" },
          { name: "timestamp", type: "uint256" },
          { name: "memo", type: "string" },
        ],
      },
    ],
  },
  {
    type: "event",
    name: "PaymentSent",
    inputs: [
      { name: "payer", type: "address", indexed: true },
      { name: "merchant", type: "address", indexed: true },
      { name: "amount", type: "uint256", indexed: false },
      { name: "timestamp", type: "uint256", indexed: false },
      { name: "memo", type: "string", indexed: false },
    ],
    anonymous: false,
  },
] as const satisfies Abi;

// TODO from teammate 2: replace or extend this ABI with the deployed Mock ERC20 ABI.
export const mockErc20Abi = [
  {
    type: "function",
    name: "approve",
    stateMutability: "nonpayable",
    inputs: [
      { name: "spender", type: "address" },
      { name: "amount", type: "uint256" },
    ],
    outputs: [{ name: "", type: "bool" }],
  },
  {
    type: "function",
    name: "decimals",
    stateMutability: "view",
    inputs: [],
    outputs: [{ name: "", type: "uint8" }],
  },
  {
    type: "function",
    name: "symbol",
    stateMutability: "view",
    inputs: [],
    outputs: [{ name: "", type: "string" }],
  },
  {
    type: "function",
    name: "balanceOf",
    stateMutability: "view",
    inputs: [{ name: "account", type: "address" }],
    outputs: [{ name: "", type: "uint256" }],
  },
  {
    type: "function",
    name: "mint",
    stateMutability: "nonpayable",
    inputs: [
      { name: "to", type: "address" },
      { name: "amount", type: "uint256" },
    ],
    outputs: [],
  },
] as const satisfies Abi;

export type PaymentRecord = {
  payer: Address;
  merchant: Address;
  amount: bigint;
  timestamp: bigint;
  memo: string;
};

export const contractTodoItems = [
  "TODO from teammate 2: Payment contract address",
  "TODO from teammate 2: Payment contract ABI",
  "TODO from teammate 2: Mock ERC20 contract address",
  "TODO from teammate 2: Mock ERC20 ABI",
  "TODO from teammate 2: confirm approve -> sendPayment flow",
  "TODO from teammate 2: payment function name and parameters",
  "TODO from teammate 2: user/merchant history function names and return structures",
  "TODO from teammate 2: PaymentSent event fields",
  "TODO from teammate 2: merchant registration or whitelist requirement",
  "TODO from teammate 2: Mock ERC20 mint/faucet method",
];
