import React, { useState, useEffect } from 'react';
import { 
  IndianRupee, Activity, Battery, Radio, ArrowUpRight, ArrowDownRight, 
  MapPin, CheckCircle, AlertTriangle, RefreshCw, Zap, ShieldAlert
} from 'lucide-react';

interface DashboardStats {
  totalStations: number;
  totalChargers: number;
  onlineChargers: number;
  offlineChargers: number;
  chargingChargers: number;
  faultedChargers: number;
  availableConnectors: number;
  activeSessions: number;
}

export default function DashboardPage() {
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);

  const fetchDashboardStats = async () => {
    try {
      setLoading(true);
      setError(null);
      const token = localStorage.getItem('token');
      const response = await fetch('/api/v1/admin/dashboard', {
        headers: {
          'Authorization': token ? `Bearer ${token}` : '',
          'Content-Type': 'application/json',
        },
      });

      if (!response.ok) {
        throw new Error(`Failed to load dashboard metrics (HTTP ${response.status})`);
      }

      const data = await response.json();
      setStats(data);
    } catch (err: any) {
      setError(err.message || 'Failed to connect to backend server');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchDashboardStats();
  }, []);

  const statItems = [
    { 
      label: 'Total Stations', 
      value: stats ? stats.totalStations.toString() : '-', 
      subtext: 'Registered charging hubs',
      icon: MapPin, 
      color: 'bg-emerald-50 dark:bg-emerald-950/50 text-emerald-600 dark:text-emerald-400' 
    },
    { 
      label: 'Charger Network Liveness', 
      value: stats ? `${stats.onlineChargers} / ${stats.totalChargers} Online` : '-', 
      subtext: stats ? `${stats.offlineChargers} Offline` : 'Hardware status',
      icon: Radio, 
      color: 'bg-blue-50 dark:bg-blue-950/50 text-blue-600 dark:text-blue-400' 
    },
    { 
      label: 'Active Sessions', 
      value: stats ? `${stats.activeSessions} Charging` : '-', 
      subtext: stats ? `${stats.chargingChargers} chargers in-use` : 'Real-time charging',
      icon: Activity, 
      color: 'bg-indigo-50 dark:bg-indigo-950/50 text-indigo-600 dark:text-indigo-400' 
    },
    { 
      label: 'Available Connectors', 
      value: stats ? stats.availableConnectors.toString() : '-', 
      subtext: stats ? `${stats.faultedChargers} Faulted / Error` : 'Ready for plug-in',
      icon: Zap, 
      color: 'bg-amber-50 dark:bg-amber-950/50 text-amber-600 dark:text-amber-400' 
    },
  ];

  return (
    <div className="space-y-6">
      
      {/* Header Bar */}
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-xl font-bold tracking-tight">EcoMargin Admin Control Dashboard</h2>
          <p className="text-xs text-gray-500 dark:text-gray-400">Live authoritative station, charger, connector, and session telemetry.</p>
        </div>
        <button
          onClick={fetchDashboardStats}
          disabled={loading}
          className="flex items-center gap-2 px-4 py-2 bg-emerald-600 hover:bg-emerald-700 text-white rounded-xl text-xs font-semibold shadow-sm transition-all disabled:opacity-50"
        >
          <RefreshCw size={14} className={loading ? 'animate-spin' : ''} />
          Refresh Stats
        </button>
      </div>

      {/* Error Alert */}
      {error && (
        <div className="p-4 bg-rose-50 dark:bg-rose-950/30 border border-rose-200 dark:border-rose-800/80 rounded-2xl flex items-center justify-between">
          <div className="flex items-center gap-3">
            <AlertTriangle className="text-rose-600 dark:text-rose-400" size={20} />
            <p className="text-xs text-rose-700 dark:text-rose-300 font-medium">{error}</p>
          </div>
          <button
            onClick={fetchDashboardStats}
            className="px-3 py-1 bg-rose-600 text-white rounded-lg text-xs font-semibold hover:bg-rose-700"
          >
            Retry
          </button>
        </div>
      )}

      {/* Stats Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {statItems.map((s, idx) => {
          const Icon = s.icon;
          return (
            <div key={idx} className="bg-white dark:bg-gray-900 p-6 rounded-2xl border border-gray-200 dark:border-gray-800 shadow-sm flex items-center justify-between">
              <div className="space-y-1">
                <span className="text-xs font-semibold text-gray-500 dark:text-gray-400">{s.label}</span>
                <p className="text-2xl font-bold">{loading ? '...' : s.value}</p>
                <p className="text-[10px] text-gray-400 font-medium">{s.subtext}</p>
              </div>
              <div className={`p-4 rounded-xl ${s.color}`}>
                <Icon size={24} />
              </div>
            </div>
          );
        })}
      </div>

      {/* Grid: Charts & Network Diagnostics */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        
        {/* Network Power Line Chart */}
        <div className="bg-white dark:bg-gray-900 p-6 rounded-2xl border border-gray-200 dark:border-gray-800 lg:col-span-2 space-y-4">
          <div className="flex items-center justify-between">
            <span className="font-bold text-sm tracking-wide">Network Charging Capacity & Power</span>
            <div className="flex items-center gap-4 text-xs font-semibold">
              <div className="flex items-center gap-1.5"><span className="w-2.5 h-2.5 rounded-full bg-emerald-500"></span> Active Charging Power</div>
              <div className="flex items-center gap-1.5"><span className="w-2.5 h-2.5 rounded-full bg-gray-300 dark:bg-gray-700"></span> Grid Limit</div>
            </div>
          </div>
          
          <div className="h-64 w-full flex items-end justify-between pt-4 relative">
            <div className="absolute inset-x-0 top-1/4 border-b border-gray-100 dark:border-gray-800/80"></div>
            <div className="absolute inset-x-0 top-2/4 border-b border-gray-100 dark:border-gray-800/80"></div>
            <div className="absolute inset-x-0 top-3/4 border-b border-gray-100 dark:border-gray-800/80"></div>

            <svg className="absolute inset-0 h-full w-full" preserveAspectRatio="none" viewBox="0 0 100 100">
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
              <path 
                d="M0,70 L15,50 L30,80 L45,40 L60,30 L75,55 L90,20 L100,45" 
                fill="none" 
                stroke="#10b981" 
                strokeWidth="2.5"
                strokeLinecap="round"
              />
            </svg>

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

        {/* Live Network Summary */}
        <div className="bg-white dark:bg-gray-900 p-6 rounded-2xl border border-gray-200 dark:border-gray-800 space-y-4">
          <span className="font-bold text-sm tracking-wide">Network Health Overview</span>
          <div className="space-y-4 text-xs">
            <div className="flex items-center justify-between p-3 rounded-xl bg-gray-50 dark:bg-gray-800/40">
              <div className="flex items-center gap-2">
                <CheckCircle className="text-emerald-500" size={16} />
                <span className="font-semibold">Online Chargers</span>
              </div>
              <span className="font-bold text-emerald-600 dark:text-emerald-400">{stats ? stats.onlineChargers : 0}</span>
            </div>

            <div className="flex items-center justify-between p-3 rounded-xl bg-gray-50 dark:bg-gray-800/40">
              <div className="flex items-center gap-2">
                <AlertTriangle className="text-rose-500" size={16} />
                <span className="font-semibold">Offline Chargers</span>
              </div>
              <span className="font-bold text-rose-600 dark:text-rose-400">{stats ? stats.offlineChargers : 0}</span>
            </div>

            <div className="flex items-center justify-between p-3 rounded-xl bg-gray-50 dark:bg-gray-800/40">
              <div className="flex items-center gap-2">
                <Activity className="text-blue-500" size={16} />
                <span className="font-semibold">Active Charging Sessions</span>
              </div>
              <span className="font-bold text-blue-600 dark:text-blue-400">{stats ? stats.activeSessions : 0}</span>
            </div>

            <div className="flex items-center justify-between p-3 rounded-xl bg-gray-50 dark:bg-gray-800/40">
              <div className="flex items-center gap-2">
                <ShieldAlert className="text-amber-500" size={16} />
                <span className="font-semibold">Faulted Chargers</span>
              </div>
              <span className="font-bold text-amber-600 dark:text-amber-400">{stats ? stats.faultedChargers : 0}</span>
            </div>
          </div>
        </div>

      </div>

    </div>
  );
}
