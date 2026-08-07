import React from 'react';
import { Zap, Play, Square, AlertCircle } from 'lucide-react';

export const ChargersPage: React.FC = () => {
  const chargers = [
    { id: 'CHG-9001', ocppId: 'SF-HUB-01', type: 'DC Fast (CCS2)', power: '150 kW', status: 'CHARGING', station: 'Downtown Hub' },
    { id: 'CHG-9002', ocppId: 'SF-HUB-02', type: 'DC Fast (CCS2)', power: '150 kW', status: 'AVAILABLE', station: 'Downtown Hub' },
    { id: 'CHG-9003', ocppId: 'SF-HUB-03', type: 'AC Type 2', power: '22 kW', status: 'AVAILABLE', station: 'Downtown Hub' },
  ];

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-xl font-bold text-white">Managed Chargers & Remote Control</h1>
          <p className="text-xs text-slate-400">Execute Remote Start / Stop OCPP commands</p>
        </div>
      </div>

      <div className="bg-slate-900 border border-slate-800 rounded-xl overflow-hidden">
        <table className="w-full text-left text-xs text-slate-300">
          <thead className="bg-slate-950 text-slate-400 font-semibold border-b border-slate-800 uppercase tracking-wider">
            <tr>
              <th className="p-4">Charger ID</th>
              <th className="p-4">OCPP Identity</th>
              <th className="p-4">Plug Type</th>
              <th className="p-4">Power</th>
              <th className="p-4">Status</th>
              <th className="p-4 text-right">Remote Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-800">
            {chargers.map((c) => (
              <tr key={c.id} className="hover:bg-slate-800/40">
                <td className="p-4 font-bold text-white">{c.id}</td>
                <td className="p-4 font-mono text-slate-400">{c.ocppId}</td>
                <td className="p-4 text-slate-200">{c.type}</td>
                <td className="p-4 font-bold text-amber-400">{c.power}</td>
                <td className="p-4">
                  <span className={`px-2 py-1 rounded text-[10px] font-bold ${
                    c.status === 'AVAILABLE' ? 'bg-emerald-500/20 text-emerald-400' : 'bg-blue-500/20 text-blue-400'
                  }`}>
                    {c.status}
                  </span>
                </td>
                <td className="p-4 text-right space-x-2">
                  <button className="px-3 py-1 bg-emerald-500/10 hover:bg-emerald-500/20 text-emerald-400 border border-emerald-500/20 rounded-lg text-[11px] inline-flex items-center gap-1">
                    <Play className="w-3 h-3" /> Start
                  </button>
                  <button className="px-3 py-1 bg-rose-500/10 hover:bg-rose-500/20 text-rose-400 border border-rose-500/20 rounded-lg text-[11px] inline-flex items-center gap-1">
                    <Square className="w-3 h-3" /> Stop
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
