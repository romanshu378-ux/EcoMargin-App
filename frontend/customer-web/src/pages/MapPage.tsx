import React, { useState } from 'react';
import { MapPin, Search, Navigation } from 'lucide-react';

export const MapPage: React.FC = () => {
  const [selectedPlug, setSelectedPlug] = useState('ALL');
  const [searchQuery, setSearchQuery] = useState('');

  const stations = [
    { id: 'ST-001', name: 'GreenCharge Hub Sector 62', address: 'Tonk Road, Jaipur, Rajasthan', distance: '0.8 km', plugs: 'CCS2 • 60 kW DC', available: '4/6 Available', price: '₹12/kWh' },
    { id: 'ST-002', name: 'EcoFast Ultra Hub Whitefield', address: 'Malviya Nagar, Jaipur, Rajasthan', distance: '2.4 km', plugs: 'CCS2 / GB/T • 120 kW', available: '5/8 Available', price: '₹15/kWh' },
    { id: 'ST-003', name: 'PowerGrid Hub Indiranagar', address: 'MG Road, Jaipur, Rajasthan', distance: '4.1 km', plugs: 'Type 2 • 22 kW AC', available: '2/4 Available', price: '₹10/kWh' },
  ];

  const filtered = stations.filter(s =>
    s.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
    s.address.toLowerCase().includes(searchQuery.toLowerCase())
  );

  return (
    <div className="h-[calc(100vh-80px)] flex flex-col md:flex-row overflow-hidden bg-slate-50">
      {/* Sidebar Station Finder List */}
      <div className="w-full md:w-96 bg-white border-r border-slate-200 flex flex-col overflow-hidden">
        <div className="p-4 border-b border-slate-200 space-y-3">
          <h2 className="font-bold text-slate-900 text-base">Nearby Charging Hubs</h2>
          <div className="relative">
            <Search className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="Search by city or landmark..."
              className="w-full pl-9 pr-4 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs text-slate-900 focus:outline-none focus:border-emerald-500"
            />
          </div>
          <div className="flex gap-2">
            <select
              value={selectedPlug}
              onChange={(e) => setSelectedPlug(e.target.value)}
              className="w-full bg-slate-50 border border-slate-200 rounded-lg text-xs text-slate-700 px-3 py-1.5 focus:outline-none"
            >
              <option value="ALL">All Connectors</option>
              <option value="CCS2">DC Fast CCS2</option>
              <option value="TYPE2">AC Type 2</option>
            </select>
          </div>
        </div>

        <div className="flex-1 overflow-y-auto p-4 space-y-3">
          {filtered.map((s) => (
            <div key={s.id} className="p-4 bg-white border border-slate-200 hover:border-emerald-500/50 rounded-xl space-y-2 cursor-pointer transition-all shadow-sm">
              <div className="flex justify-between items-start">
                <div>
                  <h4 className="font-bold text-slate-900 text-sm">{s.name}</h4>
                  <p className="text-[11px] text-slate-500">{s.address}</p>
                </div>
                <span className="text-xs font-bold text-emerald-600">{s.distance}</span>
              </div>
              <div className="flex items-center justify-between text-[11px] pt-2 border-t border-slate-100">
                <span className="text-slate-600 font-medium">{s.plugs}</span>
                <span className="text-emerald-600 font-bold">{s.available}</span>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Interactive Map Visual Simulation */}
      <div className="flex-1 bg-slate-900 relative flex items-center justify-center p-8">
        <div className="absolute inset-0 bg-[radial-gradient(#334155_1px,transparent_1px)] [background-size:24px_24px] opacity-40"></div>
        <div className="relative z-10 text-center space-y-4 max-w-md">
          <div className="w-16 h-16 rounded-2xl bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 flex items-center justify-center mx-auto shadow-2xl">
            <MapPin className="w-8 h-8 animate-bounce text-emerald-500" />
          </div>
          <h3 className="text-xl font-bold text-white">Live EV Station Map</h3>
          <p className="text-xs text-slate-400 leading-relaxed">
            3 Charging Stations active near your position. Select a station to view live connector status & tariffs.
          </p>
        </div>
      </div>
    </div>
  );
};
