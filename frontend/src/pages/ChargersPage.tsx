import React, { useState, useEffect } from 'react';
import { 
  BatteryCharging, RefreshCw, Radio, Play, Square, AlertTriangle, 
  Power, PowerOff, ShieldAlert, CheckCircle, Clock, Zap 
} from 'lucide-react';
import { useNotificationStore } from '../store/notificationStore';

interface ActiveSessionInfo {
  sessionId: number;
  userEmail: string;
  energyKwh: number;
  startedAt: string | null;
}

interface ConnectorInfo {
  id: number;
  connectorId: number;
  type: string;
  maxPowerKw: number;
  status: string;
  activeSession: ActiveSessionInfo | null;
}

interface ChargerDetailed {
  id: number;
  ocppId: string;
  brand: string;
  model: string;
  powerKw: number;
  status: string;
  online: boolean;
  lastSeen: string;
  stationId: number | null;
  stationName: string;
  connectors: ConnectorInfo[];
}

export default function ChargersPage() {
  const addNotification = useNotificationStore(state => state.addNotification);

  const [chargers, setChargers] = useState<ChargerDetailed[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);
  const [filter, setFilter] = useState<'ALL' | 'ONLINE' | 'OFFLINE' | 'CHARGING' | 'AVAILABLE' | 'FAULTED'>('ALL');

  // Confirmation Modals
  const [disableModalCharger, setDisableModalCharger] = useState<ChargerDetailed | null>(null);
  const [forceStopModalSessionId, setForceStopModalSessionId] = useState<number | null>(null);
  const [actionLoading, setActionLoading] = useState<boolean>(false);

  const fetchChargers = async () => {
    try {
      setLoading(true);
      setError(null);
      const token = localStorage.getItem('token');
      const response = await fetch('/api/v1/admin/chargers/detailed', {
        headers: {
          'Authorization': token ? `Bearer ${token}` : '',
          'Content-Type': 'application/json',
        },
      });

      if (!response.ok) {
        if (response.status === 403) {
          throw new Error('Access denied: Admin permissions required.');
        }
        throw new Error(`Failed to load chargers (HTTP ${response.status})`);
      }

      const data = await response.json();
      setChargers(data);
    } catch (err: any) {
      setError(err.message || 'Error connecting to backend server');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchChargers();
  }, []);

  const handleToggleEnableDisable = async (charger: ChargerDetailed) => {
    if (charger.status === 'DISABLED') {
      // Enable charger directly
      try {
        setActionLoading(true);
        const token = localStorage.getItem('token');
        const res = await fetch(`/api/v1/admin/chargers/${charger.id}/enable`, {
          method: 'PUT',
          headers: {
            'Authorization': token ? `Bearer ${token}` : '',
            'Content-Type': 'application/json',
          },
        });
        if (res.ok) {
          addNotification({
            title: 'Charger Enabled',
            message: `Charger ${charger.ocppId} has been enabled.`,
            type: 'success',
          });
          fetchChargers();
        } else {
          throw new Error('Failed to enable charger');
        }
      } catch (err: any) {
        addNotification({
          title: 'Error',
          message: err.message,
          type: 'error',
        });
      } finally {
        setActionLoading(false);
      }
    } else {
      // Open disable confirmation modal
      setDisableModalCharger(charger);
    }
  };

  const confirmDisableCharger = async () => {
    if (!disableModalCharger) return;
    try {
      setActionLoading(true);
      const token = localStorage.getItem('token');
      const res = await fetch(`/api/v1/admin/chargers/${disableModalCharger.id}/disable`, {
        method: 'PUT',
        headers: {
          'Authorization': token ? `Bearer ${token}` : '',
          'Content-Type': 'application/json',
        },
      });

      if (res.ok) {
        addNotification({
          title: 'Charger Disabled',
          message: `Charger ${disableModalCharger.ocppId} disabled. New customer sessions blocked.`,
          type: 'warning',
        });
        setDisableModalCharger(null);
        fetchChargers();
      } else {
        throw new Error('Failed to disable charger');
      }
    } catch (err: any) {
      addNotification({
        title: 'Error',
        message: err.message,
        type: 'error',
      });
    } finally {
      setActionLoading(false);
    }
  };

  const confirmForceStop = async () => {
    if (!forceStopModalSessionId) return;
    try {
      setActionLoading(true);
      const token = localStorage.getItem('token');
      const res = await fetch(`/api/v1/admin/sessions/${forceStopModalSessionId}/force-stop`, {
        method: 'POST',
        headers: {
          'Authorization': token ? `Bearer ${token}` : '',
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ reason: 'Admin Force Stop Command' }),
      });

      if (res.ok) {
        const result = await res.json();
        addNotification({
          title: 'Force Stop Completed',
          message: `Session #${forceStopModalSessionId} force-stopped successfully. Cost: ₹${result.totalCost}`,
          type: 'success',
        });
        setForceStopModalSessionId(null);
        fetchChargers();
      } else {
        const errorData = await res.json();
        throw new Error(errorData.message || 'Failed to force stop session');
      }
    } catch (err: any) {
      addNotification({
        title: 'Force Stop Error',
        message: err.message,
        type: 'error',
      });
    } finally {
      setActionLoading(false);
    }
  };

  // Filter Logic
  const filteredChargers = chargers.filter(c => {
    if (filter === 'ONLINE') return c.online;
    if (filter === 'OFFLINE') return !c.online;
    if (filter === 'CHARGING') return c.status === 'CHARGING';
    if (filter === 'AVAILABLE') return c.status === 'AVAILABLE';
    if (filter === 'FAULTED') return c.status === 'FAULTED' || c.status === 'ERROR';
    return true;
  });

  return (
    <div className="space-y-6">
      {/* Header Bar */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h2 className="text-xl font-bold tracking-tight">Admin Charger Monitoring & Control</h2>
          <p className="text-xs text-gray-500 dark:text-gray-400">Live hardware telemetry, connector availability, and admin override controls.</p>
        </div>
        <button
          onClick={fetchChargers}
          disabled={loading}
          className="flex items-center gap-2 px-4 py-2 bg-emerald-600 hover:bg-emerald-700 text-white rounded-xl text-xs font-semibold shadow-sm transition-all disabled:opacity-50"
        >
          <RefreshCw size={14} className={loading ? 'animate-spin' : ''} />
          Refresh
        </button>
      </div>

      {/* Filter Tabs */}
      <div className="flex items-center gap-2 overflow-x-auto pb-1 border-b border-gray-200 dark:border-gray-800 text-xs font-medium">
        {(['ALL', 'ONLINE', 'OFFLINE', 'CHARGING', 'AVAILABLE', 'FAULTED'] as const).map(tab => (
          <button
            key={tab}
            onClick={() => setFilter(tab)}
            className={`px-3 py-1.5 rounded-lg transition-colors capitalize ${
              filter === tab
                ? 'bg-emerald-100 dark:bg-emerald-950 text-emerald-800 dark:text-emerald-300 font-bold'
                : 'text-gray-500 hover:bg-gray-100 dark:hover:bg-gray-800'
            }`}
          >
            {tab.toLowerCase()}
          </button>
        ))}
      </div>

      {/* Loading State */}
      {loading && chargers.length === 0 && (
        <div className="flex flex-col items-center justify-center p-12 bg-white dark:bg-gray-900 border border-gray-200 dark:border-gray-800 rounded-2xl">
          <RefreshCw size={24} className="animate-spin text-emerald-500 mb-2" />
          <p className="text-xs text-gray-500">Loading live charger metrics...</p>
        </div>
      )}

      {/* Error State */}
      {error && (
        <div className="p-4 bg-rose-50 dark:bg-rose-950/30 border border-rose-200 dark:border-rose-800/80 rounded-2xl flex items-center justify-between">
          <div className="flex items-center gap-3">
            <AlertTriangle className="text-rose-600 dark:text-rose-400" size={20} />
            <p className="text-xs text-rose-700 dark:text-rose-300 font-medium">{error}</p>
          </div>
          <button
            onClick={fetchChargers}
            className="px-3 py-1 bg-rose-600 text-white rounded-lg text-xs font-semibold hover:bg-rose-700"
          >
            Retry
          </button>
        </div>
      )}

      {/* Empty State */}
      {!loading && !error && filteredChargers.length === 0 && (
        <div className="p-12 text-center bg-white dark:bg-gray-900 border border-gray-200 dark:border-gray-800 rounded-2xl">
          <Radio size={32} className="mx-auto text-gray-400 mb-2" />
          <p className="text-sm font-bold text-gray-700 dark:text-gray-300">No chargers registered</p>
          <p className="text-xs text-gray-400">No charger hardware matches the selected filter criteria.</p>
        </div>
      )}

      {/* Charger Asset Grid */}
      <div className="grid grid-cols-1 xl:grid-cols-2 gap-6">
        {filteredChargers.map(charger => (
          <div key={charger.id} className="bg-white dark:bg-gray-900 border border-gray-200 dark:border-gray-800 rounded-2xl p-6 shadow-sm space-y-4">
            
            {/* Header Info */}
            <div className="flex items-start justify-between border-b border-gray-100 dark:border-gray-800 pb-4">
              <div className="space-y-1">
                <div className="flex items-center gap-2">
                  <span className="font-bold text-base">{charger.ocppId}</span>
                  <span className="text-[10px] bg-gray-100 dark:bg-gray-800 px-2 py-0.5 rounded text-gray-500 font-semibold">{charger.brand}</span>
                </div>
                <p className="text-xs text-gray-500 dark:text-gray-400">{charger.stationName} • {charger.model} ({charger.powerKw} kW)</p>
              </div>

              {/* Status & Online Badges */}
              <div className="flex flex-col items-end gap-1.5">
                <span className={`px-2.5 py-0.5 rounded-full text-[10px] font-bold ${
                  charger.online 
                    ? 'bg-emerald-100 text-emerald-800 dark:bg-emerald-950/80 dark:text-emerald-400' 
                    : 'bg-rose-100 text-rose-800 dark:bg-rose-950/80 dark:text-rose-400'
                }`}>
                  {charger.online ? 'ONLINE' : 'OFFLINE'}
                </span>
                <span className="text-[10px] text-gray-400">
                  {charger.online ? 'WebSocket Connected' : `Last seen: ${charger.lastSeen.replace('T', ' ').substring(0, 16)}`}
                </span>
              </div>
            </div>

            {/* Connectors Section */}
            <div className="space-y-2">
              <span className="text-xs font-bold text-gray-700 dark:text-gray-300">Connectors ({charger.connectors.length})</span>
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                {charger.connectors.map(conn => (
                  <div key={conn.id} className="p-3 bg-gray-50 dark:bg-gray-800/40 border border-gray-200/60 dark:border-gray-800 rounded-xl space-y-2">
                    <div className="flex items-center justify-between text-xs">
                      <span className="font-semibold">Connector #{conn.connectorId} ({conn.type})</span>
                      <span className={`px-2 py-0.5 rounded text-[10px] font-bold ${
                        conn.status === 'AVAILABLE'
                          ? 'bg-emerald-100 text-emerald-800 dark:bg-emerald-950 dark:text-emerald-400'
                          : conn.status === 'CHARGING'
                          ? 'bg-blue-100 text-blue-800 dark:bg-blue-950 dark:text-blue-400'
                          : 'bg-amber-100 text-amber-800 dark:bg-amber-950 dark:text-amber-400'
                      }`}>
                        {conn.status}
                      </span>
                    </div>

                    {conn.activeSession && (
                      <div className="p-2 bg-blue-50 dark:bg-blue-950/40 border border-blue-200 dark:border-blue-800/60 rounded-lg text-[10px] space-y-1">
                        <div className="flex justify-between font-semibold text-blue-900 dark:text-blue-300">
                          <span>Session #{conn.activeSession.sessionId}</span>
                          <span>{conn.activeSession.userEmail}</span>
                        </div>
                        <div className="flex justify-between text-blue-700 dark:text-blue-400">
                          <span>Energy: {conn.activeSession.energyKwh} kWh</span>
                          <button
                            onClick={() => setForceStopModalSessionId(conn.activeSession!.sessionId)}
                            className="font-bold text-rose-600 dark:text-rose-400 underline hover:text-rose-800"
                          >
                            Force Stop
                          </button>
                        </div>
                      </div>
                    )}
                  </div>
                ))}
              </div>
            </div>

            {/* Admin Controls */}
            <div className="pt-2 flex items-center justify-between border-t border-gray-100 dark:border-gray-800">
              <span className="text-[10px] text-gray-400 font-medium">Status: {charger.status}</span>
              <button
                onClick={() => handleToggleEnableDisable(charger)}
                disabled={actionLoading}
                className={`flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-xs font-bold transition-all ${
                  charger.status === 'DISABLED'
                    ? 'bg-emerald-600 hover:bg-emerald-700 text-white'
                    : 'bg-rose-100 hover:bg-rose-200 text-rose-800 dark:bg-rose-950 dark:text-rose-300'
                }`}
              >
                {charger.status === 'DISABLED' ? <Power size={14} /> : <PowerOff size={14} />}
                {charger.status === 'DISABLED' ? 'ENABLE CHARGER' : 'DISABLE CHARGER'}
              </button>
            </div>

          </div>
        ))}
      </div>

      {/* Disable Confirmation Modal */}
      {disableModalCharger && (
        <div className="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center p-4 z-50">
          <div className="bg-white dark:bg-gray-900 border border-gray-200 dark:border-gray-800 rounded-2xl p-6 max-w-md w-full space-y-4">
            <div className="flex items-center gap-3 text-amber-600 dark:text-amber-400">
              <AlertTriangle size={24} />
              <h3 className="text-base font-bold text-gray-900 dark:text-white">Disable this charger?</h3>
            </div>
            <p className="text-xs text-gray-600 dark:text-gray-400">
              Disabling <strong>{disableModalCharger.ocppId}</strong> will prevent customers from starting new charging sessions on this hardware. Ongoing active sessions will continue.
            </p>
            <div className="flex items-center justify-end gap-3 pt-2">
              <button
                onClick={() => setDisableModalCharger(null)}
                disabled={actionLoading}
                className="px-4 py-2 border border-gray-300 dark:border-gray-700 text-gray-700 dark:text-gray-300 rounded-xl text-xs font-semibold hover:bg-gray-100 dark:hover:bg-gray-800"
              >
                Cancel
              </button>
              <button
                onClick={confirmDisableCharger}
                disabled={actionLoading}
                className="px-4 py-2 bg-rose-600 hover:bg-rose-700 text-white rounded-xl text-xs font-semibold shadow-sm disabled:opacity-50"
              >
                {actionLoading ? 'Disabling...' : 'Confirm Disable'}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Force Stop Confirmation Modal */}
      {forceStopModalSessionId && (
        <div className="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center p-4 z-50">
          <div className="bg-white dark:bg-gray-900 border border-gray-200 dark:border-gray-800 rounded-2xl p-6 max-w-md w-full space-y-4">
            <div className="flex items-center gap-3 text-rose-600 dark:text-rose-400">
              <ShieldAlert size={24} />
              <h3 className="text-base font-bold text-gray-900 dark:text-white">Force stop this charging session?</h3>
            </div>
            <p className="text-xs text-gray-600 dark:text-gray-400">
              This will immediately issue an OCPP RemoteStop command to session <strong>#{forceStopModalSessionId}</strong>, calculate energy consumed, and debit the customer wallet safely.
            </p>
            <div className="flex items-center justify-end gap-3 pt-2">
              <button
                onClick={() => setForceStopModalSessionId(null)}
                disabled={actionLoading}
                className="px-4 py-2 border border-gray-300 dark:border-gray-700 text-gray-700 dark:text-gray-300 rounded-xl text-xs font-semibold hover:bg-gray-100 dark:hover:bg-gray-800"
              >
                Cancel
              </button>
              <button
                onClick={confirmForceStop}
                disabled={actionLoading}
                className="px-4 py-2 bg-rose-600 hover:bg-rose-700 text-white rounded-xl text-xs font-semibold shadow-sm disabled:opacity-50"
              >
                {actionLoading ? 'Stopping...' : 'Confirm Force Stop'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
