import React, { useState } from 'react';
import { Wallet, Plus, CreditCard, ArrowUpRight, ArrowDownLeft } from 'lucide-react';

export const WalletPage: React.FC = () => {
  const [balance, setBalance] = useState(45.00);
  const [amount, setAmount] = useState('25');

  const handleTopup = () => {
    const val = parseFloat(amount);
    if (!isNaN(val) && val > 0) {
      setBalance(prev => prev + val);
    }
  };

  const transactions = [
    { id: 'W-901', type: 'TOPUP', amount: '+$50.00', gateway: 'Visa ending in 4242', date: '2026-03-07 09:12' },
    { id: 'W-902', type: 'CHARGING', amount: '-$18.70', gateway: 'Downtown Hub Fast Charge', date: '2026-03-07 10:14' },
  ];

  return (
    <div className="space-y-8 max-w-5xl mx-auto py-8 px-4">
      {/* Wallet Card */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div className="bg-gradient-to-br from-emerald-900 to-slate-900 border border-emerald-500/20 rounded-3xl p-8 space-y-6 shadow-2xl">
          <div className="flex justify-between items-center text-slate-300">
            <span className="text-xs font-semibold uppercase tracking-wider">EcoMargin Driver Wallet</span>
            <Wallet className="w-6 h-6 text-emerald-400" />
          </div>
          <div>
            <p className="text-xs text-slate-400">Current Balance</p>
            <p className="text-4xl font-extrabold text-white mt-1">${balance.toFixed(2)}</p>
          </div>
          <div className="pt-4 border-t border-slate-800/80 flex items-center justify-between text-xs text-slate-400">
            <span>Auto-topup: Disabled</span>
            <span className="text-emerald-400 font-semibold">Active & Ready</span>
          </div>
        </div>

        {/* Top-up Box */}
        <div className="bg-slate-900 border border-slate-800 rounded-3xl p-8 space-y-5">
          <h3 className="font-bold text-white text-base">Top-Up Wallet</h3>
          <div>
            <label className="block text-xs font-semibold text-slate-300 mb-2">Select Amount ($)</label>
            <div className="flex gap-2 mb-3">
              {['10', '25', '50', '100'].map((a) => (
                <button
                  key={a}
                  onClick={() => setAmount(a)}
                  className={`flex-1 py-2 rounded-xl text-xs font-bold transition-all ${
                    amount === a ? 'bg-emerald-500 text-white' : 'bg-slate-950 text-slate-400 hover:text-white border border-slate-800'
                  }`}
                >
                  ${a}
                </button>
              ))}
            </div>
            <input
              type="number"
              value={amount}
              onChange={(e) => setAmount(e.target.value)}
              className="w-full px-4 py-3 bg-slate-950 border border-slate-800 rounded-xl text-sm text-white focus:outline-none focus:border-emerald-500"
            />
          </div>
          <button
            onClick={handleTopup}
            className="w-full py-3 bg-emerald-500 hover:bg-emerald-600 font-semibold text-white rounded-xl text-sm transition-all shadow-lg shadow-emerald-500/20"
          >
            Add Funds via Card / Apple Pay
          </button>
        </div>
      </div>

      {/* Transaction History */}
      <div className="bg-slate-900 border border-slate-800 rounded-2xl p-6 space-y-4">
        <h3 className="font-bold text-white text-base">Wallet Ledger</h3>
        <div className="divide-y divide-slate-800">
          {transactions.map((t) => (
            <div key={t.id} className="py-3 flex items-center justify-between text-xs">
              <div className="flex items-center gap-3">
                <div className={`p-2 rounded-lg ${t.type === 'TOPUP' ? 'bg-emerald-500/10 text-emerald-400' : 'bg-rose-500/10 text-rose-400'}`}>
                  {t.type === 'TOPUP' ? <ArrowDownLeft className="w-4 h-4" /> : <ArrowUpRight className="w-4 h-4" />}
                </div>
                <div>
                  <p className="font-semibold text-white">{t.gateway}</p>
                  <p className="text-[11px] text-slate-500">{t.date}</p>
                </div>
              </div>
              <span className={`font-mono font-bold ${t.amount.startsWith('+') ? 'text-emerald-400' : 'text-slate-100'}`}>
                {t.amount}
              </span>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};
