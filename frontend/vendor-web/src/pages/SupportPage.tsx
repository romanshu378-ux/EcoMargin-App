import React from 'react';
import { LifeBuoy, MessageSquare, CheckCircle, Clock } from 'lucide-react';

export const SupportPage: React.FC = () => {
  const tickets = [
    { id: 'TCK-401', subject: 'Charger SF-HUB-01 Connector 2 Latch Jammed', station: 'Downtown Hub', priority: 'HIGH', status: 'IN_PROGRESS', date: '2026-03-07' },
    { id: 'TCK-402', subject: 'Display screen backlight flicker', station: 'Westfield Mall Hub', priority: 'LOW', status: 'OPEN', date: '2026-03-06' },
  ];

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-xl font-bold text-white">Vendor Technical Support</h1>
        <p className="text-xs text-slate-400">Manage hardware maintenance tickets and customer inquiries</p>
      </div>

      <div className="bg-slate-900 border border-slate-800 rounded-xl overflow-hidden">
        <table className="w-full text-left text-xs text-slate-300">
          <thead className="bg-slate-950 text-slate-400 font-semibold border-b border-slate-800 uppercase tracking-wider">
            <tr>
              <th className="p-4">Ticket ID</th>
              <th className="p-4">Subject</th>
              <th className="p-4">Station Location</th>
              <th className="p-4">Priority</th>
              <th className="p-4">Status</th>
              <th className="p-4">Date Reported</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-800">
            {tickets.map((t) => (
              <tr key={t.id} className="hover:bg-slate-800/40">
                <td className="p-4 font-bold text-white font-mono">{t.id}</td>
                <td className="p-4 font-semibold text-slate-200">{t.subject}</td>
                <td className="p-4 text-slate-400">{t.station}</td>
                <td className="p-4 font-bold text-rose-400">{t.priority}</td>
                <td className="p-4">
                  <span className={`px-2 py-0.5 rounded text-[10px] font-bold ${
                    t.status === 'IN_PROGRESS' ? 'bg-amber-500/20 text-amber-400' : 'bg-blue-500/20 text-blue-400'
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
