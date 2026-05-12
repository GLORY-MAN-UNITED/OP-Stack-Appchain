import { useState } from "react";
import { Search, Store } from "lucide-react";
import { isAddress } from "viem";
import { useReadContract } from "wagmi";
import {
  hasPaymentContract,
  paymentAbi,
  paymentContractAddress,
  type PaymentRecord,
} from "../config/contracts";
import { RecordTable } from "./TransactionHistory";

export function MerchantDashboard() {
  const [merchant, setMerchant] = useState("");
  const [searchedMerchant, setSearchedMerchant] = useState("");
  const canSearch = hasPaymentContract && isAddress(merchant);
  const canQuery = hasPaymentContract && isAddress(searchedMerchant);

  const { data, isLoading } = useReadContract({
    address: paymentContractAddress,
    abi: paymentAbi,
    functionName: "getMerchantPayments",
    args: canQuery ? [searchedMerchant] : undefined,
    query: { enabled: canQuery },
  });

  const records = (data ?? []) as PaymentRecord[];
  const total = records.reduce((sum, record) => sum + record.amount, 0n);

  function searchMerchant() {
    if (!canSearch) return;
    setSearchedMerchant(merchant);
  }

  return (
    <section className="panel">
      <div className="panel-heading">
        <Store size={18} />
        <h2>Merchant Dashboard</h2>
      </div>

      <label className="field">
        <span>Merchant address</span>
        <div className="search-row">
          <input
            value={merchant}
            onChange={(event) => setMerchant(event.target.value)}
            placeholder="0x..."
            spellCheck={false}
          />
          <button disabled={!canSearch} onClick={searchMerchant}>
            <Search size={16} />
            Search
          </button>
        </div>
      </label>

      <div className="metric-row">
        <div>
          <span>Total payments</span>
          <strong>{records.length}</strong>
        </div>
        <div>
          <span>Total raw amount</span>
          <strong>{total.toString()}</strong>
        </div>
      </div>

      <RecordTable
        records={records}
        emptyText={isLoading ? "Loading..." : "No merchant records found"}
      />
    </section>
  );
}
