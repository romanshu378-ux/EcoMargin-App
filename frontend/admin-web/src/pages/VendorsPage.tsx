import React from 'react';
import { Building2, CheckCircle2, Clock, XCircle, MapPin, Zap } from 'lucide-react';

export const VendorsPage: React.FC = () => {
  const vendors = [
    { id: 'VND-001', company: 'ChargeTech Global', contact: 'Robert Miller', email: 'robert@chargetech.com', stations: 14, chargers: 48, status: 'APPROVED', date: '2026-01-10' },
    { id: 'VND-002', company: 'GreenPower Networks', contact: 'Elena Rostova', email: 'elena@greenpower.io', stations: 8, chargers: 24, status: 'APPROVED', date: '2026-01-22' },
    { id: 'VND-003', company: 'VoltWay Mobility', contact: 'Marcus Vance', email: 'mvance@voltway.com', stations: 0, chargers: 0, status: 'PENDING_APPROVAL', date: '2026-03-01' },
  ];

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-xl font-bold text-white">CPO Vendor Management</h1>
          <p className="text-xs text-slate-400">Approve, monitor and manage Charge Point Operators</p>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        {vendors.map((v) => (
          <div key={v.id} className="bg-slate-900 border border-slate-800 rounded-2xl p-5 space-y-4">
            <div className="flex justify-between items-start">
              <div>
                <h3 className="font-bold text-white text-base">{v.company}</h3>
                <p className="text-xs text-slate-400">{v.contact} • {v.email}</p>
              </div>
              <span className={`px-2.5 py-1 rounded-md text-[10px] font-bold ${
                v.status === 'APPROVED' ? 'bg-emerald-500/20 text-emerald-400' : 'bg-amber-500/20 text-amber-400'
              }`}>
                {v.status}
              </span>
            </div>

            <div className="grid grid-cols-2 gap-2 bg-slate-950 p-3 rounded-xl text-xs">
              <div className="flex items-center gap-2 text-slate-300">
                <MapPin className="w-4 h-4 text-emerald-400" />
                <span>{v.stations} Stations</span>
              </div>
              <div className="flex items-center gap-2 text-slate-300">
                <Zap className="w-4 h-4 text-amber-400" />
                <span>{v.chargers} Chargers</span>
              </div>
            </div>

            <div className="flex gap-2 pt-2 border-t border-slate-800">
              {v.status === 'PENDING_APPROVAL' ? (
                <>
                  <button className="flex-1 py-2 bg-emerald-500 hover:bg-emerald-600 font-semibold text-white rounded-lg text-xs transition-all">
                    Approve CPO
                  </button>
                  <button className="px-3 py-2 bg-rose-500/10 hover:bg-rose-500/20 text-rose-400 rounded-lg text-xs transition-all">
                    Reject
                  </button>
                </>
              ) : (
                <button className="w-full py-2 bg-slate-800 hover:bg-slate-700 font-semibold text-slate-200 rounded-lg text-xs transition-all">
                  Manage CPO Account
                </button>
              )}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};
