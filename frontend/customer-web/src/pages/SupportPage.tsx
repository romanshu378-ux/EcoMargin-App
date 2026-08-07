import React from 'react';
import { MessageSquare, HelpCircle, PhoneCall } from 'lucide-react';

export const SupportPage: React.FC = () => {
  return (
    <div className="space-y-8 max-w-4xl mx-auto py-8 px-4 sm:px-6">
      <div>
        <h1 className="text-2xl font-bold text-slate-900">Customer Support & Assistance</h1>
        <p className="text-xs text-slate-500">24/7 EV Driver Helpdesk for charging sessions, billing, and technical support</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div className="bg-white border border-slate-200 rounded-2xl p-6 space-y-4 shadow-sm">
          <div className="w-10 h-10 rounded-xl bg-emerald-50 text-emerald-600 border border-emerald-100 flex items-center justify-center">
            <PhoneCall className="w-5 h-5" />
          </div>
          <h3 className="font-bold text-slate-900 text-base">24/7 Helpline</h3>
          <p className="text-xs text-slate-500">Call our emergency EV driver hotline.</p>
          <a
            href="tel:18001234567"
            className="w-full py-2.5 bg-emerald-600 hover:bg-emerald-700 font-semibold text-white rounded-xl text-xs transition-all inline-block text-center shadow-sm"
          >
            1800-123-4567
          </a>
        </div>

        <div className="bg-white border border-slate-200 rounded-2xl p-6 space-y-4 shadow-sm">
          <div className="w-10 h-10 rounded-xl bg-emerald-50 text-emerald-600 border border-emerald-100 flex items-center justify-center">
            <MessageSquare className="w-5 h-5" />
          </div>
          <h3 className="font-bold text-slate-900 text-base">Support Ticket</h3>
          <p className="text-xs text-slate-500">Report an issue with a charger pillar or transaction debit.</p>
          <button className="w-full py-2.5 bg-slate-900 hover:bg-slate-800 font-semibold text-white rounded-xl text-xs transition-all">
            Create Ticket
          </button>
        </div>

        <div className="bg-white border border-slate-200 rounded-2xl p-6 space-y-4 shadow-sm">
          <div className="w-10 h-10 rounded-xl bg-emerald-50 text-emerald-600 border border-emerald-100 flex items-center justify-center">
            <HelpCircle className="w-5 h-5" />
          </div>
          <h3 className="font-bold text-slate-900 text-base">Browse FAQs</h3>
          <p className="text-xs text-slate-500">How to start charging, unlock connectors, or request refunds.</p>
          <button className="w-full py-2.5 bg-slate-100 hover:bg-slate-200 font-semibold text-slate-700 rounded-xl text-xs border border-slate-200 transition-all">
            View Articles
          </button>
        </div>
      </div>
    </div>
  );
};
