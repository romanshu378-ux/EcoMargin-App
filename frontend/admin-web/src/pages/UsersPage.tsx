import React, { useEffect, useState } from 'react';
import { Users, Search, Lock, Unlock, PlusCircle, Shield, CheckCircle, AlertTriangle } from 'lucide-react';
import { adminApi } from '../services/api';

export const UsersPage: React.FC = () => {
  const [users, setUsers] = useState<any[]>([]);
  const [loading, setLoading] = useState(false);
  const [search, setSearch] = useState('');
  const [roleFilter, setRoleFilter] = useState('ALL');

  // Top up modal state
  const [selectedUser, setSelectedUser] = useState<any>(null);
  const [topupAmount, setTopupAmount] = useState('100');
  const [topupReason, setTopupReason] = useState('Admin Wallet Adjustment');
  const [topupSuccess, setTopupSuccess] = useState('');

  useEffect(() => {
    fetchUsers();
  }, []);

  const fetchUsers = async () => {
    try {
      setLoading(true);
      const res = await adminApi.getUsers();
      setUsers(res.data || []);
    } catch (err) {
      console.error('Failed to fetch users:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleToggleStatus = async (user: any) => {
    try {
      await adminApi.updateUserStatus(user.id, { isLocked: user.isAccountNonLocked });
      fetchUsers();
    } catch (err) {
      console.error('Failed to update user status:', err);
    }
  };

  const handleRoleChange = async (userId: number, newRole: string) => {
    try {
      await adminApi.updateUserRole(userId, newRole);
      fetchUsers();
    } catch (err) {
      console.error('Failed to update user role:', err);
    }
  };

  const handleTopupWallet = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedUser) return;
    try {
      await adminApi.creditUserWallet(selectedUser.id, parseFloat(topupAmount), topupReason);
      setTopupSuccess(`Successfully credited ₹${topupAmount} to ${selectedUser.email}`);
      setTimeout(() => {
        setTopupSuccess('');
        setSelectedUser(null);
      }, 2000);
      fetchUsers();
    } catch (err) {
      console.error('Failed to top up wallet:', err);
    }
  };

  const filteredUsers = users.filter((u) => {
    const matchesSearch =
      (u.firstName || '').toLowerCase().includes(search.toLowerCase()) ||
      (u.lastName || '').toLowerCase().includes(search.toLowerCase()) ||
      (u.email || '').toLowerCase().includes(search.toLowerCase());

    const matchesRole =
      roleFilter === 'ALL' ||
      (u.roles || []).some((r: string) => r.includes(roleFilter));

    return matchesSearch && matchesRole;
  });

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-xl font-bold text-white">User Directory & RBAC Management</h1>
          <p className="text-xs text-slate-400">Manage drivers, vendors, admins, and RBAC permissions</p>
        </div>
      </div>

      {topupSuccess && (
        <div className="p-4 bg-emerald-500/10 border border-emerald-500/30 rounded-xl text-emerald-400 text-xs flex items-center gap-2">
          <CheckCircle className="w-4 h-4" /> {topupSuccess}
        </div>
      )}

      {/* Controls */}
      <div className="flex gap-4 bg-slate-900 p-4 rounded-xl border border-slate-800">
        <div className="flex-1 relative">
          <Search className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-slate-500" />
          <input
            type="text"
            placeholder="Search by name or email..."
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
          <option value="CUSTOMER">CUSTOMERS</option>
          <option value="VENDOR">VENDORS</option>
          <option value="ADMIN">ADMINS</option>
          <option value="SUPER_ADMIN">SUPER ADMINS</option>
        </select>
      </div>

      {/* Users Table */}
      <div className="bg-slate-900 border border-slate-800 rounded-xl overflow-hidden">
        {loading ? (
          <div className="p-8 text-center text-slate-400 text-xs">Loading user directory...</div>
        ) : (
          <table className="w-full text-left text-xs text-slate-300">
            <thead className="bg-slate-950 text-slate-400 font-semibold border-b border-slate-800 uppercase tracking-wider">
              <tr>
                <th className="p-4">User</th>
                <th className="p-4">Role</th>
                <th className="p-4">Status</th>
                <th className="p-4">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-800">
              {filteredUsers.map((u) => (
                <tr key={u.id} className="hover:bg-slate-800/40">
                  <td className="p-4">
                    <p className="font-semibold text-white">
                      {u.firstName || ''} {u.lastName || ''}
                    </p>
                    <p className="text-[11px] text-slate-400">{u.email}</p>
                    <p className="text-[10px] text-slate-500">{u.phoneNumber || ''}</p>
                  </td>
                  <td className="p-4">
                    <select
                      value={(u.roles && u.roles[0]) || 'ROLE_CUSTOMER'}
                      onChange={(e) => handleRoleChange(u.id, e.target.value)}
                      className="bg-slate-950 border border-slate-800 rounded-md text-[11px] text-slate-200 px-2 py-1 focus:outline-none focus:border-emerald-500"
                    >
                      <option value="ROLE_CUSTOMER">CUSTOMER</option>
                      <option value="ROLE_VENDOR">VENDOR</option>
                      <option value="ROLE_ADMIN">ADMIN</option>
                      <option value="ROLE_SUPER_ADMIN">SUPER_ADMIN</option>
                    </select>
                  </td>
                  <td className="p-4">
                    <span
                      className={`px-2.5 py-1 rounded-md text-[10px] font-bold ${
                        u.accountNonLocked
                          ? 'bg-emerald-500/20 text-emerald-400'
                          : 'bg-rose-500/20 text-rose-400'
                      }`}
                    >
                      {u.accountNonLocked ? 'ACTIVE' : 'LOCKED'}
                    </span>
                  </td>
                  <td className="p-4 space-x-2">
                    <button
                      onClick={() => handleToggleStatus(u)}
                      className={`px-3 py-1 text-[11px] rounded-lg transition-all border ${
                        u.accountNonLocked
                          ? 'bg-rose-500/10 hover:bg-rose-500/20 text-rose-400 border-rose-500/20'
                          : 'bg-emerald-500/10 hover:bg-emerald-500/20 text-emerald-400 border-emerald-500/20'
                      }`}
                    >
                      {u.accountNonLocked ? 'Lock Account' : 'Unlock Account'}
                    </button>

                    <button
                      onClick={() => setSelectedUser(u)}
                      className="px-3 py-1 bg-emerald-500/20 hover:bg-emerald-500/30 text-emerald-400 border border-emerald-500/30 rounded-lg text-[11px] transition-all"
                    >
                      Credit Wallet
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>

      {/* Topup Modal */}
      {selectedUser && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center p-4 z-50">
          <div className="bg-slate-900 border border-slate-800 rounded-2xl p-6 max-w-md w-full space-y-4">
            <h3 className="text-sm font-bold text-white">Credit Wallet: {selectedUser.email}</h3>
            <form onSubmit={handleTopupWallet} className="space-y-4">
              <div>
                <label className="block text-xs text-slate-400 mb-1">Amount (₹)</label>
                <input
                  type="number"
                  value={topupAmount}
                  onChange={(e) => setTopupAmount(e.target.value)}
                  className="w-full px-3 py-2 bg-slate-950 border border-slate-800 rounded-xl text-xs text-white"
                  required
                />
              </div>
              <div>
                <label className="block text-xs text-slate-400 mb-1">Reason / Note</label>
                <input
                  type="text"
                  value={topupReason}
                  onChange={(e) => setTopupReason(e.target.value)}
                  className="w-full px-3 py-2 bg-slate-950 border border-slate-800 rounded-xl text-xs text-white"
                  required
                />
              </div>
              <div className="flex justify-end gap-2 pt-2">
                <button
                  type="button"
                  onClick={() => setSelectedUser(null)}
                  className="px-4 py-2 bg-slate-800 text-slate-300 text-xs rounded-xl"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="px-4 py-2 bg-emerald-500 text-white text-xs font-semibold rounded-xl"
                >
                  Credit Funds
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
