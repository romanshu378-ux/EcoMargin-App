import React, { useState } from 'react';
import { BatteryCharging, Key, RefreshCw, Radio, Play, Square, AlertTriangle } from 'lucide-react';
import { useNotificationStore } from '../store/notificationStore';

interface Charger {
  id: string;
  ocppId: string;
  model: string;
  brand: string;
  status: 'AVAILABLE' | 'CHARGING' | 'FAULTED' | 'UNAVAILABLE';
  powerKw: number;
}

export default function ChargersPage() {
  const addNotification = useNotificationStore(state => state.addNotification);
  const [chargers, setChargers] = useState<Charger[]>([
    { id: '1', ocppId: 'TX_AUS_DWTN_01', model: 'Tritium RT50', brand: 'Tritium', status: 'AVAILABLE', powerKw: 50 },
    { id: '2', ocppId: 'TX_AUS_DWTN_02', model: 'ABB Terra 184', brand: 'ABB', status: 'CHARGING', powerKw: 180 },
    { id: '3', ocppId: 'TX_AUS_NL_01', model: 'Tritium RT50', brand: 'Tritium', status: 'FAULTED', powerKw: 50 },
  ]);

  const triggerRemoteStart = (ocppId: string) => {
    addNotification({
      title: 'Remote Command Sent',
      message: `RemoteStartTransaction sent to ${ocppId}`,
      type: 'info'
    });
    setChargers(prev => prev.map(c => {
      if (c.ocppId === ocppId) {
        setTimeout(() => {
          addNotification({
            title: 'Transaction Started',
            message: `Remote start accepted on ${ocppId}`,
            type: 'success'
          });
        }, 1500);
        return { ...c, status: 'CHARGING' };
      }
      return c;
    }));
  };

  const triggerRemoteStop = (ocppId: string) => {
    addNotification({
      title: 'Remote Command Sent',
      message: `RemoteStopTransaction sent to ${ocppId}`,
      type: 'info'
    });
    setChargers(prev => prev.map(c => {
      if (c.ocppId === ocppId) {
        setTimeout(() => {
          addNotification({
            title: 'Transaction Stopped',
            message: `Remote stop accepted on ${ocppId}`,
            type: 'success'
          });
        }, 1500);
        return { ...c, status: 'AVAILABLE' };
      }
      return c;
    }));
  };

  const triggerUnlock = (ocppId: string) => {
    addNotification({
      title: 'Unlock Connector Sent',
      message: `Unlock request sent to ${ocppId}`,
      type: 'info'
    });
  };

  const triggerReset = (ocppId: string) => {
    addNotification({
      title: 'Reset Charger Sent',
      message: `Hard reset request sent to ${ocppId}`,
      type: 'warning'
    });
  };

  return (
    <div className="space-y-6">
      <h2 className="text-xl font-bold tracking-tight">OCPP Asset Management (Chargers)</h2>

      <div className="grid grid-cols-1 xl:grid-cols-2 gap-6">
        {chargers.map(charger => (
          <div key={charger.id} className="bg-white dark:bg-gray-900 border border-gray-200 dark:border-gray-800 rounded-2xl p-6 shadow-sm space-y-4">
            
            {/* Header info */}
            <div className="flex items-start justify-between border-b border-gray-100 dark:border-gray-800/80 pb-4">
              <div className="space-y-1">
                <div className="flex items-center gap-2">
                  <span className="font-bold text-base">{charger.ocppId}</span>
                  <span className="text-[10px] text-gray-400 font-semibold">{charger.brand}</span>
                </div>
                <p className="text-xs text-gray-500 dark:text-gray-400">{charger.model} • {charger.powerKw} kW</p>
              </div>

              {/* Status Badge */}
              <span className={`px-2.5 py-0.5 rounded-full text-[10px] font-bold ${
                charger.status === 'AVAILABLE' 
                  ? 'bg-emerald-100 dark:bg-emerald-950/80 text-emerald-800 dark:text-emerald-400' 
                  : charger.status === 'CHARGING'
                  ? 'bg-blue-100 dark:bg-blue-950/80 text-blue-800 dark:text-blue-400'
                  : charger.status === 'FAULTED'
                  ? 'bg-red-100 dark:bg-red-950/80 text-red-800 dark:text-red-400'
                  : 'bg-gray-100 dark:bg-gray-850 text-gray-850 dark:text-gray-400'
              }`}>
                {charger.status}
              </span>
            </div>

            {/* Action Controller Hub */}
            <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 pt-2">
              <button 
                onClick={() => triggerRemoteStart(charger.ocppId)}
                disabled={charger.status !== 'AVAILABLE'}
                className="flex flex-col items-center justify-center gap-2 p-3 bg-emerald-50 dark:bg-emerald-950/30 hover:bg-emerald-100 dark:hover:bg-emerald-900/40 text-emerald-600 dark:text-emerald-400 rounded-xl transition-all disabled:opacity-40 disabled:cursor-not-allowed"
              >
                <Play size={18} />
                <span className="text-[10px] font-bold">Start Tx</span>
              </button>

              <button 
                onClick={() => triggerRemoteStop(charger.ocppId)}
                disabled={charger.status !== 'CHARGING'}
                className="flex flex-col items-center justify-center gap-2 p-3 bg-rose-50 dark:bg-rose-950/30 hover:bg-rose-100 dark:hover:bg-rose-900/40 text-rose-600 dark:text-rose-400 rounded-xl transition-all disabled:opacity-40 disabled:cursor-not-allowed"
              >
                <Square size={18} />
                <span className="text-[10px] font-bold">Stop Tx</span>
              </button>

              <button 
                onClick={() => triggerUnlock(charger.ocppId)}
                className="flex flex-col items-center justify-center gap-2 p-3 bg-blue-50 dark:bg-blue-950/30 hover:bg-blue-100 dark:hover:bg-blue-900/40 text-blue-600 dark:text-blue-400 rounded-xl transition-all"
              >
                <Key size={18} />
                <span className="text-[10px] font-bold">Unlock</span>
              </button>

              <button 
                onClick={() => triggerReset(charger.ocppId)}
                className="flex flex-col items-center justify-center gap-2 p-3 bg-amber-50 dark:bg-amber-950/30 hover:bg-amber-100 dark:hover:bg-amber-900/40 text-amber-600 dark:text-amber-400 rounded-xl transition-all"
              >
                <RefreshCw size={18} />
                <span className="text-[10px] font-bold">Reset</span>
              </button>
            </div>

          </div>
        ))}
      </div>
    </div>
  );
}
