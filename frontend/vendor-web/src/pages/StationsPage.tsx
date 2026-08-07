import React from 'react';
import { MapPin, Plus, Zap, Navigation } from 'lucide-react';

export const StationsPage: React.FC = () => {
  const stations = [
    { id: 'ST-001', name: 'Downtown Hub Fast Charge', address: '100 Market St, San Francisco, CA', chargers: 8, status: 'OPERATIONAL' },
    { id: 'ST-002', name: 'Westfield Mall EV Plaza', address: '865 Market St, San Francisco, CA', chargers: 4, status: 'OPERATIONAL' },
  ];

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-xl font-bold text-white">Vendor Station Locations</h1>
          <p className="text-xs text-slate-400">Manage CPO charging hubs and physical property setup</p>
        </div>
        <button className="flex items-center gap-2 px-4 py-2 bg-amber-500 hover:bg-amber-600 font-semibold text-white rounded-xl text-xs transition-all shadow-lg shadow-amber-500/20">
          <Plus className="w-4 h-4" /> Add New Hub
        </button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {stations.map((s) => (
          <div key={s.id} className="bg-slate-900 border border-slate-800 rounded-2xl p-5 space-y-3">
            <div className="flex justify-between items-start">
              <div>
                <span className="text-[10px] font-mono text-amber-400 font-bold">{s.id}</span>
                <h3 className="font-bold text-white text-base">{s.name}</h3>
                <p className="text-xs text-slate-400">{s.address}</p>
              </div>
              <span className="px-2 py-0.5 rounded text-[10px] font-bold bg-emerald-500/20 text-emerald-400">
                {s.status}
              </span>
            </div>

            <div className="bg-slate-950 p-3 rounded-xl flex items-center justify-between text-xs">
              <span className="text-slate-400">Plug Points</span>
              <span className="font-bold text-white">{s.chargers} Chargers Installed</span>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};
