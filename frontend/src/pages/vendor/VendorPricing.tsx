import React, { useState } from 'react';
import { DollarSign, Percent, Clock, Check } from 'lucide-react';
import { useNotificationStore } from '../../store/notificationStore';

export default function VendorPricing() {
  const addNotification = useNotificationStore(state => state.addNotification);
  const [pricing, setPricing] = useState({
    baseRate: 0.35,
    idleFee: 0.15,
    peakRate: 0.45
  });

  const savePricing = (e: React.FormEvent) => {
    e.preventDefault();
    addNotification({
      title: 'Pricing Model Updated',
      message: 'New billing parameters applied across all connectors.',
      type: 'success'
    });
  };

  return (
    <div className="space-y-6 max-w-2xl">
      <h2 className="text-xl font-bold tracking-tight">Tariff & Pricing Management</h2>

      <div className="bg-white dark:bg-gray-900 border border-gray-200 dark:border-gray-800 rounded-2xl p-6 shadow-sm">
        <form onSubmit={savePricing} className="space-y-6 text-xs">
          
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-6">
            <div className="space-y-2">
              <label className="font-semibold text-gray-500">Standard rate (per kWh)</label>
              <div className="relative">
                <input 
                  type="number" step="0.01" 
                  value={pricing.baseRate}
                  onChange={(e) => setPricing(prev => ({ ...prev, baseRate: parseFloat(e.target.value) }))}
                  className="w-full bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700 pl-8 pr-4 py-2.5 rounded-xl outline-none" 
                />
                <DollarSign size={14} className="absolute left-3 top-3.5 text-gray-400" />
              </div>
            </div>

            <div className="space-y-2">
              <label className="font-semibold text-gray-500">Idle Fee (per minute)</label>
              <div className="relative">
                <input 
                  type="number" step="0.01" 
                  value={pricing.idleFee}
                  onChange={(e) => setPricing(prev => ({ ...prev, idleFee: parseFloat(e.target.value) }))}
                  className="w-full bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700 pl-8 pr-4 py-2.5 rounded-xl outline-none" 
                />
                <Clock size={14} className="absolute left-3 top-3.5 text-gray-400" />
              </div>
            </div>

            <div className="space-y-2">
              <label className="font-semibold text-gray-500">Peak Tariffs (per kWh)</label>
              <div className="relative">
                <input 
                  type="number" step="0.01" 
                  value={pricing.peakRate}
                  onChange={(e) => setPricing(prev => ({ ...prev, peakRate: parseFloat(e.target.value) }))}
                  className="w-full bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700 pl-8 pr-4 py-2.5 rounded-xl outline-none" 
                />
                <Percent size={14} className="absolute left-3 top-3.5 text-gray-400" />
              </div>
            </div>
          </div>

          <div className="border-t border-gray-100 dark:border-gray-800 pt-4 flex justify-end">
            <button type="submit" className="flex items-center gap-1.5 bg-emerald-600 hover:bg-emerald-700 text-white px-4 py-2.5 rounded-xl text-xs font-bold shadow-md transition-all">
              <Check size={16} /> Save Tariff Settings
            </button>
          </div>

        </form>
      </div>
    </div>
  );
}
