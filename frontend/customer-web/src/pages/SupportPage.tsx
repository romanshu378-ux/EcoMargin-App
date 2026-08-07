import React from 'react';
import { LifeBuoy, MessageSquare, HelpCircle } from 'lucide-react';

export const SupportPage: React.FC = () => {
  return (
    <div className="space-y-8 max-w-4xl mx-auto py-8 px-4">
      <div>
        <h1 className="text-2xl font-bold text-white">Customer Support & Assistance</h1>
        <p className="text-xs text-slate-400">Get help with charging sessions, billing, or app usage</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div className="bg-slate-900 border border-slate-800 rounded-2xl p-6 space-y-4">
          <div className="w-10 h-10 rounded-xl bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 flex items-center justify-center">
            <MessageSquare className="w-5 h-5" />
          </div>
          <h3 className="font-bold text-white text-base">Submit Support Ticket</h3>
          <p className="text-xs text-slate-400">Report an issue with a charger pillar or transaction debit.</p>
          <button className="w-full py-2.5 bg-emerald-500 hover:bg-emerald-600 font-semibold text-white rounded-xl text-xs transition-all">
            Create Ticket
          </button>
        </div>

        <div className="bg-slate-900 border border-slate-800 rounded-2xl p-6 space-y-4">
          <div className="w-10 h-10 rounded-xl bg-blue-500/10 border border-blue-500/20 text-blue-400 flex items-center justify-center">
            <HelpCircle className="w-5 h-5" />
          </div>
          <h3 className="font-bold text-white text-base">Frequently Asked Questions</h3>
          <p className="text-xs text-slate-400">How to start charging, unlock connectors, or request refunds.</p>
          <button className="w-full py-2.5 bg-slate-800 hover:bg-slate-700 font-semibold text-slate-200 rounded-xl text-xs border border-slate-700 transition-all">
            Browse FAQ
          </button>
        </div>
      </div>
    </div>
  );
};
