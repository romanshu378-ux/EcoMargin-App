import React, { useState } from 'react';
import { BatteryCharging, RefreshCw, Key, Power, Activity } from 'lucide-react';
import { useNotificationStore } from '../../store/notificationStore';

interface CpoCharger {
  ocppId: string;
  station: string;
  status: 'AVAILABLE' | 'CHARGING' | 'FAULTED';
  activePowerKw: number;
  tempCelsius: number;
}

export default function VendorChargers() {
  const addNotification = useNotificationStore(state => state.addNotification);
  const [chargers, setChargers] = useState<CpoCharger[]>([
    { ocppId: 'TX_AUS_DWTN_01', station: 'Austin Downtown Hub', status: 'AVAILABLE', activePowerKw: 0, tempCelsius: 32 },
    { ocppId: 'TX_AUS_DWTN_02', station: 'Austin Downtown Hub', status: 'CHARGING', activePowerKw: 124.5, tempCelsius: 52 },
    { ocppId: 'TX_AUS_NL_01', station: 'North Loop Charger Point', status: 'FAULTED', activePowerKw: 0, tempCelsius: 24 },
  ]);

  const triggerReset = (ocppId: string) => {
    addNotification({
      title: 'Remote Reset Triggered',
      message: `Reset command sent successfully to ${ocppId}`,
      type: 'warning'
    });
  };

  const triggerUnlock = (ocppId: string) => {
    addNotification({
      title: 'Unlock Connector Triggered',
      message: `Unlock request sent to ${ocppId}`,
      type: 'info'
    });
  };

  return (
    <div className="space-y-6">
      <h2 className="text-xl font-bold tracking-tight">Owned Chargers Ledger</h2>

      <div className="grid grid-cols-1 xl:grid-cols-3 gap-6">
        {chargers.map(c => (
          <div key={c.ocppId} className="bg-white dark:bg-gray-900 border border-gray-200 dark:border-gray-800 rounded-2xl p-6 shadow-sm flex flex-col justify-between space-y-4">
            
            {/* Header Status */}
            <div className="flex items-start justify-between border-b border-gray-100 dark:border-gray-800/80 pb-4">
              <div className="space-y-1">
                <span className="font-bold text-sm">{c.ocppId}</span>
                <p className="text-[10px] text-gray-400">{c.station}</p>
              </div>
              <span className={`px-2.5 py-0.5 rounded-full text-[10px] font-bold ${
                c.status === 'AVAILABLE' 
                  ? 'bg-emerald-100 text-emerald-800' 
                  : c.status === 'CHARGING' 
                  ? 'bg-blue-100 text-blue-800' 
                  : 'bg-red-100 text-red-800'
              }`}>
                {c.status}
              </span>
            </div>

            {/* Live Metrics */}
            <div className="grid grid-cols-2 gap-4 text-xs font-semibold">
              <div className="p-3 bg-gray-50 dark:bg-gray-800/40 rounded-xl space-y-1">
                <p className="text-[10px] text-gray-400">Power Draw</p>
                <p className="text-sm font-bold flex items-center gap-1">
                  <Activity size={14} className="text-emerald-500" /> {c.activePowerKw} kW
                </p>
              </div>
              <div className="p-3 bg-gray-50 dark:bg-gray-800/40 rounded-xl space-y-1">
                <p className="text-[10px] text-gray-400">Core Temp</p>
                <p className="text-sm font-bold">{c.tempCelsius}°C</p>
              </div>
            </div>

            {/* Actions */}
            <div className="flex gap-2 pt-2 border-t border-gray-100 dark:border-gray-800/80">
              <button 
                onClick={() => triggerReset(c.ocppId)}
                className="flex-1 flex items-center justify-center gap-1.5 py-2 bg-amber-50 dark:bg-amber-950/20 text-amber-600 dark:text-amber-400 text-[10px] font-bold rounded-xl hover:bg-amber-100 transition-all"
              >
                <RefreshCw size={14} /> Restart
              </button>
              <button 
                onClick={() => triggerUnlock(c.ocppId)}
                className="flex-1 flex items-center justify-center gap-1.5 py-2 bg-blue-50 dark:bg-blue-950/20 text-blue-600 dark:text-blue-400 text-[10px] font-bold rounded-xl hover:bg-blue-100 transition-all"
              >
                <Key size={14} /> Unlock
              </button>
            </div>

          </div>
        ))}
      </div>
    </div>
  );
}
