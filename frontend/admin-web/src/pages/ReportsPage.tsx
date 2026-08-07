import React from 'react';
import { BarChart3, Download, TrendingUp, Zap, DollarSign } from 'lucide-react';

export const ReportsPage: React.FC = () => {
  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-xl font-bold text-white">Platform Analytics & Reports</h1>
          <p className="text-xs text-slate-400">Export financial summaries, station utilization, and carbon offset metrics</p>
        </div>
        <button className="flex items-center gap-2 px-4 py-2 bg-slate-800 hover:bg-slate-700 text-white rounded-xl text-xs font-semibold border border-slate-700 transition-all">
          <Download className="w-4 h-4" /> Export CSV Report
        </button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div className="bg-slate-900 border border-slate-800 rounded-2xl p-6">
          <h3 className="font-semibold text-white text-sm mb-2">Monthly Revenue</h3>
          <p className="text-3xl font-bold text-emerald-400">$48,290.00</p>
          <p className="text-xs text-slate-400 mt-1">+18.4% vs last month</p>
        </div>
        <div className="bg-slate-900 border border-slate-800 rounded-2xl p-6">
          <h3 className="font-semibold text-white text-sm mb-2">Energy Dispatched</h3>
          <p className="text-3xl font-bold text-amber-400">114.8 MWh</p>
          <p className="text-xs text-slate-400 mt-1">+22.1% utilization efficiency</p>
        </div>
        <div className="bg-slate-900 border border-slate-800 rounded-2xl p-6">
          <h3 className="font-semibold text-white text-sm mb-2">CO2 Offset Equivalent</h3>
          <p className="text-3xl font-bold text-blue-400">82.4 Metric Tons</p>
          <p className="text-xs text-slate-400 mt-1">Environmental Impact Metric</p>
        </div>
      </div>
    </div>
  );
};
