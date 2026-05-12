# Payment Appchain Frontend

Frontend for Option 2: Payment Appchain Built on OP Stack.

## What to fill later

Teammate 1 should provide values for `.env`:

- `VITE_L2_RPC_URL`
- `VITE_L2_CHAIN_ID`
- `VITE_L2_CHAIN_NAME`
- `VITE_L2_NATIVE_NAME`
- `VITE_L2_NATIVE_SYMBOL`
- `VITE_L2_NATIVE_DECIMALS`
- `VITE_L2_BLOCK_EXPLORER_URL`

Teammate 2 should provide:

- `VITE_PAYMENT_CONTRACT_ADDRESS`
- `VITE_MOCK_ERC20_ADDRESS`
- Payment contract ABI in `src/config/contracts.ts`
- Mock ERC20 ABI in `src/config/contracts.ts`
- Confirm whether the payment flow is `approve -> sendPayment`
- Confirm the real names and parameters for payment/history/merchant functions

## Local setup

```bash
npm install
cp .env.example .env
npm run dev
```

Open the local URL printed by Vite.
