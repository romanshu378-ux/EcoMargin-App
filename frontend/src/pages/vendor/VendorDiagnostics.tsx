import React, { useState } from 'react';
import { Cpu, Terminal, RefreshCw, Check } from 'lucide-react';
import { useNotificationStore } from '../../store/notificationStore';

export default function VendorDiagnostics() {
  const addNotification = useNotificationStore(state => state.addNotification);
  const [logs, setLogs] = useState([
    { charger: 'TX_AUS_DWTN_01', status: 'COMPLETED', date: '2026-08-06 14:02' },
  ]);

  const requestDiagnosticLogs = (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const data = new FormData(e.currentTarget);
    const charger = data.get('charger') as string;

    addNotification({
      title: 'Diagnostics Scheduled',
      message: `CPO log request sent to ${charger}`,
      type: 'info'
    });

    setLogs(prev => [
      { charger, status: 'UPLOADING', date: 'Just now' },
      ...prev
    ]);
  };

  return (
    <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
      
      {/* Firmware updates */}
      <div className="bg-white dark:bg-gray-900 border border-gray-200 dark:border-gray-800 rounded-2xl p-6 shadow-sm space-y-4">
        <div className="flex items-center gap-2">
          <div className="p-2 bg-emerald-50 dark:bg-emerald-950 text-emerald-600 dark:text-emerald-400 rounded-lg">
            <Cpu size={18} />
          </div>
          <span className="font-bold text-sm tracking-wide">CPO Firmware Pipeline</span>
        </div>

        <form onSubmit={(e) => { e.preventDefault(); addNotification({ title: 'Firmware Scheduled', message: 'Firmware push triggered successfully.', type: 'success' }); }} className="space-y-4 text-xs">
          <div className="space-y-1">
            <label className="font-semibold text-gray-500">Firmware Build URL</label>
            <input required type="url" placeholder="https://bin.ecomargin.com/cpo-builds/rt50-v1.4.3.bin" className="w-full bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700 px-4 py-2.5 rounded-xl outline-none" />
          </div>
          <div className="space-y-1">
            <label className="font-semibold text-gray-500">Target Charger ID</label>
            <input required type="text" placeholder="TX_AUS_DWTN_01" className="w-full bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700 px-4 py-2.5 rounded-xl outline-none" />
          </div>
          <button type="submit" className="w-full py-3 bg-emerald-600 hover:bg-emerald-700 text-white font-bold rounded-xl transition-all shadow-md">
            Schedule Firmware Release
          </button>
        </form>
      </div>

      {/* Diagnostics */}
      <div className="bg-white dark:bg-gray-900 border border-gray-200 dark:border-gray-800 rounded-2xl p-6 shadow-sm space-y-4">
        <div className="flex items-center gap-2">
          <div className="p-2 bg-emerald-50 dark:bg-emerald-950 text-emerald-600 dark:text-emerald-400 rounded-lg">
            <Terminal size={18} />
          </div>
          <span className="font-bold text-sm tracking-wide">Diagnostics Retrieval</span>
        </div>

        <form onSubmit={requestDiagnosticLogs} className="flex gap-2">
          <input required name="charger" placeholder="Charger ID (e.g. TX_AUS_DWTN_01)" className="flex-1 bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700 px-4 py-2 rounded-xl text-xs outline-none" />
          <button className="bg-emerald-600 hover:bg-emerald-700 text-white px-4 py-2 rounded-xl text-xs font-semibold shadow-md transition-all">
            Fetch Logs
          </button>
        </form>

        <div className="divide-y divide-gray-100 dark:divide-gray-800 pt-2">
          {logs.map((l, idx) => (
            <div key={idx} className="py-3 flex justify-between items-center text-xs">
              <div>
                <p className="font-semibold text-gray-700 dark:text-gray-300">{l.charger}</p>
                <p className="text-[10px] text-gray-400">{l.date}</p>
              </div>
              <span className={`px-2 py-0.5 rounded text-[10px] font-bold ${
                l.status === 'COMPLETED' ? 'bg-emerald-100 text-emerald-800' : 'bg-amber-100 text-amber-800 animate-pulse'
              }`}>{l.status}</span>
            </div>
          ))}
        </div>
      </div>

    </div>
  );
}
