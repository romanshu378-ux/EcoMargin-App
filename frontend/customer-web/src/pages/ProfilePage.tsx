import React from 'react';
import { User, Car, Save } from 'lucide-react';

export const ProfilePage: React.FC = () => {
  return (
    <div className="space-y-6 max-w-3xl mx-auto py-8 px-4">
      <div>
        <h1 className="text-2xl font-bold text-white">EV Driver Profile</h1>
        <p className="text-xs text-slate-400">Personal details and vehicle compatibility settings</p>
      </div>

      <div className="bg-slate-900 border border-slate-800 rounded-2xl p-6 space-y-6">
        <h3 className="text-sm font-bold text-white border-b border-slate-800 pb-3">Personal Details</h3>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-6 text-xs">
          <div>
            <label className="block font-semibold text-slate-300 mb-2">Full Name</label>
            <input
              type="text"
              defaultValue="Alex Rivers"
              className="w-full px-4 py-2.5 bg-slate-950 border border-slate-800 rounded-xl text-slate-100 focus:outline-none focus:border-emerald-500"
            />
          </div>

          <div>
            <label className="block font-semibold text-slate-300 mb-2">Email Address</label>
            <input
              type="email"
              defaultValue="alex@example.com"
              className="w-full px-4 py-2.5 bg-slate-950 border border-slate-800 rounded-xl text-slate-100 focus:outline-none focus:border-emerald-500"
            />
          </div>
        </div>

        <h3 className="text-sm font-bold text-white border-b border-slate-800 pb-3 pt-4">EV Vehicle Settings</h3>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-6 text-xs">
          <div>
            <label className="block font-semibold text-slate-300 mb-2">Vehicle Make & Model</label>
            <input
              type="text"
              defaultValue="Tesla Model 3 Long Range"
              className="w-full px-4 py-2.5 bg-slate-950 border border-slate-800 rounded-xl text-slate-100 focus:outline-none focus:border-emerald-500"
            />
          </div>

          <div>
            <label className="block font-semibold text-slate-300 mb-2">Default Plug Compatibility</label>
            <select className="w-full px-4 py-2.5 bg-slate-950 border border-slate-800 rounded-xl text-slate-100 focus:outline-none focus:border-emerald-500">
              <option value="CCS2">CCS Combo 2 (DC Fast)</option>
              <option value="TYPE2">Type 2 (AC Mennekes)</option>
              <option value="NACS">NACS (Tesla)</option>
            </select>
          </div>
        </div>

        <div className="pt-4 border-t border-slate-800 flex justify-end">
          <button className="flex items-center gap-2 px-5 py-2.5 bg-emerald-500 hover:bg-emerald-600 font-semibold text-white text-xs rounded-xl transition-all shadow-lg shadow-emerald-500/20">
            <Save className="w-4 h-4" /> Save Profile
          </button>
        </div>
      </div>
    </div>
  );
};
