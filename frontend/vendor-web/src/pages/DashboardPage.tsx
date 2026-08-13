import React from 'react';
import { Zap, IndianRupee, MapPin, Activity, ArrowUpRight, Wallet } from 'lucide-react';

export const DashboardPage: React.FC = () => {
  const stats = [
    { label: "Today's Revenue", value: '₹1,48,050.00', change: '+12.5%', icon: IndianRupee },
    { label: 'Active Chargers', value: '42 / 48 Online', change: '87.5% Uptime', icon: Zap },
    { label: 'Charging Stations', value: '14 Active', change: '3 Hub Locations', icon: MapPin },
    { label: 'Vendor Wallet', value: '₹18,45,000.00', change: 'Available for Payout', icon: Wallet },
  ];

  return (
    <div className="space-y-8">
      {/* Top Banner */}
      <div className="flex justify-between items-center bg-gradient-to-r from-amber-950/60 to-slate-900 border border-amber-500/20 rounded-2xl p-6">
        <div>
          <h1 className="text-2xl font-bold text-white">ChargeTech CPO Operational Dashboard</h1>
          <p className="text-sm text-slate-400 mt-1">Real-time status of your charging network</p>
        </div>
        <div className="flex items-center gap-3">
          <span className="flex items-center gap-2 text-xs font-semibold px-3 py-1.5 rounded-lg bg-amber-500/20 text-amber-400 border border-amber-500/30">
            <Activity className="w-4 h-4 animate-pulse" /> Live Telemetry
          </span>
        </div>
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        {stats.map((stat, idx) => {
          const Icon = stat.icon;
          return (
            <div key={idx} className="bg-slate-900 border border-slate-800 rounded-2xl p-5 hover:border-slate-700 transition-all">
              <div className="flex items-center justify-between text-slate-400 mb-3">
                <span className="text-xs font-medium">{stat.label}</span>
                <Icon className="w-5 h-5 text-amber-400" />
              </div>
              <p className="text-2xl font-bold text-white">{stat.value}</p>
              <div className="flex items-center gap-1 mt-2 text-xs text-amber-400 font-medium">
                <ArrowUpRight className="w-3.5 h-3.5" />
                <span>{stat.change}</span>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
};
