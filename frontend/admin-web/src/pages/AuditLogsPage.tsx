import React, { useEffect, useState } from 'react';
import { ShieldAlert, Search, RefreshCw, FileText } from 'lucide-react';
import { adminApi } from '../services/api';

export const AuditLogsPage: React.FC = () => {
  const [logs, setLogs] = useState<any[]>([]);
  const [loading, setLoading] = useState(false);
  const [search, setSearch] = useState('');

  useEffect(() => {
    fetchLogs();
  }, []);

  const fetchLogs = async () => {
    try {
      setLoading(true);
      const res = await adminApi.getAuditLogs();
      setLogs(res.data || []);
    } catch (err) {
      console.error('Failed to fetch audit logs:', err);
    } finally {
      setLoading(false);
    }
  };

  const filteredLogs = logs.filter((log) => {
    const q = search.toLowerCase();
    return (
      (log.action || '').toLowerCase().includes(q) ||
      (log.performedBy || '').toLowerCase().includes(q) ||
      (log.entityName || '').toLowerCase().includes(q) ||
      (log.details || '').toLowerCase().includes(q)
    );
  });

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-xl font-bold text-white flex items-center gap-2">
            <ShieldAlert className="w-5 h-5 text-emerald-400" /> Administrative Audit Logs
          </h1>
          <p className="text-xs text-slate-400">Complete immutable record of who changed what, when, and previous vs new values</p>
        </div>
        <button
          onClick={fetchLogs}
          className="flex items-center gap-2 px-4 py-2 bg-slate-900 border border-slate-800 hover:border-slate-700 text-xs text-slate-200 rounded-xl transition-all"
        >
          <RefreshCw className={`w-3.5 h-3.5 ${loading ? 'animate-spin' : ''}`} /> Refresh Logs
        </button>
      </div>

      <div className="flex gap-4 bg-slate-900 p-4 rounded-xl border border-slate-800">
        <div className="flex-1 relative">
          <Search className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-slate-500" />
          <input
            type="text"
            placeholder="Search audit logs by action, performer, entity..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="w-full pl-9 pr-4 py-2 bg-slate-950 border border-slate-800 rounded-lg text-xs text-slate-100 focus:outline-none focus:border-emerald-500"
          />
        </div>
      </div>

      <div className="bg-slate-900 border border-slate-800 rounded-xl overflow-hidden">
        {loading ? (
          <div className="p-8 text-center text-slate-400 text-xs">Loading audit logs...</div>
        ) : (
          <table className="w-full text-left text-xs text-slate-300">
            <thead className="bg-slate-950 text-slate-400 font-semibold border-b border-slate-800 uppercase tracking-wider">
              <tr>
                <th className="p-4">Timestamp</th>
                <th className="p-4">Performed By</th>
                <th className="p-4">Action</th>
                <th className="p-4">Target Entity</th>
                <th className="p-4">Previous Value</th>
                <th className="p-4">New Value</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-800 font-mono text-[11px]">
              {filteredLogs.length === 0 ? (
                <tr>
                  <td colSpan={6} className="p-8 text-center text-slate-500">
                    No audit log records found.
                  </td>
                </tr>
              ) : (
                filteredLogs.map((item, idx) => (
                  <tr key={idx} className="hover:bg-slate-800/40">
                    <td className="p-4 text-slate-400 font-sans">
                      {item.createdAt ? new Date(item.createdAt).toLocaleString() : 'N/A'}
                    </td>
                    <td className="p-4 font-semibold text-emerald-400 font-sans">
                      {item.performedBy || 'SYSTEM'}
                    </td>
                    <td className="p-4">
                      <span className="px-2 py-1 bg-emerald-500/10 text-emerald-400 border border-emerald-500/20 rounded-md font-bold text-[10px]">
                        {item.action}
                      </span>
                    </td>
                    <td className="p-4 text-slate-200">
                      {item.entityName || '-'} {item.entityId ? `#${item.entityId}` : ''}
                    </td>
                    <td className="p-4 text-slate-400 truncate max-w-xs" title={item.previousValue}>
                      {item.previousValue || '-'}
                    </td>
                    <td className="p-4 text-emerald-300 truncate max-w-xs" title={item.newValue}>
                      {item.newValue || '-'}
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
};
