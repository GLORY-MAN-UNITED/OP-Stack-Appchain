import { getDefaultConfig } from "@rainbow-me/rainbowkit";
import { http } from "wagmi";
import { paymentChain } from "./chain";

export const wagmiConfig = getDefaultConfig({
  appName: "Payment Appchain Demo",
  projectId:
    import.meta.env.VITE_WALLETCONNECT_PROJECT_ID || "payment-appchain-demo",
  chains: [paymentChain],
  transports: {
    [paymentChain.id]: http(),
  },
});
