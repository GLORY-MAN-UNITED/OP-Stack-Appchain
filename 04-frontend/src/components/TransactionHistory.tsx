import { History } from "lucide-react";
import { formatUnits } from "viem";
import { useAccount, useReadContract } from "wagmi";
import {
  hasPaymentContract,
  paymentAbi,
  paymentContractAddress,
  type PaymentRecord,
} from "../config/contracts";

export function TransactionHistory() {
  const { address } = useAccount();
  const { data, isLoading } = useReadContract({
    address: paymentContractAddress,
    abi: paymentAbi,
    functionName: "getUserPayments",
    args: address ? [address] : undefined,
    query: { enabled: hasPaymentContract && Boolean(address) },
  });

  const records = (data ?? []) as PaymentRecord[];

  return (
    <section className="panel">
      <div className="panel-heading">
        <History size={18} />
        <h2>Transaction History</h2>
      </div>
      <RecordTable records={records} emptyText={isLoading ? "Loading..." : "No payments yet"} />
    </section>
  );
}

export function RecordTable({
  records,
  emptyText,
}: {
  records: PaymentRecord[];
  emptyText: string;
}) {
  if (records.length === 0) {
    return <div className="empty-state">{emptyText}</div>;
  }

  return (
    <div className="table-wrap">
      <table>
        <thead>
          <tr>
            <th>Payer</th>
            <th>Merchant</th>
            <th>Amount</th>
            <th>Memo</th>
            <th>Time</th>
          </tr>
        </thead>
        <tbody>
          {records.map((record, index) => (
            <tr key={`${record.payer}-${record.merchant}-${record.timestamp}-${index}`}>
              <td>{shortAddress(record.payer)}</td>
              <td>{shortAddress(record.merchant)}</td>
              <td>{formatUnits(record.amount, 18)}</td>
              <td>{record.memo || "-"}</td>
              <td>{formatTime(record.timestamp)}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

function shortAddress(address: string) {
  return `${address.slice(0, 6)}...${address.slice(-4)}`;
}

function formatTime(timestamp: bigint) {
  const value = Number(timestamp);
  if (!Number.isFinite(value) || value === 0) return "-";
  return new Date(value * 1000).toLocaleString();
}
