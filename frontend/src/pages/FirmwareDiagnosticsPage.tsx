import React, { useState } from 'react';
import { ShieldAlert, Cpu, Terminal, RefreshCw, Send, CheckCircle } from 'lucide-react';
import { useNotificationStore } from '../store/notificationStore';

export default function FirmwareDiagnosticsPage() {
  const addNotification = useNotificationStore(state => state.addNotification);
  const [diagnosticsLogs, setDiagnosticsLogs] = useState([
    { charger: 'TX_AUS_DWTN_01', status: 'COMPLETED', date: '2026-08-06 14:02' },
    { charger: 'TX_AUS_NL_01', status: 'FAILED', date: '2026-08-05 09:12' },
  ]);

  const triggerDiagnostics = (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const data = new FormData(e.currentTarget);
    const charger = data.get('charger') as string;

    addNotification({
      title: 'Diagnostics Requested',
      message: `GetDiagnostics triggered for charger ${charger}`,
      type: 'info'
    });

    setDiagnosticsLogs(prev => [
      { charger, status: 'UPLOADING', date: new Date().toISOString().replace('T', ' ').substring(0, 16) },
      ...prev
    ]);
  };

  return (
    <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
      
      {/* Firmware Management */}
      <div className="bg-white dark:bg-gray-900 border border-gray-200 dark:border-gray-800 rounded-2xl p-6 shadow-sm space-y-4">
        <div className="flex items-center gap-2">
          <div className="p-2 bg-emerald-50 dark:bg-emerald-950 text-emerald-600 dark:text-emerald-400 rounded-lg">
            <Cpu size={18} />
          </div>
          <span className="font-bold text-sm tracking-wide">Firmware Management</span>
        </div>
        
        <form className="space-y-4 text-xs" onSubmit={(e) => { e.preventDefault(); addNotification({ title: 'Firmware Scheduled', message: 'Firmware push scheduled successfully', type: 'success' }); }}>
          <div className="space-y-1">
            <label className="font-semibold text-gray-500">Firmware Build Version</label>
            <input required type="text" placeholder="e.g. v2.2.0" className="w-full bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700 px-4 py-2.5 rounded-xl outline-none" />
          </div>
          <div className="space-y-1">
            <label className="font-semibold text-gray-500">Retrieval URL</label>
            <input required type="url" placeholder="https://firmware.ecomargin.com/builds/v220.bin" className="w-full bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700 px-4 py-2.5 rounded-xl outline-none" />
          </div>
          <div className="space-y-1">
            <label className="font-semibold text-gray-500">Target Charger ID</label>
            <input required type="text" placeholder="e.g. TX_AUS_DWTN_01" className="w-full bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700 px-4 py-2.5 rounded-xl outline-none" />
          </div>
          <button type="submit" className="w-full py-3 bg-emerald-600 hover:bg-emerald-700 text-white font-bold rounded-xl transition-all shadow-md">
            Schedule Firmware Upgrade
          </button>
        </form>
      </div>

      {/* Diagnostics Logs */}
      <div className="bg-white dark:bg-gray-900 border border-gray-200 dark:border-gray-800 rounded-2xl p-6 shadow-sm space-y-4">
        <div className="flex items-center gap-2">
          <div className="p-2 bg-emerald-50 dark:bg-emerald-950 text-emerald-600 dark:text-emerald-400 rounded-lg">
            <Terminal size={18} />
          </div>
          <span className="font-bold text-sm tracking-wide">Remote Diagnostics Logger</span>
        </div>

        <form className="flex gap-3" onSubmit={triggerDiagnostics}>
          <input required name="charger" placeholder="Charger ID (e.g., TX_AUS_NL_01)" className="flex-1 bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700 px-4 py-2 rounded-xl text-xs outline-none" />
          <button type="submit" className="bg-emerald-600 hover:bg-emerald-700 text-white px-4 py-2 rounded-xl text-xs font-semibold shadow-md transition-all flex items-center gap-1.5">
            <Send size={14} /> Request Logs
          </button>
        </form>

        <div className="divide-y divide-gray-100 dark:divide-gray-800/80 pt-2">
          {diagnosticsLogs.map((log, idx) => (
            <div key={idx} className="py-3 flex items-center justify-between text-xs">
              <div>
                <p className="font-semibold text-gray-700 dark:text-gray-300">{log.charger}</p>
                <p className="text-[10px] text-gray-400">{log.date}</p>
              </div>
              <span className={`px-2 py-0.5 rounded text-[10px] font-bold ${
                log.status === 'COMPLETED' 
                  ? 'bg-emerald-100 text-emerald-800' 
                  : log.status === 'FAILED'
                  ? 'bg-red-100 text-red-800'
                  : 'bg-amber-100 text-amber-800 animate-pulse'
              }`}>
                {log.status}
              </span>
            </div>
          ))}
        </div>
      </div>

    </div>
  );
}
