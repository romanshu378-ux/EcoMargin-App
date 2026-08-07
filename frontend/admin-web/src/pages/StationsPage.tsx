import React from 'react';
import { MapPin, Zap, Power, Navigation, Plus } from 'lucide-react';

export const StationsPage: React.FC = () => {
  const stations = [
    { id: 'ST-001', name: 'Downtown Hub Fast Charge', vendor: 'ChargeTech Global', city: 'San Francisco, CA', ports: 8, power: '150 kW', status: 'ACTIVE' },
    { id: 'ST-002', name: 'Metro Airport Charging Hub', vendor: 'GreenPower Networks', city: 'San Jose, CA', ports: 12, power: '350 kW', status: 'ACTIVE' },
    { id: 'ST-003', name: 'Silicon Valley Tech Park', vendor: 'ChargeTech Global', city: 'Palo Alto, CA', ports: 6, power: '60 kW', status: 'MAINTENANCE' },
  ];

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-xl font-bold text-white">Charging Station Directory</h1>
          <p className="text-xs text-slate-400">Network-wide charging hubs and operational status</p>
        </div>
        <button className="flex items-center gap-2 px-4 py-2.5 bg-emerald-500 hover:bg-emerald-600 font-semibold text-white text-xs rounded-xl transition-all shadow-lg shadow-emerald-500/20">
          <Plus className="w-4 h-4" /> Add Station
        </button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        {stations.map((s) => (
          <div key={s.id} className="bg-slate-900 border border-slate-800 rounded-2xl p-5 space-y-4">
            <div className="flex justify-between items-start">
              <div>
                <span className="text-[10px] font-mono font-bold text-emerald-400">{s.id}</span>
                <h3 className="font-bold text-white text-base">{s.name}</h3>
                <p className="text-xs text-slate-400">{s.vendor}</p>
              </div>
              <span className={`px-2 py-0.5 rounded text-[10px] font-bold ${
                s.status === 'ACTIVE' ? 'bg-emerald-500/20 text-emerald-400' : 'bg-amber-500/20 text-amber-400'
              }`}>
                {s.status}
              </span>
            </div>

            <div className="flex items-center gap-2 text-xs text-slate-400">
              <Navigation className="w-4 h-4 text-slate-500" />
              <span>{s.city}</span>
            </div>

            <div className="grid grid-cols-2 gap-2 bg-slate-950 p-3 rounded-xl text-xs">
              <div>
                <p className="text-slate-500 text-[10px]">Connectors</p>
                <p className="font-bold text-white">{s.ports} Plug Points</p>
              </div>
              <div>
                <p className="text-slate-500 text-[10px]">Max Power</p>
                <p className="font-bold text-emerald-400">{s.power}</p>
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};
