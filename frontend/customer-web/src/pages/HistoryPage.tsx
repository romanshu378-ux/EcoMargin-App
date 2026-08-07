import React from 'react';
import { History, Zap, Download } from 'lucide-react';

export const HistoryPage: React.FC = () => {
  const sessions = [
    { id: 'SESS-9081', station: 'Downtown Hub Fast Charge', kwh: '42.5 kWh', duration: '45 mins', cost: '$18.70', date: '2026-03-07 10:14' },
    { id: 'SESS-9040', station: 'Metro Airport Hub', kwh: '68.1 kWh', duration: '58 mins', cost: '$29.96', date: '2026-03-02 14:22' },
  ];

  return (
    <div className="space-y-6 max-w-5xl mx-auto py-8 px-4">
      <div>
        <h1 className="text-2xl font-bold text-white">Charging Session Receipts</h1>
        <p className="text-xs text-slate-400">View past charging sessions and download PDF invoices</p>
      </div>

      <div className="bg-slate-900 border border-slate-800 rounded-2xl overflow-hidden">
        <table className="w-full text-left text-xs text-slate-300">
          <thead className="bg-slate-950 text-slate-400 font-semibold border-b border-slate-800 uppercase tracking-wider">
            <tr>
              <th className="p-4">Session Reference</th>
              <th className="p-4">Station</th>
              <th className="p-4">Energy Consumed</th>
              <th className="p-4">Duration</th>
              <th className="p-4">Total Paid</th>
              <th className="p-4">Date</th>
              <th className="p-4 text-right">Receipt</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-800">
            {sessions.map((s) => (
              <tr key={s.id} className="hover:bg-slate-800/40">
                <td className="p-4 font-mono font-bold text-white">{s.id}</td>
                <td className="p-4 text-slate-200">{s.station}</td>
                <td className="p-4 font-medium text-emerald-400">{s.kwh}</td>
                <td className="p-4 text-slate-400">{s.duration}</td>
                <td className="p-4 font-bold text-white font-mono">{s.cost}</td>
                <td className="p-4 text-slate-400">{s.date}</td>
                <td className="p-4 text-right">
                  <button className="px-3 py-1 bg-slate-800 hover:bg-slate-700 text-slate-200 rounded-lg text-[11px] inline-flex items-center gap-1">
                    <Download className="w-3 h-3" /> PDF
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
};
