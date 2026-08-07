import React from 'react';
import { Receipt, DollarSign } from 'lucide-react';

export const TransactionsPage: React.FC = () => {
  const txs = [
    { id: 'TX-V901', session: 'SESS-9081', kwh: '42.5 kWh', gross: '$18.70', commission: '-$1.87', net: '$16.83', date: '2026-03-07 10:14' },
    { id: 'TX-V902', session: 'SESS-9079', kwh: '18.4 kWh', gross: '$8.10', commission: '-$0.81', net: '$7.29', date: '2026-03-07 11:02' },
  ];

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-xl font-bold text-white">Vendor Session Transactions</h1>
        <p className="text-xs text-slate-400">Gross revenue, platform commission deduction, and net earnings per session</p>
      </div>

      <div className="bg-slate-900 border border-slate-800 rounded-xl overflow-hidden">
        <table className="w-full text-left text-xs text-slate-300">
          <thead className="bg-slate-950 text-slate-400 font-semibold border-b border-slate-800 uppercase tracking-wider">
            <tr>
              <th className="p-4">Transaction ID</th>
              <th className="p-4">Session Reference</th>
              <th className="p-4">Energy (kWh)</th>
              <th className="p-4">Gross Charge</th>
              <th className="p-4">Commission (10%)</th>
              <th className="p-4">Net Vendor Revenue</th>
              <th className="p-4">Date</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-800">
            {txs.map((t) => (
              <tr key={t.id} className="hover:bg-slate-800/40">
                <td className="p-4 font-bold text-white font-mono">{t.id}</td>
                <td className="p-4 text-slate-400 font-mono">{t.session}</td>
                <td className="p-4">{t.kwh}</td>
                <td className="p-4 font-medium text-slate-200">{t.gross}</td>
                <td className="p-4 text-rose-400">{t.commission}</td>
                <td className="p-4 font-bold text-amber-400 font-mono">{t.net}</td>
                <td className="p-4 text-slate-400">{t.date}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
};
