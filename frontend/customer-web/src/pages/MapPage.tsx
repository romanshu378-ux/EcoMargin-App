import React, { useState } from 'react';
import { MapPin, Zap, Filter, Navigation, Search } from 'lucide-react';

export const MapPage: React.FC = () => {
  const [selectedPlug, setSelectedPlug] = useState('ALL');

  const stations = [
    { id: 'ST-001', name: 'Downtown Hub Fast Charge', address: '100 Market St, San Francisco', distance: '0.8 mi', plugs: 'CCS2 • 150 kW', available: '6/8 Free', price: '$0.44/kWh' },
    { id: 'ST-002', name: 'Metro Airport Charging Hub', address: '865 Market St, San Francisco', distance: '2.4 mi', plugs: 'CCS2 / CHAdeMO • 350 kW', available: '10/12 Free', price: '$0.48/kWh' },
    { id: 'ST-003', name: 'Silicon Valley Tech Park', address: '3000 El Camino, Palo Alto', distance: '14.2 mi', plugs: 'Type 2 • 22 kW', available: '2/6 Free', price: '$0.32/kWh' },
  ];

  return (
    <div className="h-[calc(100vh-80px)] flex flex-col md:flex-row overflow-hidden">
      {/* Sidebar Station Finder List */}
      <div className="w-full md:w-96 bg-slate-900 border-r border-slate-800 flex flex-col overflow-hidden">
        <div className="p-4 border-b border-slate-800 space-y-3">
          <h2 className="font-bold text-white text-base">Nearby Charging Hubs</h2>
          <div className="relative">
            <Search className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-slate-500" />
            <input
              type="text"
              placeholder="Search by city or landmark..."
              className="w-full pl-9 pr-4 py-2 bg-slate-950 border border-slate-800 rounded-xl text-xs text-slate-100 focus:outline-none focus:border-emerald-500"
            />
          </div>
          <div className="flex gap-2">
            <select
              value={selectedPlug}
              onChange={(e) => setSelectedPlug(e.target.value)}
              className="w-full bg-slate-950 border border-slate-800 rounded-lg text-xs text-slate-300 px-3 py-1.5 focus:outline-none"
            >
              <option value="ALL">All Connectors</option>
              <option value="CCS2">DC Fast CCS2</option>
              <option value="TYPE2">AC Type 2</option>
            </select>
          </div>
        </div>

        <div className="flex-1 overflow-y-auto p-4 space-y-3">
          {stations.map((s) => (
            <div key={s.id} className="p-4 bg-slate-950/80 border border-slate-800/80 hover:border-emerald-500/50 rounded-xl space-y-2 cursor-pointer transition-all">
              <div className="flex justify-between items-start">
                <div>
                  <h4 className="font-bold text-white text-sm">{s.name}</h4>
                  <p className="text-[11px] text-slate-400">{s.address}</p>
                </div>
                <span className="text-xs font-bold text-emerald-400">{s.distance}</span>
              </div>
              <div className="flex items-center justify-between text-[11px] pt-1 border-t border-slate-800/60">
                <span className="text-slate-300 font-medium">{s.plugs}</span>
                <span className="text-emerald-400 font-bold">{s.available}</span>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Interactive Map Visual Simulation */}
      <div className="flex-1 bg-slate-950 relative flex items-center justify-center p-8">
        <div className="absolute inset-0 bg-[radial-gradient(#1e293b_1px,transparent_1px)] [background-size:24px_24px] opacity-40"></div>
        <div className="relative z-10 text-center space-y-4 max-w-md">
          <div className="w-16 h-16 rounded-2xl bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 flex items-center justify-center mx-auto shadow-2xl">
            <MapPin className="w-8 h-8 animate-bounce" />
          </div>
          <h3 className="text-xl font-bold text-white">Interactive Map Ready</h3>
          <p className="text-xs text-slate-400 leading-relaxed">
            3 Charging Stations active in your viewport. Click any station pin on the left to start a charging session.
          </p>
        </div>
      </div>
    </div>
  );
};
