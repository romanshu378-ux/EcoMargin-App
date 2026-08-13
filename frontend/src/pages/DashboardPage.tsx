import React from 'react';
import { 
  IndianRupee, Activity, Battery, Radio, ArrowUpRight, ArrowDownRight, 
  MapPin, CheckCircle, AlertTriangle 
} from 'lucide-react';

const stats = [
  { label: 'Weekly Revenue', value: '₹12,48,520.00', change: '+14.2%', trend: 'up', icon: IndianRupee },
  { label: 'Active Sessions', value: '42 Charging', change: '+8.3%', trend: 'up', icon: Activity },
  { label: 'Network Power', value: '380.5 kW', change: '-2.1%', trend: 'down', icon: Battery },
  { label: 'Active Chargers', value: '18 / 20 Online', change: '90%', trend: 'up', icon: Radio },
];

const mockLogs = [
  { id: '1', charger: 'TX_AUS_DWTN_01', event: 'BootNotification received', status: 'Accepted', time: '10s ago' },
  { id: '2', charger: 'TX_AUS_DWTN_02', event: 'RemoteStart triggered', status: 'Pending', time: '1m ago' },
  { id: '3', charger: 'TX_AUS_NL_01', event: 'MeterValues report (24.2 kWh)', status: 'Success', time: '2m ago' },
  { id: '4', charger: 'TX_AUS_DWTN_01', event: 'StatusNotification (Faulted)', status: 'Warning', time: '5m ago' },
];

const topStations = [
  { name: 'Austin Downtown Hub', activeTx: 6, usage: 88, status: 'Optimal' },
  { name: 'North Loop Charger Point', activeTx: 3, usage: 65, status: 'Optimal' },
  { name: 'West Lake Hills Station', activeTx: 0, usage: 0, status: 'Maintenance' },
];

export default function DashboardPage() {
  return (
    <div className="space-y-6">
      
      {/* Stats Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {stats.map((s, idx) => {
          const Icon = s.icon;
          return (
            <div key={idx} className="bg-white dark:bg-gray-900 p-6 rounded-2xl border border-gray-200 dark:border-gray-800 shadow-sm flex items-center justify-between">
              <div className="space-y-2">
                <span className="text-xs font-semibold text-gray-500 dark:text-gray-400">{s.label}</span>
                <p className="text-2xl font-bold">{s.value}</p>
                <div className="flex items-center gap-1">
                  {s.trend === 'up' ? (
                    <span className="text-emerald-500 flex items-center text-xs font-semibold">
                      <ArrowUpRight size={14} /> {s.change}
                    </span>
                  ) : (
                    <span className="text-rose-500 flex items-center text-xs font-semibold">
                      <ArrowDownRight size={14} /> {s.change}
                    </span>
                  )}
                  <span className="text-[10px] text-gray-400">vs last week</span>
                </div>
              </div>
              <div className="p-4 bg-emerald-50 dark:bg-emerald-950/50 text-emerald-600 dark:text-emerald-400 rounded-xl">
                <Icon size={24} />
              </div>
            </div>
          );
        })}
      </div>

      {/* Grid: Charts & Analytics */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        
        {/* Weekly Power Analytics (Custom SVG Chart) */}
        <div className="bg-white dark:bg-gray-900 p-6 rounded-2xl border border-gray-200 dark:border-gray-800 lg:col-span-2 space-y-4">
          <div className="flex items-center justify-between">
            <span className="font-bold text-sm tracking-wide">Network Utilization (Last 24 Hours)</span>
            <div className="flex items-center gap-4 text-xs font-semibold">
              <div className="flex items-center gap-1.5"><span className="w-2.5 h-2.5 rounded-full bg-emerald-500"></span> Active Power</div>
              <div className="flex items-center gap-1.5"><span className="w-2.5 h-2.5 rounded-full bg-gray-300 dark:bg-gray-700"></span> Baseline Limit</div>
            </div>
          </div>
          
          <div className="h-64 w-full flex items-end justify-between pt-4 relative">
            {/* Grid Lines */}
            <div className="absolute inset-x-0 top-1/4 border-b border-gray-100 dark:border-gray-800/80"></div>
            <div className="absolute inset-x-0 top-2/4 border-b border-gray-100 dark:border-gray-800/80"></div>
            <div className="absolute inset-x-0 top-3/4 border-b border-gray-100 dark:border-gray-800/80"></div>

            {/* Custom SVG Line Chart */}
            <svg className="absolute inset-0 h-full w-full" preserveAspectRatio="none" viewBox="0 0 100 100">
              {/* Fill Gradient Area */}
              <defs>
                <linearGradient id="chartGrad" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="0%" stopColor="#10b981" stopOpacity="0.25"/>
                  <stop offset="100%" stopColor="#10b981" stopOpacity="0.0"/>
                </linearGradient>
              </defs>
              <path 
                d="M0,100 L0,70 L15,50 L30,80 L45,40 L60,30 L75,55 L90,20 L100,45 L100,100 Z" 
                fill="url(#chartGrad)"
              />
              {/* Stroke Line */}
              <path 
                d="M0,70 L15,50 L30,80 L45,40 L60,30 L75,55 L90,20 L100,45" 
                fill="none" 
                stroke="#10b981" 
                strokeWidth="2.5"
                strokeLinecap="round"
              />
            </svg>

            {/* Time Labels */}
            <div className="absolute bottom-0 inset-x-0 flex justify-between text-[10px] text-gray-400 pt-1">
              <span>08:00 AM</span>
              <span>12:00 PM</span>
              <span>04:00 PM</span>
              <span>08:00 PM</span>
              <span>12:00 AM</span>
              <span>04:00 AM</span>
            </div>
          </div>
        </div>

        {/* Top Stations */}
        <div className="bg-white dark:bg-gray-900 p-6 rounded-2xl border border-gray-200 dark:border-gray-800 space-y-4">
          <span className="font-bold text-sm tracking-wide">Top Stations</span>
          <div className="space-y-4">
            {topStations.map((station, idx) => (
              <div key={idx} className="flex items-center justify-between p-3 rounded-xl hover:bg-gray-50 dark:hover:bg-gray-800/40 transition-colors">
                <div className="flex items-center gap-3">
                  <div className="p-2 bg-emerald-50 dark:bg-emerald-950 text-emerald-600 dark:text-emerald-400 rounded-lg">
                    <MapPin size={18} />
                  </div>
                  <div>
                    <p className="text-xs font-semibold">{station.name}</p>
                    <p className="text-[10px] text-gray-400">{station.activeTx} Active Transactions</p>
                  </div>
                </div>
                <div className="text-right">
                  <p className="text-xs font-bold">{station.usage}% Utilization</p>
                  <span className={`inline-block w-2 h-2 rounded-full ${station.status === 'Optimal' ? 'bg-emerald-500' : 'bg-amber-500'}`}></span>
                </div>
              </div>
            ))}
          </div>
        </div>

      </div>

      {/* Grid: OCPP Live Logs & System Diagnostics */}
      <div className="bg-white dark:bg-gray-900 p-6 rounded-2xl border border-gray-200 dark:border-gray-800 space-y-4">
        <div className="flex items-center justify-between">
          <span className="font-bold text-sm tracking-wide">Live OCPP Log Stream</span>
          <span className="text-[10px] bg-emerald-100 dark:bg-emerald-950 text-emerald-800 dark:text-emerald-400 px-2 py-0.5 rounded-full flex items-center gap-1 font-semibold">
            <span className="w-1.5 h-1.5 bg-emerald-500 rounded-full animate-pulse"></span> Streaming
          </span>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs border-collapse">
            <thead>
              <tr className="border-b border-gray-200 dark:border-gray-800 text-gray-400">
                <th className="py-3 font-semibold">Charger Box ID</th>
                <th className="py-3 font-semibold">Event Description</th>
                <th className="py-3 font-semibold">OCPP Status</th>
                <th className="py-3 font-semibold">Timestamp</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100 dark:divide-gray-800/80">
              {mockLogs.map((log) => (
                <tr key={log.id} className="hover:bg-gray-50 dark:hover:bg-gray-800/30 transition-colors">
                  <td className="py-3.5 font-semibold text-gray-700 dark:text-gray-300">{log.charger}</td>
                  <td className="py-3.5 text-gray-600 dark:text-gray-400">{log.event}</td>
                  <td className="py-3.5">
                    <span className={`px-2.5 py-0.5 rounded-full text-[10px] font-semibold ${
                      log.status === 'Accepted' || log.status === 'Success' 
                        ? 'bg-emerald-100 dark:bg-emerald-950/80 text-emerald-850 dark:text-emerald-400' 
                        : log.status === 'Warning' 
                        ? 'bg-rose-100 dark:bg-rose-950/80 text-rose-800 dark:text-rose-400'
                        : 'bg-amber-100 dark:bg-amber-950/80 text-amber-800 dark:text-amber-400'
                    }`}>
                      {log.status}
                    </span>
                  </td>
                  <td className="py-3.5 text-gray-400">{log.time}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

    </div>
  );
}
