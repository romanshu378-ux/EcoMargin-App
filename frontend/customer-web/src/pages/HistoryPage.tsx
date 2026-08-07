import React from 'react';
import { Download } from 'lucide-react';

export const HistoryPage: React.FC = () => {
  const sessions = [
    { id: 'SESS-9081', station: 'GreenCharge Hub Sector 62', kwh: '14.5 kWh', duration: '19 mins', cost: '₹261.00', date: '2026-08-07 15:30' },
    { id: 'SESS-9040', station: 'EcoFast Station Whitefield', kwh: '28.2 kWh', duration: '35 mins', cost: '₹507.60', date: '2026-08-04 11:15' },
    { id: 'SESS-8991', station: 'PowerGrid Hub Indiranagar', kwh: '18.0 kWh', duration: '45 mins', cost: '₹252.00', date: '2026-07-29 18:45' },
  ];

  return (
    <div className="space-y-6 max-w-5xl mx-auto py-8 px-4 sm:px-6">
      <div>
        <h1 className="text-2xl font-bold text-slate-900">Charging History & Receipts</h1>
        <p className="text-xs text-slate-500">View past charging sessions and download tax invoice receipts</p>
      </div>

      <div className="bg-white border border-slate-200 rounded-2xl overflow-x-auto shadow-sm">
        <table className="w-full text-left text-xs text-slate-700">
          <thead className="bg-slate-50 text-slate-500 font-semibold border-b border-slate-200 uppercase tracking-wider">
            <tr>
              <th className="p-4">Session Ref</th>
              <th className="p-4">Station</th>
              <th className="p-4">Energy</th>
              <th className="p-4">Duration</th>
              <th className="p-4">Total Paid</th>
              <th className="p-4">Date</th>
              <th className="p-4 text-right">Receipt</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-100">
            {sessions.map((s) => (
              <tr key={s.id} className="hover:bg-slate-50/80">
                <td className="p-4 font-mono font-bold text-slate-900">{s.id}</td>
                <td className="p-4 font-medium text-slate-800">{s.station}</td>
                <td className="p-4 font-bold text-emerald-600">{s.kwh}</td>
                <td className="p-4 text-slate-500">{s.duration}</td>
                <td className="p-4 font-bold text-slate-900 font-mono">{s.cost}</td>
                <td className="p-4 text-slate-500">{s.date}</td>
                <td className="p-4 text-right">
                  <button className="px-3 py-1 bg-slate-100 hover:bg-slate-200 text-slate-700 rounded-lg text-[11px] inline-flex items-center gap-1">
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
