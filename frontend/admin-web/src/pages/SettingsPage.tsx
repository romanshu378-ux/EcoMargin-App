import React, { useState } from 'react';
import { Settings, Save, Shield, Sliders } from 'lucide-react';

export const SettingsPage: React.FC = () => {
  const [baseRate, setBaseRate] = useState('0.44');
  const [idleFee, setIdleFee] = useState('0.50');
  const [cpoCommission, setCpoCommission] = useState('10.0');

  return (
    <div className="space-y-6 max-w-4xl">
      <div>
        <h1 className="text-xl font-bold text-white">Global System Settings</h1>
        <p className="text-xs text-slate-400">Configure default charging tariffs, commission rates, and operational parameters</p>
      </div>

      <div className="bg-slate-900 border border-slate-800 rounded-2xl p-6 space-y-6">
        <h3 className="text-sm font-bold text-white border-b border-slate-800 pb-3">Tariff & Platform Pricing</h3>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div>
            <label className="block text-xs font-semibold text-slate-300 mb-2">Default Base Rate ($/kWh)</label>
            <input
              type="text"
              value={baseRate}
              onChange={(e) => setBaseRate(e.target.value)}
              className="w-full px-4 py-2.5 bg-slate-950 border border-slate-800 rounded-xl text-xs text-slate-100 focus:outline-none focus:border-emerald-500"
            />
          </div>

          <div>
            <label className="block text-xs font-semibold text-slate-300 mb-2">Idle Fee Rate ($/min after charge)</label>
            <input
              type="text"
              value={idleFee}
              onChange={(e) => setIdleFee(e.target.value)}
              className="w-full px-4 py-2.5 bg-slate-950 border border-slate-800 rounded-xl text-xs text-slate-100 focus:outline-none focus:border-emerald-500"
            />
          </div>

          <div>
            <label className="block text-xs font-semibold text-slate-300 mb-2">Platform CPO Commission (%)</label>
            <input
              type="text"
              value={cpoCommission}
              onChange={(e) => setCpoCommission(e.target.value)}
              className="w-full px-4 py-2.5 bg-slate-950 border border-slate-800 rounded-xl text-xs text-slate-100 focus:outline-none focus:border-emerald-500"
            />
          </div>
        </div>

        <div className="pt-4 border-t border-slate-800 flex justify-end">
          <button className="flex items-center gap-2 px-5 py-2.5 bg-emerald-500 hover:bg-emerald-600 font-semibold text-white text-xs rounded-xl transition-all shadow-lg shadow-emerald-500/20">
            <Save className="w-4 h-4" /> Save Global Settings
          </button>
        </div>
      </div>
    </div>
  );
};
