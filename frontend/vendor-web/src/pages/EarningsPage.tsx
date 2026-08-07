import React from 'react';
import { TrendingUp, DollarSign, Download, ArrowUpRight } from 'lucide-react';

export const EarningsPage: React.FC = () => {
  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-xl font-bold text-white">Vendor Revenue & Payouts</h1>
          <p className="text-xs text-slate-400">Request automated payouts to your registered bank account</p>
        </div>
        <button className="flex items-center gap-2 px-4 py-2.5 bg-amber-500 hover:bg-amber-600 font-semibold text-white text-xs rounded-xl transition-all shadow-lg shadow-amber-500/20">
          <DollarSign className="w-4 h-4" /> Request Payout ($18,450.00)
        </button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div className="bg-slate-900 border border-slate-800 rounded-2xl p-6">
          <h3 className="font-semibold text-slate-400 text-xs mb-1">Available Payout Balance</h3>
          <p className="text-3xl font-bold text-amber-400">$18,450.00</p>
          <p className="text-xs text-emerald-400 mt-2 flex items-center gap-1 font-medium">
            <ArrowUpRight className="w-3.5 h-3.5" /> +14.2% vs last week
          </p>
        </div>
        <div className="bg-slate-900 border border-slate-800 rounded-2xl p-6">
          <h3 className="font-semibold text-slate-400 text-xs mb-1">Lifetime Gross Revenue</h3>
          <p className="text-3xl font-bold text-white">$142,890.00</p>
          <p className="text-xs text-slate-400 mt-2">Total energy sales</p>
        </div>
        <div className="bg-slate-900 border border-slate-800 rounded-2xl p-6">
          <h3 className="font-semibold text-slate-400 text-xs mb-1">Total Payouts Completed</h3>
          <p className="text-3xl font-bold text-emerald-400">$124,440.00</p>
          <p className="text-xs text-slate-400 mt-2">Direct bank deposits</p>
        </div>
      </div>
    </div>
  );
};
