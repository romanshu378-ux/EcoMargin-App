import React from 'react';
import { CreditCard, IndianRupee, ArrowUpRight, ArrowDownLeft } from 'lucide-react';

export const PaymentsPage: React.FC = () => {
  const txs = [
    { id: 'TX-901', type: 'WALLET_TOPUP', user: 'Alex Rivers', amount: '+₹5,000.00', gateway: 'Razorpay', status: 'SUCCESS', date: '2026-03-07 09:12' },
    { id: 'TX-902', type: 'CHARGING_DEBIT', user: 'Alex Rivers', amount: '-₹637.50', gateway: 'Internal Wallet', status: 'SUCCESS', date: '2026-03-07 10:14' },
    { id: 'TX-903', type: 'CPO_PAYOUT', user: 'ChargeTech Global', amount: '-₹4,50,000.00', gateway: 'Bank Wire', status: 'PROCESSING', date: '2026-03-06 16:00' },
  ];

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-xl font-bold text-white">Payment Ledger & Payouts</h1>
        <p className="text-xs text-slate-400">Gateway transactions, customer wallet top-ups, and CPO payouts</p>
      </div>

      <div className="bg-slate-900 border border-slate-800 rounded-xl overflow-hidden">
        <table className="w-full text-left text-xs text-slate-300">
          <thead className="bg-slate-950 text-slate-400 font-semibold border-b border-slate-800 uppercase tracking-wider">
            <tr>
              <th className="p-4">Transaction ID</th>
              <th className="p-4">Type</th>
              <th className="p-4">Account</th>
              <th className="p-4">Amount</th>
              <th className="p-4">Gateway</th>
              <th className="p-4">Status</th>
              <th className="p-4">Date</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-800">
            {txs.map((t) => (
              <tr key={t.id} className="hover:bg-slate-800/40">
                <td className="p-4 font-bold text-white font-mono">{t.id}</td>
                <td className="p-4">
                  <span className={`px-2 py-0.5 rounded text-[10px] font-bold ${
                    t.type === 'WALLET_TOPUP' ? 'bg-emerald-500/20 text-emerald-400' :
                    t.type === 'CHARGING_DEBIT' ? 'bg-blue-500/20 text-blue-400' : 'bg-purple-500/20 text-purple-400'
                  }`}>
                    {t.type}
                  </span>
                </td>
                <td className="p-4 text-slate-200">{t.user}</td>
                <td className={`p-4 font-bold font-mono ${t.amount.startsWith('+') ? 'text-emerald-400' : 'text-slate-100'}`}>{t.amount}</td>
                <td className="p-4 text-slate-400">{t.gateway}</td>
                <td className="p-4">
                  <span className={`px-2 py-0.5 rounded text-[10px] font-bold ${
                    t.status === 'SUCCESS' ? 'bg-emerald-500/20 text-emerald-400' : 'bg-amber-500/20 text-amber-400'
                  }`}>
                    {t.status}
                  </span>
                </td>
                <td className="p-4 text-slate-400">{t.date}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
};
