import React, { useState } from 'react';
import { MapPin, Power, Radio, Server, Plus, Search, Trash2 } from 'lucide-react';
import { useNotificationStore } from '../store/notificationStore';

interface Station {
  id: string;
  name: string;
  location: string;
  chargers: number;
  status: 'ACTIVE' | 'INACTIVE' | 'MAINTENANCE';
}

export default function StationsPage() {
  const addNotification = useNotificationStore(state => state.addNotification);
  const [stations, setStations] = useState<Station[]>([
    { id: '1', name: 'Austin Downtown Hub', location: '120 E 6th St, Austin, TX', chargers: 2, status: 'ACTIVE' },
    { id: '2', name: 'North Loop Charger Point', location: '5310 Airport Blvd, Austin, TX', chargers: 1, status: 'ACTIVE' },
    { id: '3', name: 'West Lake Hills Station', location: '3300 Bee Caves Rd, Austin, TX', chargers: 0, status: 'MAINTENANCE' },
  ]);

  const toggleStatus = (id: string) => {
    setStations(prev => prev.map(s => {
      if (s.id === id) {
        const nextStatus: Station['status'] = s.status === 'ACTIVE' ? 'INACTIVE' : 'ACTIVE';
        addNotification({
          title: 'Station Status Updated',
          message: `${s.name} is now ${nextStatus}`,
          type: 'info'
        });
        return { ...s, status: nextStatus };
      }
      return s;
    }));
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
        <h2 className="text-xl font-bold tracking-tight">Charging Stations</h2>
        <button className="flex items-center gap-2 bg-emerald-600 hover:bg-emerald-700 text-white px-4 py-2 rounded-xl text-xs font-semibold shadow-md transition-all">
          <Plus size={16} /> Add Station
        </button>
      </div>

      {/* Stations List */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {stations.map(station => (
          <div key={station.id} className="bg-white dark:bg-gray-900 border border-gray-200 dark:border-gray-800 rounded-2xl p-6 shadow-sm flex flex-col justify-between space-y-4 hover:border-emerald-500 dark:hover:border-emerald-500 transition-all">
            <div className="space-y-2">
              <div className="flex items-center justify-between">
                <span className={`px-2.5 py-0.5 rounded-full text-[10px] font-bold ${
                  station.status === 'ACTIVE' 
                    ? 'bg-emerald-100 dark:bg-emerald-950/80 text-emerald-800 dark:text-emerald-400' 
                    : station.status === 'MAINTENANCE'
                    ? 'bg-amber-100 dark:bg-amber-950/80 text-amber-800 dark:text-amber-400'
                    : 'bg-gray-100 dark:bg-gray-850 text-gray-800 dark:text-gray-400'
                }`}>
                  {station.status}
                </span>
                <span className="text-[10px] text-gray-400 font-semibold">{station.chargers} Chargers</span>
              </div>
              <h3 className="font-bold text-base leading-tight">{station.name}</h3>
              <p className="text-xs text-gray-500 dark:text-gray-400 flex items-center gap-1.5">
                <MapPin size={14} className="text-gray-400" /> {station.location}
              </p>
            </div>

            <div className="flex items-center justify-between border-t border-gray-100 dark:border-gray-800/80 pt-4">
              <button 
                onClick={() => toggleStatus(station.id)}
                className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-semibold transition-all ${
                  station.status === 'ACTIVE' 
                    ? 'bg-rose-50 dark:bg-rose-950/20 text-rose-600 dark:text-rose-400 hover:bg-rose-100' 
                    : 'bg-emerald-50 dark:bg-emerald-950/20 text-emerald-600 dark:text-emerald-400 hover:bg-emerald-100'
                }`}
              >
                <Power size={14} />
                {station.status === 'ACTIVE' ? 'Deactivate' : 'Activate'}
              </button>
              <button className="text-gray-400 hover:text-red-500 p-2 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-800/50 transition-colors">
                <Trash2 size={16} />
              </button>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
