import React, { useState, useEffect } from 'react';
import { 
  MapPin, Power, Radio, Server, Plus, Search, Trash2, RefreshCw, 
  ExternalLink, Edit3, ShieldAlert, CheckCircle, AlertTriangle, X, Info, Zap, Sliders, Eye
} from 'lucide-react';

interface ActiveSessionInfo {
  sessionId: number;
  userEmail: string;
  energyKwh: number;
  startedAt: string | null;
}

interface ConnectorDetailed {
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
  status: string;
  online: boolean;
  connectorCount: number;
  connectors: ConnectorDetailed[];
}

interface StationDetailed {
  id: number;
  name: string;
  address: string;
  city: string;
  state: string;
  country: string;
  latitude: number;
  longitude: number;
  status: string;
  createdAt: string;
  updatedAt: string;
  totalChargers: number;
  onlineChargers: number;
  offlineChargers: number;
  totalConnectors: number;
  availableConnectors: number;
  chargingConnectors: number;
  faultedConnectors: number;
  chargers: ChargerDetailed[];
}

export const StationsPage: React.FC = () => {
  const [stations, setStations] = useState<StationDetailed[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);

  // Filters & Search
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [statusFilter, setStatusFilter] = useState<'ALL' | 'ACTIVE' | 'INACTIVE' | 'UNDER_MAINTENANCE' | 'OFFLINE'>('ALL');

  // Modals
  const [selectedStation, setSelectedStation] = useState<StationDetailed | null>(null);
  const [addModalOpen, setAddModalOpen] = useState<boolean>(false);
  const [editStation, setEditStation] = useState<StationDetailed | null>(null);
  const [statusChangeStation, setStatusChangeStation] = useState<StationDetailed | null>(null);
  const [toggleModalStation, setToggleModalStation] = useState<StationDetailed | null>(null);
  const [deleteModalStation, setDeleteModalStation] = useState<StationDetailed | null>(null);
  const [actionLoading, setActionLoading] = useState<boolean>(false);
  const [toastMessage, setToastMessage] = useState<{ title: string; desc: string; type: 'success' | 'warning' | 'error' | 'info' } | null>(null);

  // Form states for Add / Edit
  const [formData, setFormData] = useState({
    name: '',
    address: '',
    city: 'Jaipur',
    state: 'Rajasthan',
    country: 'India',
    latitude: '26.9124',
    longitude: '75.7873',
    status: 'ACTIVE'
  });
  const [formError, setFormError] = useState<string | null>(null);

  // Target status for Status Control modal
  const [targetStatus, setTargetStatus] = useState<string>('ACTIVE');

  const showToast = (title: string, desc: string, type: 'success' | 'warning' | 'error' | 'info' = 'success') => {
    setToastMessage({ title, desc, type });
    setTimeout(() => setToastMessage(null), 4000);
  };

  const getAuthToken = () => {
    return localStorage.getItem('admin_token') || localStorage.getItem('token') || '';
  };

  const fetchStations = async () => {
    try {
      setLoading(true);
      setError(null);
      const token = getAuthToken();
      const params = new URLSearchParams();
      if (searchQuery.trim()) params.append('search', searchQuery.trim());
      if (statusFilter !== 'ALL') params.append('status', statusFilter);

      const response = await fetch(`/api/v1/admin/stations/detailed?${params.toString()}`, {
        headers: {
          'Authorization': token ? `Bearer ${token}` : '',
          'Content-Type': 'application/json'
        }
      });

      if (!response.ok) {
        if (response.status === 403) {
          throw new Error('403 Forbidden: You do not have permission to access Station Management.');
        }
        throw new Error(`Failed to load stations (HTTP ${response.status})`);
      }

      const data: StationDetailed[] = await response.json();
      setStations(data);
    } catch (err: any) {
      setError(err.message || 'Unable to load stations');
      showToast('Error Loading Stations', err.message || 'Unable to fetch station details from backend.', 'error');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchStations();
  }, [statusFilter]);

  const handleSearchSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    fetchStations();
  };

  const openAddModal = () => {
    setFormData({
      name: '',
      address: '',
      city: 'Jaipur',
      state: 'Rajasthan',
      country: 'India',
      latitude: '26.9124',
      longitude: '75.7873',
      status: 'ACTIVE'
    });
    setFormError(null);
    setAddModalOpen(true);
  };

  const openEditModal = (station: StationDetailed) => {
    setEditStation(station);
    setFormData({
      name: station.name || '',
      address: station.address || '',
      city: station.city || 'Jaipur',
      state: station.state || 'Rajasthan',
      country: station.country || 'India',
      latitude: station.latitude != null ? station.latitude.toString() : '',
      longitude: station.longitude != null ? station.longitude.toString() : '',
      status: station.status || 'ACTIVE'
    });
    setFormError(null);
  };

  const openStatusChangeModal = (station: StationDetailed) => {
    setStatusChangeStation(station);
    setTargetStatus(station.status || 'ACTIVE');
  };

  const validateForm = () => {
    if (!formData.name.trim()) {
      setFormError('Station Name is required');
      return false;
    }
    const lat = parseFloat(formData.latitude);
    if (isNaN(lat) || lat < -90.0 || lat > 90.0) {
      setFormError('Latitude must be a valid number between -90 and 90');
      return false;
    }
    const lon = parseFloat(formData.longitude);
    if (isNaN(lon) || lon < -180.0 || lon > 180.0) {
      setFormError('Longitude must be a valid number between -180 and 180');
      return false;
    }
    setFormError(null);
    return true;
  };

  const handleSaveStation = async () => {
    if (!validateForm()) return;
    try {
      setActionLoading(true);
      const token = getAuthToken();
      const payload = {
        name: formData.name.trim(),
        address: formData.address.trim(),
        city: formData.city.trim(),
        state: formData.state.trim(),
        country: formData.country.trim(),
        latitude: parseFloat(formData.latitude),
        longitude: parseFloat(formData.longitude),
        status: formData.status
      };

      const isEdit = !!editStation;
      const url = isEdit ? `/api/v1/admin/stations/${editStation.id}` : '/api/v1/admin/stations';
      const method = isEdit ? 'PUT' : 'POST';

      const response = await fetch(url, {
        method,
        headers: {
          'Authorization': token ? `Bearer ${token}` : '',
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(payload)
      });

      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}));
        throw new Error(errorData.message || `Failed to ${isEdit ? 'update' : 'create'} station`);
      }

      showToast(`Station ${isEdit ? 'Updated' : 'Created'}`, `Station "${formData.name}" has been successfully saved.`, 'success');
      setAddModalOpen(false);
      setEditStation(null);
      fetchStations();
    } catch (err: any) {
      setFormError(err.message || 'Error saving station');
    } finally {
      setActionLoading(false);
    }
  };

  const handleExecuteStatusChange = async () => {
    if (!statusChangeStation) return;
    try {
      setActionLoading(true);
      const token = getAuthToken();
      const response = await fetch(`/api/v1/admin/stations/${statusChangeStation.id}/status`, {
        method: 'PUT',
        headers: {
          'Authorization': token ? `Bearer ${token}` : '',
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ status: targetStatus })
      });

      if (!response.ok) {
        const errData = await response.json().catch(() => ({}));
        throw new Error(errData.message || 'Failed to update station status');
      }

      showToast('Station Status Updated', `Station "${statusChangeStation.name}" status changed from ${statusChangeStation.status} to ${targetStatus}.`, targetStatus === 'ACTIVE' ? 'success' : 'warning');
      setStatusChangeStation(null);
      fetchStations();
    } catch (err: any) {
      showToast('Status Change Failed', err.message || 'Failed to update station status', 'error');
    } finally {
      setActionLoading(false);
    }
  };

  const handleToggleStatus = async () => {
    if (!toggleModalStation) return;
    const isDisabling = toggleModalStation.status === 'ACTIVE';
    const actionEndpoint = isDisabling ? 'disable' : 'enable';
    try {
      setActionLoading(true);
      const token = getAuthToken();
      const response = await fetch(`/api/v1/admin/stations/${toggleModalStation.id}/${actionEndpoint}`, {
        method: 'PUT',
        headers: {
          'Authorization': token ? `Bearer ${token}` : '',
          'Content-Type': 'application/json'
        }
      });

      if (!response.ok) {
        const errData = await response.json().catch(() => ({}));
        throw new Error(errData.message || `Failed to ${actionEndpoint} station`);
      }

      showToast(`Station ${isDisabling ? 'Disabled' : 'Enabled'}`, `Station "${toggleModalStation.name}" is now ${isDisabling ? 'INACTIVE' : 'ACTIVE'}.`, isDisabling ? 'warning' : 'success');
      setToggleModalStation(null);
      fetchStations();
    } catch (err: any) {
      showToast('Action Failed', err.message || 'Failed to toggle station status', 'error');
    } finally {
      setActionLoading(false);
    }
  };

  const handleDeleteStation = async () => {
    if (!deleteModalStation) return;
    try {
      setActionLoading(true);
      const token = getAuthToken();
      const response = await fetch(`/api/v1/admin/stations/${deleteModalStation.id}`, {
        method: 'DELETE',
        headers: {
          'Authorization': token ? `Bearer ${token}` : '',
          'Content-Type': 'application/json'
        }
      });

      const resData = await response.json().catch(() => ({}));

      if (!response.ok) {
        if (response.status === 409) {
          showToast('Station Deactivated', resData.message || 'Station has chargers/history and was soft-deactivated instead of deleted.', 'info');
          setDeleteModalStation(null);
          fetchStations();
          return;
        }
        throw new Error(resData.message || 'Failed to delete station');
      }

      showToast('Station Deleted', `Station "${deleteModalStation.name}" was successfully removed.`, 'success');
      setDeleteModalStation(null);
      fetchStations();
    } catch (err: any) {
      showToast('Delete Failed', err.message || 'Error deleting station', 'error');
    } finally {
      setActionLoading(false);
    }
  };

  const openGoogleMaps = (lat: number, lng: number) => {
    window.open(`https://www.google.com/maps?q=${lat},${lng}`, '_blank');
  };

  const formatDateStr = (dateStr: string | null) => {
    if (!dateStr) return 'N/A';
    try {
      return new Date(dateStr).toLocaleString();
    } catch {
      return dateStr;
    }
  };

  return (
    <div className="space-y-6 text-slate-100">
      {/* Toast Notification Banner */}
      {toastMessage && (
        <div className={`p-4 rounded-xl text-xs font-semibold flex items-center justify-between border shadow-lg animate-in fade-in duration-200 ${
          toastMessage.type === 'success' ? 'bg-emerald-950/80 border-emerald-800 text-emerald-300' :
          toastMessage.type === 'warning' ? 'bg-amber-950/80 border-amber-800 text-amber-300' :
          toastMessage.type === 'error' ? 'bg-rose-950/80 border-rose-800 text-rose-300' :
          'bg-slate-900 border-slate-700 text-slate-300'
        }`}>
          <div>
            <span className="font-bold block text-sm">{toastMessage.title}</span>
            <span>{toastMessage.desc}</span>
          </div>
          <button onClick={() => setToastMessage(null)} className="p-1 hover:opacity-80">
            <X size={16} />
          </button>
        </div>
      )}

      {/* Header & Primary Actions */}
      <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-xl font-bold text-white tracking-tight">Charging Station Directory</h1>
          <p className="text-xs text-slate-400 mt-0.5">
            Monitor network infrastructure, charger availability, and station status.
          </p>
        </div>
        <div className="flex items-center gap-3">
          <button
            onClick={fetchStations}
            disabled={loading}
            className="flex items-center gap-1.5 bg-slate-800 hover:bg-slate-700 text-slate-200 px-3.5 py-2 rounded-xl text-xs font-semibold border border-slate-700 transition-all disabled:opacity-50"
          >
            <RefreshCw size={14} className={loading ? 'animate-spin' : ''} /> Refresh
          </button>
          <button
            onClick={openAddModal}
            className="flex items-center gap-2 bg-emerald-500 hover:bg-emerald-600 text-white px-4 py-2.5 rounded-xl text-xs font-semibold shadow-lg shadow-emerald-500/20 transition-all"
          >
            <Plus size={16} /> Add Station
          </button>
        </div>
      </div>

      {/* Search & Filter Controls */}
      <div className="flex flex-col md:flex-row items-stretch md:items-center justify-between gap-4 bg-slate-900 border border-slate-800 rounded-2xl p-4 shadow-sm">
        {/* Search Bar */}
        <form onSubmit={handleSearchSubmit} className="relative flex-1 max-w-md">
          <Search size={16} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400" />
          <input
            type="text"
            placeholder="Search by name, ID, city, or address..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full bg-slate-950 border border-slate-800 rounded-xl pl-10 pr-4 py-2 text-xs font-medium text-white focus:outline-none focus:border-emerald-500 transition-colors"
          />
        </form>

        {/* Status Filter Tabs */}
        <div className="flex items-center gap-1.5 overflow-x-auto pb-1 md:pb-0">
          {(['ALL', 'ACTIVE', 'INACTIVE', 'UNDER_MAINTENANCE', 'OFFLINE'] as const).map((st) => (
            <button
              key={st}
              onClick={() => setStatusFilter(st)}
              className={`px-3 py-1.5 rounded-xl text-[11px] font-bold whitespace-nowrap transition-all ${
                statusFilter === st
                  ? 'bg-emerald-500 text-white shadow-sm'
                  : 'bg-slate-800 text-slate-400 hover:bg-slate-700 hover:text-white'
              }`}
            >
              {st === 'INACTIVE' ? 'DISABLED' : st === 'UNDER_MAINTENANCE' ? 'MAINTENANCE' : st}
            </button>
          ))}
        </div>
      </div>

      {/* Loading State */}
      {loading && (
        <div className="flex flex-col items-center justify-center py-16 bg-slate-900 border border-slate-800 rounded-2xl p-8 shadow-sm">
          <RefreshCw size={32} className="animate-spin text-emerald-500 mb-3" />
          <p className="text-xs font-semibold text-slate-400">Loading stations network data...</p>
        </div>
      )}

      {/* Error State */}
      {!loading && error && (
        <div className="flex flex-col items-center justify-center py-16 bg-slate-900 border border-rose-950/60 rounded-2xl p-8 text-center shadow-sm">
          <ShieldAlert size={36} className="text-rose-500 mb-3" />
          <h3 className="text-base font-bold text-white mb-1">Unable to load stations</h3>
          <p className="text-xs text-rose-400 max-w-md mb-4">{error}</p>
          <button
            onClick={fetchStations}
            className="flex items-center gap-2 bg-emerald-500 hover:bg-emerald-600 text-white px-4 py-2 rounded-xl text-xs font-semibold transition-all"
          >
            <RefreshCw size={14} /> Retry
          </button>
        </div>
      )}

      {/* Empty State */}
      {!loading && !error && stations.length === 0 && (
        <div className="flex flex-col items-center justify-center py-16 bg-slate-900 border border-slate-800 rounded-2xl p-8 text-center shadow-sm">
          <Server size={36} className="text-slate-500 mb-3" />
          <h3 className="text-base font-bold text-white mb-1">No stations registered</h3>
          <p className="text-xs text-slate-400 max-w-sm mb-4">
            No charging stations match your current query filter. Click below to add a new station.
          </p>
          <button
            onClick={openAddModal}
            className="flex items-center gap-2 bg-emerald-500 hover:bg-emerald-600 text-white px-4 py-2 rounded-xl text-xs font-semibold transition-all"
          >
            <Plus size={16} /> Add First Station
          </button>
        </div>
      )}

      {/* Stations Grid */}
      {!loading && !error && stations.length > 0 && (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {stations.map((station) => {
            const isInactive = station.status === 'INACTIVE' || station.status === 'DISABLED';
            const isMaintenance = station.status === 'UNDER_MAINTENANCE' || station.status === 'MAINTENANCE';

            return (
              <div
                key={station.id}
                className="bg-slate-900 border border-slate-800 rounded-2xl p-6 shadow-sm flex flex-col justify-between space-y-4 hover:border-emerald-500/80 transition-all group"
              >
                {/* Station Top Info */}
                <div className="space-y-3">
                  <div className="flex items-center justify-between">
                    <span
                      className={`px-2.5 py-0.5 rounded-full text-[10px] font-bold tracking-wide ${
                        station.status === 'ACTIVE'
                          ? 'bg-emerald-500/20 text-emerald-400'
                          : isMaintenance
                          ? 'bg-amber-500/20 text-amber-400'
                          : 'bg-rose-500/20 text-rose-400'
                      }`}
                    >
                      {station.status}
                    </span>
                    <span className="text-[10px] text-slate-400 font-mono font-bold">Station #{station.id}</span>
                  </div>

                  <div>
                    <h3
                      onClick={() => setSelectedStation(station)}
                      className="font-bold text-base leading-tight text-white group-hover:text-emerald-400 transition-colors cursor-pointer"
                    >
                      {station.name}
                    </h3>
                    <p className="text-xs text-slate-400 flex items-center gap-1.5 mt-1">
                      <MapPin size={14} className="text-emerald-500 shrink-0" />
                      <span className="truncate">{station.address}, {station.city}, {station.state}</span>
                    </p>
                    <p className="text-[10px] text-slate-500 mt-1">
                      Updated: {formatDateStr(station.updatedAt)}
                    </p>
                  </div>

                  {/* Network Summary Pills */}
                  <div className="grid grid-cols-2 gap-2 pt-1 text-[11px]">
                    <div className="bg-slate-950 rounded-xl p-2.5 flex items-center justify-between border border-slate-800">
                      <span className="text-slate-400 font-medium">Chargers</span>
                      <span className="font-bold text-white">{station.totalChargers}</span>
                    </div>
                    <div className="bg-slate-950 rounded-xl p-2.5 flex items-center justify-between border border-slate-800">
                      <span className="text-slate-400 font-medium">Connectors</span>
                      <span className="font-bold text-emerald-400">{station.availableConnectors}/{station.totalConnectors} Available</span>
                    </div>
                  </div>
                </div>

                {/* Footer Action Bar with Visible [View] [Edit] [Status] Buttons */}
                <div className="flex items-center justify-between border-t border-slate-800 pt-4 gap-2">
                  <div className="flex items-center gap-1.5">
                    <button
                      onClick={() => setSelectedStation(station)}
                      className="flex items-center gap-1 px-2.5 py-1.5 bg-slate-800 hover:bg-slate-700 text-slate-200 rounded-lg text-xs font-semibold border border-slate-700 transition-all"
                      title="View Details"
                    >
                      <Eye size={14} className="text-emerald-400" /> View
                    </button>
                    <button
                      onClick={() => openEditModal(station)}
                      className="flex items-center gap-1 px-2.5 py-1.5 bg-slate-800 hover:bg-slate-700 text-slate-200 rounded-lg text-xs font-semibold border border-slate-700 transition-all"
                      title="Edit Station"
                    >
                      <Edit3 size={14} className="text-blue-400" /> Edit
                    </button>
                    <button
                      onClick={() => openStatusChangeModal(station)}
                      className="flex items-center gap-1 px-2.5 py-1.5 bg-slate-800 hover:bg-slate-700 text-slate-200 rounded-lg text-xs font-semibold border border-slate-700 transition-all"
                      title="Change Status"
                    >
                      <Sliders size={14} className="text-amber-400" /> Status
                    </button>
                  </div>

                  <div className="flex items-center gap-1">
                    <button
                      onClick={() => setToggleModalStation(station)}
                      className={`px-2.5 py-1.5 rounded-lg text-xs font-semibold transition-all ${
                        isInactive
                          ? 'bg-emerald-500/20 text-emerald-400 hover:bg-emerald-500/30'
                          : 'bg-amber-500/20 text-amber-400 hover:bg-amber-500/30'
                      }`}
                    >
                      {isInactive ? 'Enable' : 'Disable'}
                    </button>
                    <button
                      onClick={() => setDeleteModalStation(station)}
                      className="p-1.5 text-slate-400 hover:text-rose-400 rounded-lg hover:bg-slate-800 transition-colors"
                      title="Delete / Deactivate"
                    >
                      <Trash2 size={15} />
                    </button>
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      )}

      {/* STATION DETAILS MODAL */}
      {selectedStation && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/70 backdrop-blur-sm animate-in fade-in duration-200">
          <div className="bg-slate-900 border border-slate-800 rounded-2xl max-w-3xl w-full max-h-[90vh] overflow-y-auto shadow-2xl p-6 space-y-6">
            <div className="flex items-start justify-between border-b border-slate-800 pb-4">
              <div>
                <span className="text-[10px] font-bold text-emerald-400 uppercase tracking-widest">Station Details</span>
                <h3 className="text-xl font-bold text-white mt-0.5">{selectedStation.name}</h3>
                <p className="text-xs text-slate-400 flex items-center gap-1 mt-1">
                  <MapPin size={13} className="text-emerald-500" /> {selectedStation.address}, {selectedStation.city}, {selectedStation.state}, {selectedStation.country}
                </p>
                <div className="flex flex-wrap items-center gap-4 text-[11px] text-slate-400 mt-2">
                  <span>Coordinates: {selectedStation.latitude}, {selectedStation.longitude}</span>
                  <span>Created: {formatDateStr(selectedStation.createdAt)}</span>
                  <span>Updated: {formatDateStr(selectedStation.updatedAt)}</span>
                </div>
              </div>
              <button
                onClick={() => setSelectedStation(null)}
                className="p-1.5 text-slate-400 hover:text-white rounded-lg hover:bg-slate-800 transition-colors"
              >
                <X size={18} />
              </button>
            </div>

            {/* Network Summary Dashboard */}
            <div className="space-y-2">
              <h4 className="text-xs font-bold text-slate-400 uppercase tracking-wider">Network Summary</h4>
              <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
                <div className="bg-slate-950 p-3 rounded-xl border border-slate-800">
                  <span className="text-[10px] text-slate-400 font-medium">Chargers</span>
                  <div className="text-base font-bold text-white mt-0.5">
                    {selectedStation.totalChargers} <span className="text-[11px] text-emerald-400 font-normal">({selectedStation.onlineChargers} Online)</span>
                  </div>
                </div>
                <div className="bg-slate-950 p-3 rounded-xl border border-slate-800">
                  <span className="text-[10px] text-slate-400 font-medium">Connectors</span>
                  <div className="text-base font-bold text-white mt-0.5">{selectedStation.totalConnectors} Total</div>
                </div>
                <div className="bg-slate-950 p-3 rounded-xl border border-slate-800">
                  <span className="text-[10px] text-slate-400 font-medium">Available</span>
                  <div className="text-base font-bold text-emerald-400 mt-0.5">{selectedStation.availableConnectors}</div>
                </div>
                <div className="bg-slate-950 p-3 rounded-xl border border-slate-800">
                  <span className="text-[10px] text-slate-400 font-medium">Active Charging</span>
                  <div className="text-base font-bold text-blue-400 mt-0.5">{selectedStation.chargingConnectors}</div>
                </div>
              </div>
            </div>

            {/* Charger Hierarchy List */}
            <div className="space-y-3">
              <div className="flex items-center justify-between">
                <h4 className="text-xs font-bold text-slate-400 uppercase tracking-wider">Charger → Connector Hierarchy</h4>
                <button
                  onClick={() => openGoogleMaps(selectedStation.latitude, selectedStation.longitude)}
                  className="flex items-center gap-1 text-xs text-blue-400 hover:underline font-semibold"
                >
                  <ExternalLink size={13} /> View on Map
                </button>
              </div>

              {selectedStation.chargers.length === 0 ? (
                <p className="text-xs text-slate-400 py-4 text-center bg-slate-950 rounded-xl border border-dashed border-slate-800">
                  No chargers currently assigned to this station.
                </p>
              ) : (
                <div className="space-y-3">
                  {selectedStation.chargers.map((chg) => (
                    <div key={chg.id} className="bg-slate-950 border border-slate-800 rounded-xl p-4 space-y-3">
                      <div className="flex items-center justify-between">
                        <div className="flex items-center gap-2">
                          <Zap size={16} className={chg.online ? 'text-emerald-400' : 'text-slate-500'} />
                          <span className="font-bold text-sm text-white">{chg.ocppId}</span>
                          <span className="text-xs text-slate-400">({chg.brand} - {chg.model})</span>
                        </div>
                        <div className="flex items-center gap-2">
                          <span className={`px-2 py-0.5 rounded-full text-[10px] font-bold ${chg.online ? 'bg-emerald-500/20 text-emerald-400' : 'bg-slate-800 text-slate-400'}`}>
                            {chg.online ? 'ONLINE' : 'OFFLINE'}
                          </span>
                          <span className="text-[10px] text-slate-400">{chg.connectorCount} Plugs</span>
                        </div>
                      </div>

                      {/* Connectors */}
                      <div className="grid grid-cols-1 sm:grid-cols-2 gap-2 pl-4 border-l-2 border-slate-800">
                        {chg.connectors.map((conn) => (
                          <div key={conn.id} className="bg-slate-900 p-2.5 rounded-lg border border-slate-800 text-xs space-y-1">
                            <div className="flex items-center justify-between">
                              <span className="font-semibold text-slate-300">Connector #{conn.connectorId} ({conn.type})</span>
                              <span className={`text-[10px] font-bold ${conn.status === 'AVAILABLE' ? 'text-emerald-400' : conn.status === 'CHARGING' ? 'text-blue-400' : 'text-amber-400'}`}>
                                {conn.status}
                              </span>
                            </div>
                            <div className="text-[10px] text-slate-400">Max Power: {conn.maxPowerKw} kW</div>
                            {conn.activeSession && (
                              <div className="text-[10px] text-blue-400 bg-blue-950/40 p-1.5 rounded mt-1 border border-blue-900/50">
                                User: {conn.activeSession.userEmail} | Energy: {conn.activeSession.energyKwh} kWh
                              </div>
                            )}
                          </div>
                        ))}
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>

            <div className="flex justify-end pt-4 border-t border-slate-800">
              <button
                onClick={() => setSelectedStation(null)}
                className="px-4 py-2 bg-slate-800 hover:bg-slate-700 text-slate-300 rounded-xl text-xs font-semibold transition-all"
              >
                Close
              </button>
            </div>
          </div>
        </div>
      )}

      {/* ADD / EDIT STATION MODAL */}
      {(addModalOpen || editStation) && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/70 backdrop-blur-sm animate-in fade-in duration-200">
          <div className="bg-slate-900 border border-slate-800 rounded-2xl max-w-lg w-full shadow-2xl p-6 space-y-5">
            <div className="flex items-center justify-between border-b border-slate-800 pb-3">
              <h3 className="text-base font-bold text-white">
                {editStation ? 'Edit Station' : 'Add New Charging Station'}
              </h3>
              <button
                onClick={() => { setAddModalOpen(false); setEditStation(null); }}
                className="p-1 text-slate-400 hover:text-white rounded-lg"
              >
                <X size={18} />
              </button>
            </div>

            {formError && (
              <div className="bg-rose-950/40 border border-rose-900/60 p-3 rounded-xl text-xs text-rose-300 flex items-center gap-2">
                <AlertTriangle size={15} /> {formError}
              </div>
            )}

            <div className="space-y-4 text-xs">
              <div>
                <label className="block font-semibold text-slate-300 mb-1">Station Name *</label>
                <input
                  type="text"
                  value={formData.name}
                  onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                  placeholder="e.g. Jaipur Tech Park Charging Hub"
                  className="w-full bg-slate-950 border border-slate-800 rounded-xl px-3 py-2 text-xs text-white focus:outline-none focus:border-emerald-500"
                />
              </div>

              <div>
                <label className="block font-semibold text-slate-300 mb-1">Address</label>
                <input
                  type="text"
                  value={formData.address}
                  onChange={(e) => setFormData({ ...formData, address: e.target.value })}
                  placeholder="Street address or location details"
                  className="w-full bg-slate-950 border border-slate-800 rounded-xl px-3 py-2 text-xs text-white focus:outline-none focus:border-emerald-500"
                />
              </div>

              <div className="grid grid-cols-3 gap-3">
                <div>
                  <label className="block font-semibold text-slate-300 mb-1">City</label>
                  <input
                    type="text"
                    value={formData.city}
                    onChange={(e) => setFormData({ ...formData, city: e.target.value })}
                    className="w-full bg-slate-950 border border-slate-800 rounded-xl px-3 py-2 text-xs text-white focus:outline-none focus:border-emerald-500"
                  />
                </div>
                <div>
                  <label className="block font-semibold text-slate-300 mb-1">State</label>
                  <input
                    type="text"
                    value={formData.state}
                    onChange={(e) => setFormData({ ...formData, state: e.target.value })}
                    className="w-full bg-slate-950 border border-slate-800 rounded-xl px-3 py-2 text-xs text-white focus:outline-none focus:border-emerald-500"
                  />
                </div>
                <div>
                  <label className="block font-semibold text-slate-300 mb-1">Country</label>
                  <input
                    type="text"
                    value={formData.country}
                    onChange={(e) => setFormData({ ...formData, country: e.target.value })}
                    className="w-full bg-slate-950 border border-slate-800 rounded-xl px-3 py-2 text-xs text-white focus:outline-none focus:border-emerald-500"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block font-semibold text-slate-300 mb-1">Latitude (-90 to 90) *</label>
                  <input
                    type="number"
                    step="any"
                    value={formData.latitude}
                    onChange={(e) => setFormData({ ...formData, latitude: e.target.value })}
                    placeholder="26.9124"
                    className="w-full bg-slate-950 border border-slate-800 rounded-xl px-3 py-2 text-xs text-white focus:outline-none focus:border-emerald-500"
                  />
                </div>
                <div>
                  <label className="block font-semibold text-slate-300 mb-1">Longitude (-180 to 180) *</label>
                  <input
                    type="number"
                    step="any"
                    value={formData.longitude}
                    onChange={(e) => setFormData({ ...formData, longitude: e.target.value })}
                    placeholder="75.7873"
                    className="w-full bg-slate-950 border border-slate-800 rounded-xl px-3 py-2 text-xs text-white focus:outline-none focus:border-emerald-500"
                  />
                </div>
              </div>

              <div>
                <label className="block font-semibold text-slate-300 mb-1">Status</label>
                <select
                  value={formData.status}
                  onChange={(e) => setFormData({ ...formData, status: e.target.value })}
                  className="w-full bg-slate-950 border border-slate-800 rounded-xl px-3 py-2 text-xs text-white focus:outline-none focus:border-emerald-500"
                >
                  <option value="ACTIVE">ACTIVE</option>
                  <option value="INACTIVE">INACTIVE / DISABLED</option>
                  <option value="UNDER_MAINTENANCE">UNDER MAINTENANCE</option>
                </select>
              </div>
            </div>

            <div className="flex justify-end gap-2 pt-3 border-t border-slate-800">
              <button
                onClick={() => { setAddModalOpen(false); setEditStation(null); }}
                className="px-4 py-2 bg-slate-800 hover:bg-slate-700 text-slate-300 rounded-xl text-xs font-semibold"
              >
                Cancel
              </button>
              <button
                onClick={handleSaveStation}
                disabled={actionLoading}
                className="flex items-center gap-2 bg-emerald-500 hover:bg-emerald-600 text-white px-4 py-2 rounded-xl text-xs font-semibold shadow-md transition-all disabled:opacity-50"
              >
                {actionLoading && <RefreshCw size={14} className="animate-spin" />}
                {editStation ? 'Save Changes' : 'Create Station'}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* STATUS CONTROL MODAL */}
      {statusChangeStation && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/70 backdrop-blur-sm animate-in fade-in duration-200">
          <div className="bg-slate-900 border border-slate-800 rounded-2xl max-w-md w-full shadow-2xl p-6 space-y-4">
            <div className="flex items-center justify-between border-b border-slate-800 pb-3">
              <div className="flex items-center gap-2">
                <Sliders size={18} className="text-emerald-400" />
                <h3 className="text-base font-bold text-white">Station Status Control</h3>
              </div>
              <button onClick={() => setStatusChangeStation(null)} className="p-1 text-slate-400 hover:text-white">
                <X size={18} />
              </button>
            </div>

            <div className="bg-slate-950 p-3 rounded-xl border border-slate-800 space-y-1.5 text-xs">
              <div className="flex justify-between"><span className="text-slate-400">Station Name:</span><span className="font-bold text-white">{statusChangeStation.name}</span></div>
              <div className="flex justify-between"><span className="text-slate-400">Station ID:</span><span className="font-mono font-bold text-emerald-400">#{statusChangeStation.id}</span></div>
              <div className="flex justify-between"><span className="text-slate-400">Current Status:</span><span className="font-bold text-amber-400">{statusChangeStation.status}</span></div>
            </div>

            <div>
              <label className="block text-xs font-semibold text-slate-300 mb-1.5">Select New Status</label>
              <div className="grid grid-cols-3 gap-2">
                {(['ACTIVE', 'INACTIVE', 'UNDER_MAINTENANCE'] as const).map((st) => (
                  <button
                    key={st}
                    onClick={() => setTargetStatus(st)}
                    className={`py-2 px-2 rounded-xl text-xs font-bold transition-all ${
                      targetStatus === st
                        ? 'bg-emerald-500 text-white shadow-sm'
                        : 'bg-slate-800 text-slate-400 hover:bg-slate-700 hover:text-white'
                    }`}
                  >
                    {st === 'INACTIVE' ? 'DISABLED' : st === 'UNDER_MAINTENANCE' ? 'MAINTENANCE' : st}
                  </button>
                ))}
              </div>
            </div>

            <p className="text-[11px] text-slate-300 bg-amber-950/40 p-2.5 rounded-lg border border-amber-900/50">
              {targetStatus === 'ACTIVE'
                ? 'Activating this station enables customer app visibility and allows new sessions.'
                : 'Setting to MAINTENANCE or DISABLED prevents new charging sessions from being started by customers. Ongoing active sessions will NOT be interrupted.'}
            </p>

            <div className="flex justify-end gap-2 pt-2">
              <button
                onClick={() => setStatusChangeStation(null)}
                className="px-4 py-2 bg-slate-800 hover:bg-slate-700 text-slate-300 rounded-xl text-xs font-semibold"
              >
                Cancel
              </button>
              <button
                onClick={handleExecuteStatusChange}
                disabled={actionLoading}
                className="flex items-center gap-2 bg-emerald-500 hover:bg-emerald-600 text-white px-4 py-2 rounded-xl text-xs font-semibold shadow-md transition-all disabled:opacity-50"
              >
                {actionLoading && <RefreshCw size={14} className="animate-spin" />}
                Confirm Status Update
              </button>
            </div>
          </div>
        </div>
      )}

      {/* ENABLE / DISABLE CONFIRMATION MODAL */}
      {toggleModalStation && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/70 backdrop-blur-sm animate-in fade-in duration-200">
          <div className="bg-slate-900 border border-slate-800 rounded-2xl max-w-md w-full shadow-2xl p-6 space-y-4">
            <div className="flex items-center gap-3">
              <div className="p-3 bg-amber-500/20 rounded-xl text-amber-400">
                <AlertTriangle size={24} />
              </div>
              <div>
                <h3 className="text-base font-bold text-white">
                  {toggleModalStation.status === 'ACTIVE' ? 'Disable this station?' : 'Enable this station?'}
                </h3>
                <p className="text-xs text-slate-400">
                  Station: <span className="font-semibold text-white">{toggleModalStation.name}</span> (ID #{toggleModalStation.id})
                </p>
              </div>
            </div>

            <p className="text-xs text-slate-300 bg-slate-950 p-3 rounded-xl border border-slate-800">
              {toggleModalStation.status === 'ACTIVE'
                ? 'Disabling this station will prevent customer app users from starting new charging sessions on any associated chargers. Ongoing active sessions will NOT be interrupted.'
                : 'Enabling this station will restore customer visibility and allow new charging sessions to start.'}
            </p>

            <div className="flex items-center justify-end gap-3 pt-2">
              <button
                onClick={() => setToggleModalStation(null)}
                disabled={actionLoading}
                className="px-4 py-2 bg-slate-800 hover:bg-slate-700 text-slate-300 rounded-xl text-xs font-semibold"
              >
                Cancel
              </button>
              <button
                onClick={handleToggleStatus}
                disabled={actionLoading}
                className={`flex items-center gap-2 text-white px-4 py-2 rounded-xl text-xs font-semibold shadow-md transition-all disabled:opacity-50 ${
                  toggleModalStation.status === 'ACTIVE'
                    ? 'bg-rose-600 hover:bg-rose-700'
                    : 'bg-emerald-500 hover:bg-emerald-600'
                }`}
              >
                {actionLoading && <RefreshCw size={14} className="animate-spin" />}
                Confirm {toggleModalStation.status === 'ACTIVE' ? 'Disable' : 'Enable'}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* DELETE CONFIRMATION MODAL */}
      {deleteModalStation && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/70 backdrop-blur-sm animate-in fade-in duration-200">
          <div className="bg-slate-900 border border-slate-800 rounded-2xl max-w-md w-full shadow-2xl p-6 space-y-4">
            <div className="flex items-center gap-3">
              <div className="p-3 bg-rose-500/20 rounded-xl text-rose-400">
                <Trash2 size={24} />
              </div>
              <div>
                <h3 className="text-base font-bold text-white">Delete / Deactivate Station</h3>
                <p className="text-xs text-slate-400">
                  Station: <span className="font-semibold text-white">{deleteModalStation.name}</span> (ID #{deleteModalStation.id})
                </p>
              </div>
            </div>

            <p className="text-xs text-slate-300 bg-slate-950 p-3 rounded-xl border border-slate-800">
              Note: Hard deletion is strictly blocked if this station contains chargers, connectors, or session history. The system will automatically soft-deactivate the station to preserve data integrity.
            </p>

            <div className="flex items-center justify-end gap-3 pt-2">
              <button
                onClick={() => setDeleteModalStation(null)}
                disabled={actionLoading}
                className="px-4 py-2 bg-slate-800 hover:bg-slate-700 text-slate-300 rounded-xl text-xs font-semibold"
              >
                Cancel
              </button>
              <button
                onClick={handleDeleteStation}
                disabled={actionLoading}
                className="flex items-center gap-2 bg-rose-600 hover:bg-rose-700 text-white px-4 py-2 rounded-xl text-xs font-semibold shadow-md transition-all disabled:opacity-50"
              >
                {actionLoading && <RefreshCw size={14} className="animate-spin" />}
                Confirm Delete / Deactivate
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default StationsPage;
