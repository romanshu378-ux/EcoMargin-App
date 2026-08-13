import React, { useState } from 'react';
import { IndianRupee, Wallet, ArrowUpRight, ArrowDownRight, CreditCard } from 'lucide-react';

interface Transaction {
  id: string;
  user: string;
  amount: number;
  type: 'CREDIT' | 'DEBIT';
  status: 'SUCCESS' | 'FAILED' | 'PENDING';
  date: string;
}

export default function TransactionsPage() {
  const [txs] = useState<Transaction[]>([
    { id: 'TXN102948', user: 'Jane Driver', amount: 850.00, type: 'DEBIT', status: 'SUCCESS', date: '2026-08-07 09:12' },
    { id: 'TXN102949', user: 'Jane Driver', amount: 5000.00, type: 'CREDIT', status: 'SUCCESS', date: '2026-08-07 08:30' },
    { id: 'TXN102950', user: 'Jane Driver', amount: 520.00, type: 'DEBIT', status: 'SUCCESS', date: '2026-08-06 18:45' },
    { id: 'TXN102951', user: 'Bob Driver', amount: 300.00, type: 'DEBIT', status: 'FAILED', date: '2026-08-06 11:20' },
  ]);

  return (
    <div className="space-y-6">
      
      {/* Financial Overview Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div className="bg-white dark:bg-gray-900 border border-gray-200 dark:border-gray-800 rounded-2xl p-6 flex justify-between items-center shadow-sm">
          <div>
            <span className="text-xs font-semibold text-gray-400">Total Net Income</span>
            <p className="text-2xl font-bold mt-1">₹4,82,150.00</p>
          </div>
          <div className="p-3 bg-emerald-50 dark:bg-emerald-950/40 text-emerald-600 dark:text-emerald-400 rounded-xl">
            <IndianRupee size={20} />
          </div>
        </div>

        <div className="bg-white dark:bg-gray-900 border border-gray-200 dark:border-gray-800 rounded-2xl p-6 flex justify-between items-center shadow-sm">
          <div>
            <span className="text-xs font-semibold text-gray-400">Total Wallet Deposits</span>
            <p className="text-2xl font-bold mt-1">₹10,48,000.00</p>
          </div>
          <div className="p-3 bg-blue-50 dark:bg-blue-950/40 text-blue-600 dark:text-blue-400 rounded-xl">
            <Wallet size={20} />
          </div>
        </div>

        <div className="bg-white dark:bg-gray-900 border border-gray-200 dark:border-gray-800 rounded-2xl p-6 flex justify-between items-center shadow-sm">
          <div>
            <span className="text-xs font-semibold text-gray-400">Failed Authorizations</span>
            <p className="text-2xl font-bold mt-1">4.2%</p>
          </div>
          <div className="p-3 bg-rose-50 dark:bg-rose-950/40 text-rose-600 dark:text-rose-400 rounded-xl">
            <CreditCard size={20} />
          </div>
        </div>
      </div>

      {/* Transactions Grid */}
      <div className="bg-white dark:bg-gray-900 border border-gray-200 dark:border-gray-800 rounded-2xl p-6 shadow-sm space-y-4">
        <span className="font-bold text-sm tracking-wide">Global Transaction Ledger</span>
        
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs border-collapse">
            <thead>
              <tr className="border-b border-gray-200 dark:border-gray-800 text-gray-400">
                <th className="py-3 font-semibold">Transaction ID</th>
                <th className="py-3 font-semibold">User</th>
                <th className="py-3 font-semibold">Amount</th>
                <th className="py-3 font-semibold">Type</th>
                <th className="py-3 font-semibold">Status</th>
                <th className="py-3 font-semibold">Timestamp</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100 dark:divide-gray-800/80">
              {txs.map(t => (
                <tr key={t.id} className="hover:bg-gray-50 dark:hover:bg-gray-800/30 transition-colors">
                  <td className="py-4 font-semibold text-gray-700 dark:text-gray-300">{t.id}</td>
                  <td className="py-4 font-semibold">{t.user}</td>
                  <td className={`py-4 font-bold ${t.type === 'CREDIT' ? 'text-emerald-500' : ''}`}>
                    {t.type === 'CREDIT' ? '+' : '-'}₹{t.amount.toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
                  </td>
                  <td className="py-4">
                    <span className={`px-2 py-0.5 rounded text-[10px] font-bold ${
                      t.type === 'CREDIT' 
                        ? 'bg-emerald-50 dark:bg-emerald-950/20 text-emerald-600 dark:text-emerald-400' 
                        : 'bg-blue-50 dark:bg-blue-950/20 text-blue-600 dark:text-blue-400'
                    }`}>
                      {t.type}
                    </span>
                  </td>
                  <td className="py-4">
                    <span className={`px-2.5 py-0.5 rounded-full text-[10px] font-bold ${
                      t.status === 'SUCCESS' 
                        ? 'bg-emerald-100 text-emerald-800' 
                        : t.status === 'FAILED'
                        ? 'bg-red-100 text-red-800'
                        : 'bg-amber-100 text-amber-800'
                    }`}>
                      {t.status}
                    </span>
                  </td>
                  <td className="py-4 text-gray-400">{t.date}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

    </div>
  );
}
