import React, { useState } from 'react';
import { Users, Search, UserCheck, Lock, Unlock, Filter } from 'lucide-react';

export const UsersPage: React.FC = () => {
  const [search, setSearch] = useState('');
  const [roleFilter, setRoleFilter] = useState('ALL');

  const users = [
    { id: 'USR-101', name: 'Alex Rivers', email: 'alex@example.com', role: 'DRIVER', status: 'ACTIVE', wallet: '$45.00', joined: '2026-01-15' },
    { id: 'USR-102', name: 'ChargeTech Solutions', email: 'contact@chargetech.io', role: 'VENDOR', status: 'ACTIVE', wallet: '$1,250.00', joined: '2026-02-01' },
    { id: 'USR-103', name: 'Sarah Jenkins', email: 'sarah@example.com', role: 'DRIVER', status: 'ACTIVE', wallet: '$120.50', joined: '2026-02-10' },
    { id: 'USR-104', name: 'Michael Vance', email: 'michael@example.com', role: 'DRIVER', status: 'SUSPENDED', wallet: '$0.00', joined: '2026-03-05' },
  ];

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-xl font-bold text-white">User Directory & Management</h1>
          <p className="text-xs text-slate-400">Manage drivers, CPO vendors, and administrative roles</p>
        </div>
      </div>

      {/* Controls */}
      <div className="flex gap-4 bg-slate-900 p-4 rounded-xl border border-slate-800">
        <div className="flex-1 relative">
          <Search className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-slate-500" />
          <input
            type="text"
            placeholder="Search by name, email or ID..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="w-full pl-9 pr-4 py-2 bg-slate-950 border border-slate-800 rounded-lg text-xs text-slate-100 focus:outline-none focus:border-emerald-500"
          />
        </div>
        <select
          value={roleFilter}
          onChange={(e) => setRoleFilter(e.target.value)}
          className="bg-slate-950 border border-slate-800 rounded-lg text-xs text-slate-300 px-3 py-2 focus:outline-none focus:border-emerald-500"
        >
          <option value="ALL">All Roles</option>
          <option value="DRIVER">EV Drivers</option>
          <option value="VENDOR">CPO Vendors</option>
          <option value="ADMIN">Admins</option>
        </select>
      </div>

      {/* Users Table */}
      <div className="bg-slate-900 border border-slate-800 rounded-xl overflow-hidden">
        <table className="w-full text-left text-xs text-slate-300">
          <thead className="bg-slate-950 text-slate-400 font-semibold border-b border-slate-800 uppercase tracking-wider">
            <tr>
              <th className="p-4">User</th>
              <th className="p-4">Role</th>
              <th className="p-4">Status</th>
              <th className="p-4">Wallet Balance</th>
              <th className="p-4">Joined Date</th>
              <th className="p-4 text-right">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-800">
            {users.map((u) => (
              <tr key={u.id} className="hover:bg-slate-800/40">
                <td className="p-4">
                  <p className="font-semibold text-white">{u.name}</p>
                  <p className="text-[11px] text-slate-400">{u.email}</p>
                </td>
                <td className="p-4">
                  <span className={`px-2.5 py-1 rounded-md text-[10px] font-bold ${
                    u.role === 'ADMIN' ? 'bg-purple-500/20 text-purple-400' :
                    u.role === 'VENDOR' ? 'bg-amber-500/20 text-amber-400' : 'bg-blue-500/20 text-blue-400'
                  }`}>
                    {u.role}
                  </span>
                </td>
                <td className="p-4">
                  <span className={`px-2.5 py-1 rounded-md text-[10px] font-bold ${
                    u.status === 'ACTIVE' ? 'bg-emerald-500/20 text-emerald-400' : 'bg-rose-500/20 text-rose-400'
                  }`}>
                    {u.status}
                  </span>
                </td>
                <td className="p-4 font-mono font-medium text-emerald-400">{u.wallet}</td>
                <td className="p-4 text-slate-400">{u.joined}</td>
                <td className="p-4 text-right space-x-2">
                  <button className="px-3 py-1 bg-slate-800 hover:bg-slate-700 text-slate-200 rounded-lg transition-all text-[11px]">
                    Edit
                  </button>
                  <button className="px-3 py-1 bg-rose-500/10 hover:bg-rose-500/20 text-rose-400 border border-rose-500/20 rounded-lg transition-all text-[11px]">
                    Suspend
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
};
