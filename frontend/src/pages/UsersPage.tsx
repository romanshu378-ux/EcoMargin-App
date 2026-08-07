import React, { useState } from 'react';
import { Search, UserCheck, ShieldAlert, Ban } from 'lucide-react';
import { useNotificationStore } from '../store/notificationStore';

interface User {
  id: string;
  email: string;
  name: string;
  role: 'CUSTOMER' | 'VENDOR' | 'ADMIN';
  isVerified: boolean;
  isLocked: boolean;
}

export default function UsersPage() {
  const addNotification = useNotificationStore(state => state.addNotification);
  const [users, setUsers] = useState<User[]>([
    { id: '1', email: 'admin@ecomargin.com', name: 'Platform Admin', role: 'ADMIN', isVerified: true, isLocked: false },
    { id: '2', email: 'vendor@ecomargin.com', name: 'John CPO', role: 'VENDOR', isVerified: true, isLocked: false },
    { id: '3', email: 'customer@ecomargin.com', name: 'Jane Driver', role: 'CUSTOMER', isVerified: true, isLocked: false },
    { id: '4', email: 'test_driver@ecomargin.com', name: 'Bob Driver', role: 'CUSTOMER', isVerified: false, isLocked: true },
  ]);

  const toggleLock = (id: string, name: string) => {
    setUsers(prev => prev.map(u => {
      if (u.id === id) {
        const nextState = !u.isLocked;
        addNotification({
          title: nextState ? 'Account Locked' : 'Account Unlocked',
          message: `${name} has been ${nextState ? 'locked' : 'unlocked'}.`,
          type: 'warning'
        });
        return { ...u, isLocked: nextState };
      }
      return u;
    }));
  };

  return (
    <div className="space-y-6">
      <h2 className="text-xl font-bold tracking-tight">User Management</h2>

      <div className="bg-white dark:bg-gray-900 border border-gray-200 dark:border-gray-800 rounded-2xl p-6 shadow-sm space-y-4">
        
        {/* Table Filter Search */}
        <div className="relative max-w-sm">
          <input placeholder="Search users by name/email..." className="w-full bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700 pl-10 pr-4 py-2 rounded-xl text-xs outline-none" />
          <Search size={16} className="absolute left-3.5 top-2.5 text-gray-400" />
        </div>

        {/* Users Table */}
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs border-collapse">
            <thead>
              <tr className="border-b border-gray-200 dark:border-gray-800 text-gray-400">
                <th className="py-3 font-semibold">Name</th>
                <th className="py-3 font-semibold">Email</th>
                <th className="py-3 font-semibold">Role</th>
                <th className="py-3 font-semibold">Status</th>
                <th className="py-3 font-semibold text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100 dark:divide-gray-800/80">
              {users.map(u => (
                <tr key={u.id} className="hover:bg-gray-50 dark:hover:bg-gray-800/30 transition-colors">
                  <td className="py-4 font-semibold">{u.name}</td>
                  <td className="py-4 text-gray-500 dark:text-gray-400">{u.email}</td>
                  <td className="py-4 font-bold">{u.role}</td>
                  <td className="py-4">
                    <span className={`px-2.5 py-0.5 rounded-full text-[10px] font-bold ${
                      u.isLocked 
                        ? 'bg-rose-100 text-rose-800' 
                        : u.isVerified 
                        ? 'bg-emerald-100 text-emerald-800' 
                        : 'bg-amber-100 text-amber-800'
                    }`}>
                      {u.isLocked ? 'LOCKED' : u.isVerified ? 'VERIFIED' : 'PENDING'}
                    </span>
                  </td>
                  <td className="py-4 text-right">
                    <button 
                      onClick={() => toggleLock(u.id, u.name)}
                      className={`px-3 py-1.5 rounded-lg text-[10px] font-bold transition-all ${
                        u.isLocked 
                          ? 'bg-emerald-50 text-emerald-600 hover:bg-emerald-100' 
                          : 'bg-rose-50 text-rose-600 hover:bg-rose-100'
                      }`}
                    >
                      {u.isLocked ? 'Unlock' : 'Block User'}
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

      </div>
    </div>
  );
}
