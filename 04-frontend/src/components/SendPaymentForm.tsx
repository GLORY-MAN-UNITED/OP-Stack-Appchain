import { useMemo, useState } from "react";
import { CheckCircle2, Send } from "lucide-react";
import { isAddress, parseUnits } from "viem";
import {
  useAccount,
  useReadContract,
  useWaitForTransactionReceipt,
  useWriteContract,
} from "wagmi";
import {
  hasMockTokenContract,
  hasPaymentContract,
  mockErc20Abi,
  mockErc20Address,
  paymentAbi,
  paymentContractAddress,
} from "../config/contracts";

type Props = {
  disabled: boolean;
};

export function SendPaymentForm({ disabled }: Props) {
  const { address } = useAccount();
  const [merchant, setMerchant] = useState("");
  const [amount, setAmount] = useState("");
  const [memo, setMemo] = useState("");
  const [lastStep, setLastStep] = useState<"idle" | "approved" | "sent">("idle");

  const { data: decimals = 18 } = useReadContract({
    address: mockErc20Address,
    abi: mockErc20Abi,
    functionName: "decimals",
    query: { enabled: hasMockTokenContract },
  });

  const { data: symbol = "TOKEN" } = useReadContract({
    address: mockErc20Address,
    abi: mockErc20Abi,
    functionName: "symbol",
    query: { enabled: hasMockTokenContract },
  });

  const parsedAmount = useMemo(() => {
    if (!amount || Number(amount) <= 0) return 0n;
    try {
      return parseUnits(amount, Number(decimals));
    } catch {
      return 0n;
    }
  }, [amount, decimals]);

  const { writeContractAsync, data: hash, isPending } = useWriteContract();
  const { isLoading: isConfirming } = useWaitForTransactionReceipt({ hash });

  const formReady =
    !disabled &&
    hasPaymentContract &&
    hasMockTokenContract &&
    isAddress(merchant) &&
    parsedAmount > 0n;

  async function approveToken() {
    if (!formReady) return;
    await writeContractAsync({
      address: mockErc20Address,
      abi: mockErc20Abi,
      functionName: "approve",
      args: [paymentContractAddress, parsedAmount],
    });
    setLastStep("approved");
  }

  async function sendPayment() {
    if (!formReady) return;
    await writeContractAsync({
      address: paymentContractAddress,
      abi: paymentAbi,
      functionName: "sendPayment",
      args: [merchant, parsedAmount, memo],
    });
    setLastStep("sent");
  }

  return (
    <section className="panel payment-panel">
      <div className="panel-heading">
        <Send size={18} />
        <h2>Send Payment</h2>
      </div>

      <label className="field">
        <span>Merchant address</span>
        <input
          value={merchant}
          onChange={(event) => setMerchant(event.target.value)}
          placeholder="0x..."
          spellCheck={false}
        />
      </label>

      <label className="field">
        <span>Amount</span>
        <div className="amount-row">
          <input
            value={amount}
            onChange={(event) => setAmount(event.target.value)}
            placeholder="10.00"
            inputMode="decimal"
          />
          <strong>{symbol}</strong>
        </div>
      </label>

      <label className="field">
        <span>Memo</span>
        <input
          value={memo}
          onChange={(event) => setMemo(event.target.value)}
          placeholder="Order #1001"
        />
      </label>

      <div className="action-row">
        <button disabled={!formReady || isPending || isConfirming} onClick={approveToken}>
          Approve
        </button>
        <button
          className="primary"
          disabled={!formReady || isPending || isConfirming}
          onClick={sendPayment}
        >
          Send Payment
        </button>
      </div>

      <div className="flow-note">
        <CheckCircle2 size={16} />
        <span>
          Current assumed flow: ERC20 approve Payment contract, then call{" "}
          <code>sendPayment(merchant, amount, memo)</code>.
        </span>
      </div>

      {address ? <p className="muted-line">Connected payer: {address}</p> : null}
      {lastStep !== "idle" ? (
        <p className="muted-line">
          Last action: {lastStep === "approved" ? "approve submitted" : "payment submitted"}
        </p>
      ) : null}
      {!hasPaymentContract || !hasMockTokenContract ? (
        <p className="error-line">
          Contract addresses are placeholders. Fill `.env` after teammate 2 deploys contracts.
        </p>
      ) : null}
    </section>
  );
}
