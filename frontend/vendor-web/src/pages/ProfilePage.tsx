import React from 'react';
import { User, Building2, CreditCard, Save } from 'lucide-react';

export const ProfilePage: React.FC = () => {
  return (
    <div className="space-y-6 max-w-4xl">
      <div>
        <h1 className="text-xl font-bold text-white">Vendor Business Profile</h1>
        <p className="text-xs text-slate-400">Manage CPO company registration, tax identity, and payout bank settings</p>
      </div>

      <div className="bg-slate-900 border border-slate-800 rounded-2xl p-6 space-y-6">
        <h3 className="text-sm font-bold text-white border-b border-slate-800 pb-3">Company Details</h3>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-6 text-xs">
          <div>
            <label className="block font-semibold text-slate-300 mb-2">Company Registered Name</label>
            <input
              type="text"
              defaultValue="ChargeTech Global Inc."
              className="w-full px-4 py-2.5 bg-slate-950 border border-slate-800 rounded-xl text-slate-100 focus:outline-none focus:border-amber-500"
            />
          </div>

          <div>
            <label className="block font-semibold text-slate-300 mb-2">Federal Tax Identification Number (EIN)</label>
            <input
              type="text"
              defaultValue="XX-XXX9081"
              className="w-full px-4 py-2.5 bg-slate-950 border border-slate-800 rounded-xl text-slate-100 focus:outline-none focus:border-amber-500"
            />
          </div>
        </div>

        <h3 className="text-sm font-bold text-white border-b border-slate-800 pb-3 pt-4">Payout Direct Deposit</h3>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-6 text-xs">
          <div>
            <label className="block font-semibold text-slate-300 mb-2">Bank Account Routing Number</label>
            <input
              type="text"
              defaultValue="121000358"
              className="w-full px-4 py-2.5 bg-slate-950 border border-slate-800 rounded-xl text-slate-100 focus:outline-none focus:border-amber-500"
            />
          </div>

          <div>
            <label className="block font-semibold text-slate-300 mb-2">Bank Account Number</label>
            <input
              type="password"
              defaultValue="987654321098"
              className="w-full px-4 py-2.5 bg-slate-950 border border-slate-800 rounded-xl text-slate-100 focus:outline-none focus:border-amber-500"
            />
          </div>
        </div>

        <div className="pt-4 border-t border-slate-800 flex justify-end">
          <button className="flex items-center gap-2 px-5 py-2.5 bg-amber-500 hover:bg-amber-600 font-semibold text-white text-xs rounded-xl transition-all shadow-lg shadow-amber-500/20">
            <Save className="w-4 h-4" /> Save Vendor Profile
          </button>
        </div>
      </div>
    </div>
  );
};
