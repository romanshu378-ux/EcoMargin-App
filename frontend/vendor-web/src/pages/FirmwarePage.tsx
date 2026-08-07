import React from 'react';
import { Cpu, Upload, CheckCircle2, AlertTriangle } from 'lucide-react';

export const FirmwarePage: React.FC = () => {
  const firmwares = [
    { id: 'FW-v2.4.1', model: 'ChargeTech FastCharger 150', version: 'v2.4.1-stable', md5: 'e99a18c428cb38d5f260853678922e03', status: 'DEPLOYED' },
    { id: 'FW-v2.5.0-beta', model: 'ChargeTech FastCharger 150', version: 'v2.5.0-beta', md5: '782b99c104ab48e21903450912ab9901', status: 'TESTING' },
  ];

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-xl font-bold text-white">OTA Firmware Management</h1>
          <p className="text-xs text-slate-400">Deploy Over-The-Air firmware updates to OCPP chargers</p>
        </div>
        <button className="flex items-center gap-2 px-4 py-2.5 bg-amber-500 hover:bg-amber-600 font-semibold text-white rounded-xl text-xs transition-all shadow-lg shadow-amber-500/20">
          <Upload className="w-4 h-4" /> Upload Firmware Binary (.bin)
        </button>
      </div>

      <div className="bg-slate-900 border border-slate-800 rounded-xl overflow-hidden">
        <table className="w-full text-left text-xs text-slate-300">
          <thead className="bg-slate-950 text-slate-400 font-semibold border-b border-slate-800 uppercase tracking-wider">
            <tr>
              <th className="p-4">Firmware Package</th>
              <th className="p-4">Hardware Model</th>
              <th className="p-4">Version</th>
              <th className="p-4">MD5 Checksum</th>
              <th className="p-4">Status</th>
              <th className="p-4 text-right">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-800">
            {firmwares.map((f) => (
              <tr key={f.id} className="hover:bg-slate-800/40">
                <td className="p-4 font-bold text-white">{f.id}</td>
                <td className="p-4 text-slate-200">{f.model}</td>
                <td className="p-4 font-mono text-amber-400">{f.version}</td>
                <td className="p-4 font-mono text-slate-500 text-[10px]">{f.md5}</td>
                <td className="p-4">
                  <span className={`px-2 py-0.5 rounded text-[10px] font-bold ${
                    f.status === 'DEPLOYED' ? 'bg-emerald-500/20 text-emerald-400' : 'bg-amber-500/20 text-amber-400'
                  }`}>
                    {f.status}
                  </span>
                </td>
                <td className="p-4 text-right">
                  <button className="px-3 py-1 bg-amber-500/10 hover:bg-amber-500/20 text-amber-400 border border-amber-500/20 rounded-lg text-[11px]">
                    Push OTA Update
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
