import React from 'react';
import { ShoppingBag, Clock, CheckCircle2, Zap } from 'lucide-react';

export const OrdersPage: React.FC = () => {
  const orders = [
    { id: 'ORD-8801', user: 'Alex Rivers', station: 'Downtown Hub Fast Charge', duration: '45 mins', kwh: '42.5 kWh', total: '$18.70', status: 'COMPLETED', time: '2026-03-07 10:14' },
    { id: 'ORD-8802', user: 'Sarah Jenkins', station: 'Metro Airport Hub', duration: '58 mins', kwh: '68.1 kWh', total: '$29.96', status: 'COMPLETED', time: '2026-03-07 09:30' },
    { id: 'ORD-8803', user: 'David Kim', station: 'Silicon Valley Tech Park', duration: '22 mins', kwh: '18.4 kWh', total: '$8.10', status: 'IN_PROGRESS', time: '2026-03-07 11:02' },
  ];

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-xl font-bold text-white">Charging Session Orders</h1>
        <p className="text-xs text-slate-400">Complete historical and real-time charging session transactions</p>
      </div>

      <div className="bg-slate-900 border border-slate-800 rounded-xl overflow-hidden">
        <table className="w-full text-left text-xs text-slate-300">
          <thead className="bg-slate-950 text-slate-400 font-semibold border-b border-slate-800 uppercase tracking-wider">
            <tr>
              <th className="p-4">Order ID</th>
              <th className="p-4">Customer</th>
              <th className="p-4">Station</th>
              <th className="p-4">Energy / Duration</th>
              <th className="p-4">Amount</th>
              <th className="p-4">Status</th>
              <th className="p-4">Time</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-800">
            {orders.map((o) => (
              <tr key={o.id} className="hover:bg-slate-800/40">
                <td className="p-4 font-bold text-white font-mono">{o.id}</td>
                <td className="p-4 text-slate-200">{o.user}</td>
                <td className="p-4 text-slate-400">{o.station}</td>
                <td className="p-4">{o.kwh} ({o.duration})</td>
                <td className="p-4 font-bold text-emerald-400">{o.total}</td>
                <td className="p-4">
                  <span className={`px-2 py-1 rounded text-[10px] font-bold ${
                    o.status === 'COMPLETED' ? 'bg-emerald-500/20 text-emerald-400' : 'bg-blue-500/20 text-blue-400 animate-pulse'
                  }`}>
                    {o.status}
                  </span>
                </td>
                <td className="p-4 text-slate-400">{o.time}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
};
