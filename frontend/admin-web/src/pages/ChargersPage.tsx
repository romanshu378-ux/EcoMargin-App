import React from 'react';
import { Zap, Activity, AlertTriangle, CheckCircle, RefreshCw } from 'lucide-react';

export const ChargersPage: React.FC = () => {
  const chargers = [
    { id: 'CHG-9001', ocppId: 'SF-HUB-01', type: 'DC Fast (CCS2)', power: '150 kW', status: 'CHARGING', station: 'Downtown Hub Fast Charge' },
    { id: 'CHG-9002', ocppId: 'SF-HUB-02', type: 'DC Fast (CCS2)', power: '150 kW', status: 'AVAILABLE', station: 'Downtown Hub Fast Charge' },
    { id: 'CHG-9003', ocppId: 'SJO-AIR-01', type: 'Ultra Fast (CCS2/CHAdeMO)', power: '350 kW', status: 'CHARGING', station: 'Metro Airport Charging Hub' },
    { id: 'CHG-9004', ocppId: 'PA-TECH-01', type: 'AC Type 2', power: '22 kW', status: 'FAULTED', station: 'Silicon Valley Tech Park' },
  ];

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-xl font-bold text-white">OCPP Charger Infrastructure</h1>
          <p className="text-xs text-slate-400">Live telemetry and connector status tracking across CPO fleet</p>
        </div>
      </div>

      <div className="bg-slate-900 border border-slate-800 rounded-xl overflow-hidden">
        <table className="w-full text-left text-xs text-slate-300">
          <thead className="bg-slate-950 text-slate-400 font-semibold border-b border-slate-800 uppercase tracking-wider">
            <tr>
              <th className="p-4">Charger & OCPP ID</th>
              <th className="p-4">Plug Type</th>
              <th className="p-4">Power Rating</th>
              <th className="p-4">Station</th>
              <th className="p-4">Status</th>
              <th className="p-4 text-right">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-800">
            {chargers.map((c) => (
              <tr key={c.id} className="hover:bg-slate-800/40">
                <td className="p-4">
                  <p className="font-semibold text-white">{c.id}</p>
                  <p className="text-[11px] font-mono text-slate-400">{c.ocppId}</p>
                </td>
                <td className="p-4 text-slate-300 font-medium">{c.type}</td>
                <td className="p-4 font-bold text-emerald-400">{c.power}</td>
                <td className="p-4 text-slate-400">{c.station}</td>
                <td className="p-4">
                  <span className={`px-2.5 py-1 rounded-md text-[10px] font-bold ${
                    c.status === 'AVAILABLE' ? 'bg-emerald-500/20 text-emerald-400' :
                    c.status === 'CHARGING' ? 'bg-blue-500/20 text-blue-400' : 'bg-rose-500/20 text-rose-400'
                  }`}>
                    {c.status}
                  </span>
                </td>
                <td className="p-4 text-right space-x-2">
                  <button className="px-3 py-1 bg-slate-800 hover:bg-slate-700 text-slate-200 rounded-lg text-[11px]">
                    Reset OCPP
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
