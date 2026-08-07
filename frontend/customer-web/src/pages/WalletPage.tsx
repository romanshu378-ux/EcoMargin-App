import React, { useState } from 'react';
import { Wallet, Plus, ArrowUpRight, ArrowDownLeft } from 'lucide-react';

export const WalletPage: React.FC = () => {
  const [balance, setBalance] = useState(256.50);
  const [amount, setAmount] = useState('500');

  const handleTopup = () => {
    const val = parseFloat(amount);
    if (!isNaN(val) && val > 0) {
      setBalance(prev => prev + val);
    }
  };

  const transactions = [
    { id: 'W-901', type: 'TOPUP', amount: '+₹500.00', gateway: 'Razorpay UPI (Google Pay)', date: '2026-08-07 14:12' },
    { id: 'W-902', type: 'CHARGING', amount: '-₹261.00', gateway: 'GreenCharge Hub Sector 62', date: '2026-08-07 15:30' },
  ];

  return (
    <div className="space-y-8 max-w-5xl mx-auto py-8 px-4 sm:px-6">
      {/* Wallet Card */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div className="bg-gradient-to-br from-slate-900 via-emerald-950 to-slate-900 border border-slate-200 rounded-3xl p-8 space-y-6 shadow-xl">
          <div className="flex justify-between items-center text-slate-300">
            <span className="text-xs font-semibold uppercase tracking-wider text-emerald-400">EcoMargin Driver Wallet</span>
            <Wallet className="w-6 h-6 text-emerald-400" />
          </div>
          <div>
            <p className="text-xs text-slate-400">Available Balance</p>
            <p className="text-4xl font-extrabold text-white mt-1">₹{balance.toFixed(2)}</p>
          </div>
          <div className="pt-4 border-t border-slate-800 flex items-center justify-between text-xs text-slate-400">
            <span>Auto-Topup: Disabled</span>
            <span className="text-emerald-400 font-semibold">Active & Ready</span>
          </div>
        </div>

        {/* Top-up Box */}
        <div className="bg-white border border-slate-200 rounded-3xl p-8 space-y-5 shadow-sm">
          <h3 className="font-bold text-slate-900 text-base">Top-Up Wallet</h3>
          <div>
            <label className="block text-xs font-semibold text-slate-600 mb-2">Select Top-Up Amount (₹)</label>
            <div className="flex gap-2 mb-3">
              {['200', '500', '1000', '2000'].map((a) => (
                <button
                  key={a}
                  onClick={() => setAmount(a)}
                  className={`flex-1 py-2 rounded-xl text-xs font-bold transition-all ${
                    amount === a ? 'bg-emerald-600 text-white' : 'bg-slate-50 text-slate-700 hover:bg-slate-100 border border-slate-200'
                  }`}
                >
                  ₹{a}
                </button>
              ))}
            </div>
            <input
              type="number"
              value={amount}
              onChange={(e) => setAmount(e.target.value)}
              className="w-full px-4 py-3 bg-slate-50 border border-slate-200 rounded-xl text-sm text-slate-900 focus:outline-none focus:border-emerald-500"
            />
          </div>
          <button
            onClick={handleTopup}
            className="w-full py-3 bg-emerald-600 hover:bg-emerald-700 font-semibold text-white rounded-xl text-sm transition-all shadow-md shadow-emerald-600/20"
          >
            Add Funds via Razorpay / UPI
          </button>
        </div>
      </div>

      {/* Transaction History */}
      <div className="bg-white border border-slate-200 rounded-2xl p-6 space-y-4 shadow-sm">
        <h3 className="font-bold text-slate-900 text-base">Wallet Ledger</h3>
        <div className="divide-y divide-slate-100">
          {transactions.map((t) => (
            <div key={t.id} className="py-3 flex items-center justify-between text-xs">
              <div className="flex items-center gap-3">
                <div className={`p-2 rounded-lg ${t.type === 'TOPUP' ? 'bg-emerald-50 text-emerald-600' : 'bg-rose-50 text-rose-600'}`}>
                  {t.type === 'TOPUP' ? <ArrowDownLeft className="w-4 h-4" /> : <ArrowUpRight className="w-4 h-4" />}
                </div>
                <div>
                  <p className="font-semibold text-slate-900">{t.gateway}</p>
                  <p className="text-[11px] text-slate-500">{t.date}</p>
                </div>
              </div>
              <span className={`font-mono font-bold ${t.amount.startsWith('+') ? 'text-emerald-600' : 'text-slate-900'}`}>
                {t.amount}
              </span>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};
