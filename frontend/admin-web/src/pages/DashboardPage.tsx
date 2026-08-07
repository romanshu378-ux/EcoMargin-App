import React from 'react';
import { Users, Building2, MapPin, Zap, DollarSign, Activity, TrendingUp } from 'lucide-react';

export const DashboardPage: React.FC = () => {
  const stats = [
    { label: 'Total Platform Revenue', value: '$128,450.00', change: '+14.2%', icon: DollarSign, color: 'emerald' },
    { label: 'Active Drivers', value: '4,892', change: '+8.1%', icon: Users, color: 'blue' },
    { label: 'CPO Vendors', value: '38', change: '+3', icon: Building2, color: 'purple' },
    { label: 'Charging Stations', value: '142', change: '+12', icon: MapPin, color: 'amber' },
    { label: 'Active Sessions', value: '89 Live', change: '1.4 MW Output', icon: Zap, color: 'rose' },
  ];

  return (
    <div className="space-y-8">
      {/* Top Banner */}
      <div className="flex justify-between items-center bg-gradient-to-r from-emerald-950/60 to-slate-900 border border-emerald-500/20 rounded-2xl p-6">
        <div>
          <h1 className="text-2xl font-bold text-white">System Operations Overview</h1>
          <p className="text-sm text-slate-400 mt-1">Real-time status monitor for EcoMargin CPO Network</p>
        </div>
        <div className="flex items-center gap-3">
          <span className="flex items-center gap-2 text-xs font-semibold px-3 py-1.5 rounded-lg bg-emerald-500/20 text-emerald-400 border border-emerald-500/30">
            <Activity className="w-4 h-4 animate-spin" /> Live OCPP 1.6/2.0 WebSocket Online
          </span>
        </div>
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 lg:grid-cols-5 gap-4">
        {stats.map((stat, idx) => {
          const Icon = stat.icon;
          return (
            <div key={idx} className="bg-slate-900 border border-slate-800 rounded-2xl p-5 hover:border-slate-700 transition-all">
              <div className="flex items-center justify-between text-slate-400 mb-3">
                <span className="text-xs font-medium">{stat.label}</span>
                <Icon className="w-5 h-5 text-emerald-400" />
              </div>
              <p className="text-2xl font-bold text-white">{stat.value}</p>
              <div className="flex items-center gap-1 mt-2 text-xs text-emerald-400 font-medium">
                <TrendingUp className="w-3.5 h-3.5" />
                <span>{stat.change}</span>
              </div>
            </div>
          );
        })}
      </div>

      {/* Analytics Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Network Power Demand */}
        <div className="bg-slate-900 border border-slate-800 rounded-2xl p-6">
          <h3 className="font-semibold text-white mb-4">Live Power Demand (kW)</h3>
          <div className="h-64 flex items-end justify-between gap-2 pt-8">
            {[40, 65, 80, 55, 90, 110, 95, 120, 140, 130, 160, 175, 150].map((h, i) => (
              <div key={i} className="flex-1 flex flex-col items-center gap-2">
                <div 
                  className="w-full bg-emerald-500/80 hover:bg-emerald-400 transition-all rounded-t-sm" 
                  style={{ height: `${(h / 200) * 100}%` }}
                />
                <span className="text-[10px] text-slate-500">{i * 2}:00</span>
              </div>
            ))}
          </div>
        </div>

        {/* Live Session Feed */}
        <div className="bg-slate-900 border border-slate-800 rounded-2xl p-6">
          <h3 className="font-semibold text-white mb-4">Recent Charging Sessions</h3>
          <div className="space-y-3">
            {[
              { id: 'SESS-9081', user: 'Alex Rivers', station: 'EcoCharge Downtown Hub', kwh: '42.5 kWh', cost: '$18.70', status: 'Charging' },
              { id: 'SESS-9080', user: 'Sarah Jenkins', station: 'Metro Express Charging', kwh: '68.1 kWh', cost: '$29.96', status: 'Completed' },
              { id: 'SESS-9079', user: 'David Kim', station: 'GreenPark Station B2', kwh: '18.4 kWh', cost: '$8.10', status: 'Charging' },
              { id: 'SESS-9078', user: 'Emily Vance', station: 'Airport Fast Charger #4', kwh: '55.0 kWh', cost: '$24.20', status: 'Completed' },
            ].map((sess) => (
              <div key={sess.id} className="flex items-center justify-between p-3.5 bg-slate-950/60 rounded-xl border border-slate-800/80 text-xs">
                <div>
                  <p className="font-semibold text-white">{sess.user} <span className="text-slate-500">({sess.id})</span></p>
                  <p className="text-slate-400">{sess.station}</p>
                </div>
                <div className="text-right">
                  <p className="font-bold text-emerald-400">{sess.cost}</p>
                  <p className="text-slate-400">{sess.kwh}</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
};
