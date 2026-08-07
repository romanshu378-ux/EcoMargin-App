import React, { useState } from 'react';
import { ShieldCheck, Plus, CheckCircle, XCircle } from 'lucide-react';
import { useNotificationStore } from '../store/notificationStore';

interface Vendor {
  id: string;
  businessName: string;
  taxId: string;
  status: 'ACTIVE' | 'PENDING' | 'SUSPENDED';
}

export default function VendorsPage() {
  const addNotification = useNotificationStore(state => state.addNotification);
  const [vendors, setVendors] = useState<Vendor[]>([
    { id: '1', businessName: 'EcoCharge Networks LLC', taxId: 'TX-987654321', status: 'ACTIVE' },
    { id: '2', businessName: 'VoltWay Operators', taxId: 'TX-123456789', status: 'PENDING' },
  ]);

  const updateStatus = (id: string, name: string, status: Vendor['status']) => {
    setVendors(prev => prev.map(v => {
      if (v.id === id) {
        addNotification({
          title: 'Vendor Status Updated',
          message: `${name} has been set to ${status}`,
          type: status === 'ACTIVE' ? 'success' : 'warning'
        });
        return { ...v, status };
      }
      return v;
    }));
  };

  return (
    <div className="space-y-6">
      <h2 className="text-xl font-bold tracking-tight">Vendor Management (CPOs)</h2>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {vendors.map(v => (
          <div key={v.id} className="bg-white dark:bg-gray-900 border border-gray-200 dark:border-gray-800 rounded-2xl p-6 shadow-sm space-y-4">
            <div className="flex items-center justify-between border-b border-gray-100 dark:border-gray-800/80 pb-4">
              <div>
                <h3 className="font-bold text-sm">{v.businessName}</h3>
                <p className="text-[10px] text-gray-400">Tax ID: {v.taxId}</p>
              </div>
              <span className={`px-2.5 py-0.5 rounded-full text-[10px] font-bold ${
                v.status === 'ACTIVE' 
                  ? 'bg-emerald-100 text-emerald-800' 
                  : v.status === 'PENDING' 
                  ? 'bg-amber-100 text-amber-800' 
                  : 'bg-rose-100 text-rose-800'
              }`}>
                {v.status}
              </span>
            </div>

            <div className="flex gap-2">
              <button 
                onClick={() => updateStatus(v.id, v.businessName, 'ACTIVE')}
                disabled={v.status === 'ACTIVE'}
                className="flex-1 py-2 bg-emerald-50 text-emerald-600 hover:bg-emerald-100 text-[10px] font-bold rounded-xl transition-all disabled:opacity-40 disabled:cursor-not-allowed"
              >
                Approve Vendor
              </button>
              <button 
                onClick={() => updateStatus(v.id, v.businessName, 'SUSPENDED')}
                disabled={v.status === 'SUSPENDED'}
                className="flex-1 py-2 bg-rose-50 text-rose-600 hover:bg-rose-100 text-[10px] font-bold rounded-xl transition-all disabled:opacity-40 disabled:cursor-not-allowed"
              >
                Suspend
              </button>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
