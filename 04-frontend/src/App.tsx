import { ConnectButton } from "@rainbow-me/rainbowkit";
import { AlertCircle, BarChart3, Send, WalletCards } from "lucide-react";
import { useAccount, useChainId } from "wagmi";
import { paymentChain } from "./config/chain";
import { hasMockTokenContract, hasPaymentContract } from "./config/contracts";
import { MerchantDashboard } from "./components/MerchantDashboard";
import { SendPaymentForm } from "./components/SendPaymentForm";
import { TransactionHistory } from "./components/TransactionHistory";

export function App() {
  const { isConnected } = useAccount();
  const chainId = useChainId();
  const isExpectedChain = chainId === paymentChain.id;

  return (
    <main className="app-shell">
      <header className="topbar">
        <div>
          <p className="eyebrow">OP Stack Payment Appchain</p>
          <h1>Payment Console</h1>
        </div>
        <ConnectButton />
      </header>

      <section className="status-grid">
        <StatusTile
          icon={<WalletCards size={20} />}
          label="Network"
          value={paymentChain.name}
          muted={`Chain ID ${paymentChain.id}`}
        />
        <StatusTile
          icon={<Send size={20} />}
          label="Payment Contract"
          value={hasPaymentContract ? "Configured" : "Pending"}
          muted={hasPaymentContract ? "Ready for calls" : "Need deployed address"}
        />
        <StatusTile
          icon={<BarChart3 size={20} />}
          label="Mock ERC20"
          value={hasMockTokenContract ? "Configured" : "Pending"}
          muted={hasMockTokenContract ? "Approve enabled" : "Need token address"}
        />
      </section>

      {isConnected && !isExpectedChain ? (
        <div className="notice warning">
          <AlertCircle size={18} />
          <span>
            Wallet is connected to chain {chainId}. Switch to {paymentChain.name}{" "}
            before sending payments.
          </span>
        </div>
      ) : null}

      <section className="workspace-grid">
        <div className="main-column">
          <SendPaymentForm disabled={!isConnected || !isExpectedChain} />
          <TransactionHistory />
        </div>
        <aside className="side-column">
          <MerchantDashboard />
        </aside>
      </section>
    </main>
  );
}

function StatusTile({
  icon,
  label,
  value,
  muted,
}: {
  icon: React.ReactNode;
  label: string;
  value: string;
  muted: string;
}) {
  return (
    <div className="status-tile">
      <div className="status-icon">{icon}</div>
      <div>
        <p>{label}</p>
        <strong>{value}</strong>
        <span>{muted}</span>
      </div>
    </div>
  );
}


