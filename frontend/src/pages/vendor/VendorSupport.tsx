import React, { useState } from 'react';
import { HelpCircle, Plus, Send, MessageCircle } from 'lucide-react';
import { useNotificationStore } from '../../store/notificationStore';

interface Ticket {
  id: string;
  subject: string;
  description: string;
  status: 'OPEN' | 'IN_PROGRESS' | 'RESOLVED';
  priority: 'MEDIUM' | 'HIGH' | 'URGENT';
}

export default function VendorSupport() {
  const addNotification = useNotificationStore(state => state.addNotification);
  const [tickets, setTickets] = useState<Ticket[]>([
    { id: 'TCK-892', subject: 'OCPP connection drops on dual-CCS2 model', description: 'Austin Downtown Hub dual-connector charger shows offline status intermittently.', status: 'IN_PROGRESS', priority: 'HIGH' },
    { id: 'TCK-891', subject: 'Billing webhook failure on deposits', description: 'Vendor deposits not updating instantly in wallet.', status: 'RESOLVED', priority: 'MEDIUM' },
  ]);

  const submitTicket = (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const data = new FormData(e.currentTarget);
    const subject = data.get('subject') as string;
    const description = data.get('description') as string;
    const priority = data.get('priority') as Ticket['priority'];

    addNotification({
      title: 'Support Ticket Created',
      message: `Ticket "${subject}" submitted successfully.`,
      type: 'success'
    });

    setTickets(prev => [
      {
        id: 'TCK-' + Math.floor(100 + Math.random() * 900),
        subject,
        description,
        status: 'OPEN',
        priority
      },
      ...prev
    ]);
    e.currentTarget.reset();
  };

  return (
    <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
      
      {/* List Tickets */}
      <div className="lg:col-span-2 space-y-4">
        <h3 className="font-bold text-sm tracking-wide">CPO Support Inquiries</h3>
        <div className="space-y-4">
          {tickets.map(t => (
            <div key={t.id} className="bg-white dark:bg-gray-900 border border-gray-200 dark:border-gray-800 rounded-2xl p-6 shadow-sm space-y-3">
              <div className="flex justify-between items-start">
                <div className="space-y-1">
                  <span className="text-[10px] text-gray-400 font-bold">{t.id}</span>
                  <h4 className="font-bold text-xs leading-tight">{t.subject}</h4>
                </div>
                <div className="flex gap-2">
                  <span className={`px-2 py-0.5 rounded text-[9px] font-bold ${
                    t.priority === 'URGENT' ? 'bg-red-100 text-red-800' : t.priority === 'HIGH' ? 'bg-amber-100 text-amber-800' : 'bg-gray-100 text-gray-800'
                  }`}>{t.priority}</span>
                  <span className={`px-2.5 py-0.5 rounded-full text-[9px] font-bold ${
                    t.status === 'RESOLVED' ? 'bg-emerald-100 text-emerald-800' : 'bg-amber-100 text-amber-800'
                  }`}>{t.status}</span>
                </div>
              </div>
              <p className="text-xs text-gray-500 dark:text-gray-400">{t.description}</p>
            </div>
          ))}
        </div>
      </div>

      {/* Create Ticket */}
      <div className="bg-white dark:bg-gray-900 border border-gray-200 dark:border-gray-800 rounded-2xl p-6 shadow-sm space-y-4 h-fit">
        <div className="flex items-center gap-2">
          <div className="p-2 bg-emerald-50 dark:bg-emerald-950 text-emerald-600 dark:text-emerald-400 rounded-lg">
            <MessageCircle size={18} />
          </div>
          <span className="font-bold text-sm tracking-wide">Open Support Request</span>
        </div>

        <form onSubmit={submitTicket} className="space-y-4 text-xs">
          <div className="space-y-1">
            <label className="font-semibold text-gray-500">Inquiry Subject</label>
            <input required name="subject" placeholder="Summarize your issue..." className="w-full bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700 px-4 py-2.5 rounded-xl outline-none" />
          </div>
          
          <div className="space-y-1">
            <label className="font-semibold text-gray-500">Priority Level</label>
            <select name="priority" className="w-full bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700 px-4 py-2.5 rounded-xl outline-none">
              <option value="MEDIUM">Medium</option>
              <option value="HIGH">High</option>
              <option value="URGENT">Urgent</option>
            </select>
          </div>

          <div className="space-y-1">
            <label className="font-semibold text-gray-500">Detailed Description</label>
            <textarea required name="description" rows={4} placeholder="Describe the fault details, error codes, or timestamp of the issue..." className="w-full bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700 px-4 py-2.5 rounded-xl outline-none resize-none"></textarea>
          </div>

          <button type="submit" className="w-full py-3 bg-emerald-600 hover:bg-emerald-700 text-white font-bold rounded-xl transition-all shadow-md flex items-center justify-center gap-1.5">
            <Send size={14} /> Submit Support Request
          </button>
        </form>
      </div>

    </div>
  );
}
