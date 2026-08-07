import React from 'react';
import { Calendar, Clock, MapPin, CheckCircle } from 'lucide-react';

export const BookingPage: React.FC = () => {
  const bookings = [
    { id: 'RES-108', station: 'Downtown Hub Fast Charge', plug: 'CCS2 150kW (Pillar #2)', slot: 'Today, 14:00 - 15:00', status: 'CONFIRMED' },
  ];

  return (
    <div className="space-y-6 max-w-5xl mx-auto py-8 px-4">
      <div>
        <h1 className="text-2xl font-bold text-white">Connector Reservations</h1>
        <p className="text-xs text-slate-400">Reserve charging slots in advance to guarantee zero waiting time</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {bookings.map((b) => (
          <div key={b.id} className="bg-slate-900 border border-slate-800 rounded-2xl p-5 space-y-4">
            <div className="flex justify-between items-start">
              <div>
                <span className="text-[10px] font-mono font-bold text-emerald-400">{b.id}</span>
                <h3 className="font-bold text-white text-base">{b.station}</h3>
                <p className="text-xs text-slate-400">{b.plug}</p>
              </div>
              <span className="px-2.5 py-1 rounded text-[10px] font-bold bg-emerald-500/20 text-emerald-400 flex items-center gap-1">
                <CheckCircle className="w-3 h-3" /> {b.status}
              </span>
            </div>

            <div className="bg-slate-950 p-3 rounded-xl flex items-center gap-2 text-xs text-slate-300">
              <Clock className="w-4 h-4 text-emerald-400" />
              <span>{b.slot}</span>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};
