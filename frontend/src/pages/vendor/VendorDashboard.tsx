import React from 'react';
import { DollarSign, Zap, Clock, Radio, ArrowUpRight, ArrowDownRight, RefreshCcw } from 'lucide-react';

const stats = [
  { label: 'Today Revenue', value: '$840.00', change: '+8.1%', trend: 'up', icon: DollarSign },
  { label: 'Energy Transferred', value: '1.2 MWh', change: '+12.4%', trend: 'up', icon: Zap },
  { label: 'Avg Session Duration', value: '45 mins', change: '-4.2%', trend: 'down', icon: Clock },
  { label: 'Online Chargers', value: '3 / 3 Active', change: '100%', trend: 'up', icon: Radio },
];

const mockSessions = [
  { id: 'SESS-203', charger: 'TX_AUS_DWTN_01', connector: 'CCS2 (1)', user: 'Jane Driver', energy: '24.2 kWh', cost: '$8.47', status: 'Charging' },
  { id: 'SESS-202', charger: 'TX_AUS_DWTN_02', connector: 'CCS2 (1)', user: 'John Driver', energy: '48.9 kWh', cost: '$17.11', status: 'Completed' },
];

export default function VendorDashboard() {
  return (
    <div className="space-y-6">
      
      {/* Stats Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {stats.map((s, idx) => {
          const Icon = s.icon;
          return (
            <div key={idx} className="bg-white dark:bg-gray-900 p-6 rounded-2xl border border-gray-200 dark:border-gray-800 shadow-sm flex items-center justify-between">
              <div className="space-y-2">
                <span className="text-xs font-semibold text-gray-400">{s.label}</span>
                <p className="text-2xl font-bold">{s.value}</p>
                <div className="flex items-center gap-1 text-[10px]">
                  {s.trend === 'up' ? (
                    <span className="text-emerald-500 font-bold flex items-center"><ArrowUpRight size={12} /> {s.change}</span>
                  ) : (
                    <span className="text-rose-500 font-bold flex items-center"><ArrowDownRight size={12} /> {s.change}</span>
                  )}
                  <span className="text-gray-400">vs yesterday</span>
                </div>
              </div>
              <div className="p-4 bg-emerald-50 dark:bg-emerald-950/30 text-emerald-600 dark:text-emerald-400 rounded-xl">
                <Icon size={22} />
              </div>
            </div>
          );
        })}
      </div>

      {/* Grid: SVG chart & recent sessions */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        
        {/* Custom CPO Revenue Chart */}
        <div className="bg-white dark:bg-gray-900 p-6 rounded-2xl border border-gray-200 dark:border-gray-800 lg:col-span-2 space-y-4">
          <div className="flex justify-between items-center">
            <span className="font-bold text-sm tracking-wide">Daily CPO Revenue Trends</span>
            <span className="text-[10px] text-gray-400">Last 7 Days</span>
          </div>

          <div className="h-60 w-full flex items-end justify-between pt-4 relative">
            <div className="absolute inset-x-0 top-1/3 border-b border-gray-100 dark:border-gray-800/80"></div>
            <div className="absolute inset-x-0 top-2/3 border-b border-gray-100 dark:border-gray-800/80"></div>

            {/* Custom SVG Bar Chart */}
            <svg className="absolute inset-0 h-full w-full" preserveAspectRatio="none" viewBox="0 0 100 100">
              <rect x="5" y="40" width="8" height="60" rx="2" fill="#10b981" />
              <rect x="18" y="30" width="8" height="70" rx="2" fill="#10b981" />
              <rect x="31" y="55" width="8" height="45" rx="2" fill="#10b981" />
              <rect x="44" y="25" width="8" height="75" rx="2" fill="#10b981" />
              <rect x="57" y="50" width="8" height="50" rx="2" fill="#10b981" />
              <rect x="70" y="35" width="8" height="65" rx="2" fill="#10b981" />
              <rect x="83" y="15" width="8" height="85" rx="2" fill="#10b981" />
            </svg>

            {/* Day Labels */}
            <div className="absolute bottom-0 inset-x-0 flex justify-between text-[10px] text-gray-400 pt-1 px-2">
              <span>Mon</span>
              <span>Tue</span>
              <span>Wed</span>
              <span>Thu</span>
              <span>Fri</span>
              <span>Sat</span>
              <span>Sun</span>
            </div>
          </div>
        </div>

        {/* Live Active Sessions */}
        <div className="bg-white dark:bg-gray-900 p-6 rounded-2xl border border-gray-200 dark:border-gray-800 space-y-4">
          <span className="font-bold text-sm tracking-wide">Live Sessions</span>
          <div className="space-y-4">
            {mockSessions.map(session => (
              <div key={session.id} className="p-3 bg-gray-50 dark:bg-gray-800/30 border border-gray-150 dark:border-gray-800 rounded-xl space-y-2 text-xs">
                <div className="flex items-center justify-between font-semibold border-b border-gray-100 dark:border-gray-800/80 pb-2">
                  <span className="text-gray-700 dark:text-gray-300">{session.charger}</span>
                  <span className={`px-2 py-0.5 rounded text-[9px] font-bold ${
                    session.status === 'Charging' 
                      ? 'bg-emerald-100 text-emerald-800 animate-pulse' 
                      : 'bg-gray-100 text-gray-800'
                  }`}>
                    {session.status}
                  </span>
                </div>
                <div className="grid grid-cols-2 gap-2 text-[10px]">
                  <div>
                    <p className="text-gray-400">Driver</p>
                    <p className="font-semibold">{session.user}</p>
                  </div>
                  <div>
                    <p className="text-gray-400">Delivered</p>
                    <p className="font-semibold">{session.energy}</p>
                  </div>
                  <div>
                    <p className="text-gray-400">Revenue</p>
                    <p className="font-semibold text-emerald-500">{session.cost}</p>
                  </div>
                  <div>
                    <p className="text-gray-400">Connector</p>
                    <p className="font-semibold">{session.connector}</p>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>

      </div>

    </div>
  );
}
