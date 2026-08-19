import React, { useState, useEffect } from 'react';
import { 
  MapPin, Power, Radio, Server, Plus, Search, Trash2, RefreshCw, 
  ExternalLink, Edit3, ShieldAlert, CheckCircle, AlertTriangle, X, Info, Zap
} from 'lucide-react';
import { useNotificationStore } from '../store/notificationStore';

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

export default function StationsPage() {
  const addNotification = useNotificationStore(state => state.addNotification);

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
  const [toggleModalStation, setToggleModalStation] = useState<StationDetailed | null>(null);
  const [actionLoading, setActionLoading] = useState<boolean>(false);

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

  const fetchStations = async () => {
    try {
      setLoading(true);
      setError(null);
      const token = localStorage.getItem('token');
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
      addNotification({
        title: 'Error Loading Stations',
        message: err.message || 'Unable to fetch station details from backend.',
        type: 'error'
      });
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
      const token = localStorage.getItem('token');
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

      addNotification({
        title: `Station ${isEdit ? 'Updated' : 'Created'}`,
        message: `Station "${formData.name}" has been successfully saved.`,
        type: 'success'
      });

      setAddModalOpen(false);
      setEditStation(null);
      fetchStations();
    } catch (err: any) {
      setFormError(err.message || 'Error saving station');
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
      const token = localStorage.getItem('token');
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

      addNotification({
        title: `Station ${isDisabling ? 'Disabled' : 'Enabled'}`,
        message: `Station "${toggleModalStation.name}" is now ${isDisabling ? 'INACTIVE' : 'ACTIVE'}.`,
        type: isDisabling ? 'warning' : 'success'
      });

      setToggleModalStation(null);
      fetchStations();
    } catch (err: any) {
      addNotification({
        title: 'Action Failed',
        message: err.message || 'Failed to toggle station status',
        type: 'error'
      });
    } finally {
      setActionLoading(false);
    }
  };

  const openGoogleMaps = (lat: number, lng: number) => {
    window.open(`https://www.google.com/maps?q=${lat},${lng}`, '_blank');
  };

  return (
    <div className="space-y-6 text-gray-900 dark:text-gray-100">
      {/* Header & Primary Actions */}
      <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
        <div>
          <h2 className="text-xl font-bold tracking-tight">Charging Stations</h2>
          <p className="text-xs text-gray-500 dark:text-gray-400 mt-0.5">
            Monitor infrastructure network, charger status, and location availability.
          </p>
        </div>
        <div className="flex items-center gap-3">
          <button
            onClick={fetchStations}
            disabled={loading}
            className="flex items-center gap-1.5 bg-gray-100 dark:bg-gray-800 hover:bg-gray-200 dark:hover:bg-gray-700 text-gray-700 dark:text-gray-300 px-3.5 py-2 rounded-xl text-xs font-semibold shadow-sm transition-all disabled:opacity-50"
          >
            <RefreshCw size={14} className={loading ? 'animate-spin' : ''} /> Refresh
          </button>
          <button
            onClick={openAddModal}
            className="flex items-center gap-2 bg-emerald-600 hover:bg-emerald-700 text-white px-4 py-2 rounded-xl text-xs font-semibold shadow-md transition-all"
          >
            <Plus size={16} /> Add Station
          </button>
        </div>
      </div>

      {/* Search & Filter Controls */}
      <div className="flex flex-col md:flex-row items-stretch md:items-center justify-between gap-4 bg-white dark:bg-gray-900 border border-gray-200 dark:border-gray-800 rounded-2xl p-4 shadow-sm">
        {/* Search Bar */}
        <form onSubmit={handleSearchSubmit} className="relative flex-1 max-w-md">
          <Search size={16} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-gray-400" />
          <input
            type="text"
            placeholder="Search by name, ID, city, or address..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full bg-gray-50 dark:bg-gray-800/60 border border-gray-200 dark:border-gray-700/80 rounded-xl pl-10 pr-4 py-2 text-xs font-medium focus:outline-none focus:border-emerald-500 dark:focus:border-emerald-500 transition-colors"
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
                  ? 'bg-emerald-600 text-white shadow-sm'
                  : 'bg-gray-100 dark:bg-gray-800 text-gray-600 dark:text-gray-400 hover:bg-gray-200 dark:hover:bg-gray-700'
              }`}
            >
              {st === 'INACTIVE' ? 'DISABLED' : st === 'UNDER_MAINTENANCE' ? 'MAINTENANCE' : st}
            </button>
          ))}
        </div>
      </div>

      {/* Loading State */}
      {loading && (
        <div className="flex flex-col items-center justify-center py-16 bg-white dark:bg-gray-900 border border-gray-200 dark:border-gray-800 rounded-2xl p-8 shadow-sm">
          <RefreshCw size={32} className="animate-spin text-emerald-500 mb-3" />
          <p className="text-xs font-semibold text-gray-500 dark:text-gray-400">Loading stations network data...</p>
        </div>
      )}

      {/* Error State */}
      {!loading && error && (
        <div className="flex flex-col items-center justify-center py-16 bg-white dark:bg-gray-900 border border-rose-200 dark:border-rose-950/50 rounded-2xl p-8 text-center shadow-sm">
          <ShieldAlert size={36} className="text-rose-500 mb-3" />
          <h3 className="text-base font-bold text-gray-900 dark:text-gray-100 mb-1">Unable to load stations</h3>
          <p className="text-xs text-rose-500 dark:text-rose-400 max-w-md mb-4">{error}</p>
          <button
            onClick={fetchStations}
            className="flex items-center gap-2 bg-emerald-600 hover:bg-emerald-700 text-white px-4 py-2 rounded-xl text-xs font-semibold shadow-md transition-all"
          >
            <RefreshCw size={14} /> Retry
          </button>
        </div>
      )}

      {/* Empty State */}
      {!loading && !error && stations.length === 0 && (
        <div className="flex flex-col items-center justify-center py-16 bg-white dark:bg-gray-900 border border-gray-200 dark:border-gray-800 rounded-2xl p-8 text-center shadow-sm">
          <Server size={36} className="text-gray-400 mb-3" />
          <h3 className="text-base font-bold text-gray-900 dark:text-gray-100 mb-1">No stations registered</h3>
          <p className="text-xs text-gray-500 dark:text-gray-400 max-w-sm mb-4">
            No charging stations match your current query filter. Click below to add a new station.
          </p>
          <button
            onClick={openAddModal}
            className="flex items-center gap-2 bg-emerald-600 hover:bg-emerald-700 text-white px-4 py-2 rounded-xl text-xs font-semibold shadow-md transition-all"
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
                className="bg-white dark:bg-gray-900 border border-gray-200 dark:border-gray-800 rounded-2xl p-6 shadow-sm flex flex-col justify-between space-y-4 hover:border-emerald-500/80 dark:hover:border-emerald-500/80 transition-all group"
              >
                {/* Station Top Info */}
                <div className="space-y-3">
                  <div className="flex items-center justify-between">
                    <span
                      className={`px-2.5 py-0.5 rounded-full text-[10px] font-bold tracking-wide ${
                        station.status === 'ACTIVE'
                          ? 'bg-emerald-100 dark:bg-emerald-950/80 text-emerald-800 dark:text-emerald-400'
                          : isMaintenance
                          ? 'bg-amber-100 dark:bg-amber-950/80 text-amber-800 dark:text-amber-400'
                          : 'bg-rose-100 dark:bg-rose-950/80 text-rose-800 dark:text-rose-400'
                      }`}
                    >
                      {station.status}
                    </span>
                    <span className="text-[10px] text-gray-400 font-bold">Station #{station.id}</span>
                  </div>

                  <div>
                    <h3
                      onClick={() => setSelectedStation(station)}
                      className="font-bold text-base leading-tight group-hover:text-emerald-500 transition-colors cursor-pointer"
                    >
                      {station.name}
                    </h3>
                    <p className="text-xs text-gray-500 dark:text-gray-400 flex items-center gap-1.5 mt-1">
                      <MapPin size={14} className="text-emerald-500 shrink-0" />
                      <span className="truncate">{station.address}, {station.city}</span>
                    </p>
                  </div>

                  {/* Network Summary Pills */}
                  <div className="grid grid-cols-2 gap-2 pt-1 text-[11px]">
                    <div className="bg-gray-50 dark:bg-gray-800/60 rounded-xl p-2.5 flex items-center justify-between border border-gray-100 dark:border-gray-800">
                      <span className="text-gray-500 dark:text-gray-400 font-medium">Chargers</span>
                      <span className="font-bold text-gray-900 dark:text-gray-100">{station.totalChargers}</span>
                    </div>
                    <div className="bg-gray-50 dark:bg-gray-800/60 rounded-xl p-2.5 flex items-center justify-between border border-gray-100 dark:border-gray-800">
                      <span className="text-gray-500 dark:text-gray-400 font-medium">Connectors</span>
                      <span className="font-bold text-emerald-500">{station.availableConnectors}/{station.totalConnectors} Available</span>
                    </div>
                  </div>
                </div>

                {/* Footer Action Bar */}
                <div className="flex items-center justify-between border-t border-gray-100 dark:border-gray-800/80 pt-4 gap-2">
                  <div className="flex items-center gap-1.5">
                    <button
                      onClick={() => setSelectedStation(station)}
                      className="px-3 py-1.5 bg-gray-100 dark:bg-gray-800 hover:bg-gray-200 dark:hover:bg-gray-700 rounded-lg text-xs font-semibold transition-all"
                    >
                      Details
                    </button>
                    <button
                      onClick={() => openEditModal(station)}
                      className="p-1.5 text-gray-400 hover:text-emerald-500 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors"
                      title="Edit Station"
                    >
                      <Edit3 size={15} />
                    </button>
                    <button
                      onClick={() => openGoogleMaps(station.latitude, station.longitude)}
                      className="p-1.5 text-gray-400 hover:text-blue-500 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors"
                      title="View on Map"
                    >
                      <ExternalLink size={15} />
                    </button>
                  </div>

                  <button
                    onClick={() => setToggleModalStation(station)}
                    className={`flex items-center gap-1 px-3 py-1.5 rounded-lg text-xs font-semibold transition-all ${
                      isInactive
                        ? 'bg-emerald-50 dark:bg-emerald-950/20 text-emerald-600 dark:text-emerald-400 hover:bg-emerald-100'
                        : 'bg-rose-50 dark:bg-rose-950/20 text-rose-600 dark:text-rose-400 hover:bg-rose-100'
                    }`}
                  >
                    <Power size={13} />
                    {isInactive ? 'Enable' : 'Disable'}
                  </button>
                </div>
              </div>
            );
          })}
        </div>
      )}

      {/* STATION DETAILS MODAL */}
      {selectedStation && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm animate-in fade-in duration-200">
          <div className="bg-white dark:bg-gray-900 border border-gray-200 dark:border-gray-800 rounded-2xl max-w-3xl w-full max-h-[90vh] overflow-y-auto shadow-2xl p-6 space-y-6">
            <div className="flex items-start justify-between border-b border-gray-100 dark:border-gray-800 pb-4">
              <div>
                <span className="text-[10px] font-bold text-emerald-500 uppercase tracking-widest">Station Details</span>
                <h3 className="text-xl font-bold text-gray-900 dark:text-gray-100 mt-0.5">{selectedStation.name}</h3>
                <p className="text-xs text-gray-500 dark:text-gray-400 flex items-center gap-1 mt-1">
                  <MapPin size={13} className="text-emerald-500" /> {selectedStation.address}, {selectedStation.city}, {selectedStation.state}, {selectedStation.country}
                </p>
              </div>
              <button
                onClick={() => setSelectedStation(null)}
                className="p-1.5 text-gray-400 hover:text-gray-600 dark:hover:text-gray-200 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors"
              >
                <X size={18} />
              </button>
            </div>

            {/* Network Summary Dashboard */}
            <div className="space-y-2">
              <h4 className="text-xs font-bold text-gray-400 uppercase tracking-wider">Network Summary</h4>
              <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
                <div className="bg-gray-50 dark:bg-gray-800/60 p-3 rounded-xl border border-gray-100 dark:border-gray-800">
                  <span className="text-[10px] text-gray-500 dark:text-gray-400 font-medium">Chargers</span>
                  <div className="text-base font-bold text-gray-900 dark:text-gray-100 mt-0.5">
                    {selectedStation.totalChargers} <span className="text-[11px] text-emerald-500 font-normal">({selectedStation.onlineChargers} Online)</span>
                  </div>
                </div>
                <div className="bg-gray-50 dark:bg-gray-800/60 p-3 rounded-xl border border-gray-100 dark:border-gray-800">
                  <span className="text-[10px] text-gray-500 dark:text-gray-400 font-medium">Connectors</span>
                  <div className="text-base font-bold text-gray-900 dark:text-gray-100 mt-0.5">{selectedStation.totalConnectors} Total</div>
                </div>
                <div className="bg-gray-50 dark:bg-gray-800/60 p-3 rounded-xl border border-gray-100 dark:border-gray-800">
                  <span className="text-[10px] text-gray-500 dark:text-gray-400 font-medium">Available</span>
                  <div className="text-base font-bold text-emerald-500 mt-0.5">{selectedStation.availableConnectors}</div>
                </div>
                <div className="bg-gray-50 dark:bg-gray-800/60 p-3 rounded-xl border border-gray-100 dark:border-gray-800">
                  <span className="text-[10px] text-gray-500 dark:text-gray-400 font-medium">Active Charging</span>
                  <div className="text-base font-bold text-blue-500 mt-0.5">{selectedStation.chargingConnectors}</div>
                </div>
              </div>
            </div>

            {/* Charger Hierarchy List */}
            <div className="space-y-3">
              <div className="flex items-center justify-between">
                <h4 className="text-xs font-bold text-gray-400 uppercase tracking-wider">Charger & Connector Hierarchy</h4>
                <button
                  onClick={() => openGoogleMaps(selectedStation.latitude, selectedStation.longitude)}
                  className="flex items-center gap-1 text-xs text-blue-500 hover:underline font-semibold"
                >
                  <ExternalLink size={13} /> View on Map
                </button>
              </div>

              {selectedStation.chargers.length === 0 ? (
                <p className="text-xs text-gray-500 dark:text-gray-400 py-4 text-center bg-gray-50 dark:bg-gray-800/40 rounded-xl border border-dashed border-gray-200 dark:border-gray-800">
                  No chargers currently assigned to this station.
                </p>
              ) : (
                <div className="space-y-3">
                  {selectedStation.chargers.map((chg) => (
                    <div key={chg.id} className="bg-gray-50 dark:bg-gray-800/50 border border-gray-200 dark:border-gray-800 rounded-xl p-4 space-y-3">
                      <div className="flex items-center justify-between">
                        <div className="flex items-center gap-2">
                          <Zap size={16} className={chg.online ? 'text-emerald-500' : 'text-gray-400'} />
                          <span className="font-bold text-sm text-gray-900 dark:text-gray-100">{chg.ocppId}</span>
                          <span className="text-xs text-gray-400">({chg.brand} - {chg.model})</span>
                        </div>
                        <div className="flex items-center gap-2">
                          <span className={`px-2 py-0.5 rounded-full text-[10px] font-bold ${chg.online ? 'bg-emerald-100 text-emerald-800 dark:bg-emerald-950 dark:text-emerald-400' : 'bg-gray-200 text-gray-700 dark:bg-gray-700 dark:text-gray-300'}`}>
                            {chg.online ? 'ONLINE' : 'OFFLINE'}
                          </span>
                          <span className="text-[10px] text-gray-400">{chg.connectorCount} Plugs</span>
                        </div>
                      </div>

                      {/* Connectors */}
                      <div className="grid grid-cols-1 sm:grid-cols-2 gap-2 pl-4 border-l-2 border-gray-200 dark:border-gray-700">
                        {chg.connectors.map((conn) => (
                          <div key={conn.id} className="bg-white dark:bg-gray-900 p-2.5 rounded-lg border border-gray-100 dark:border-gray-800 text-xs space-y-1">
                            <div className="flex items-center justify-between">
                              <span className="font-semibold text-gray-700 dark:text-gray-300">Connector #{conn.connectorId} ({conn.type})</span>
                              <span className={`text-[10px] font-bold ${conn.status === 'AVAILABLE' ? 'text-emerald-500' : conn.status === 'CHARGING' ? 'text-blue-500' : 'text-amber-500'}`}>
                                {conn.status}
                              </span>
                            </div>
                            <div className="text-[10px] text-gray-400">Max Power: {conn.maxPowerKw} kW</div>
                            {conn.activeSession && (
                              <div className="text-[10px] text-blue-400 bg-blue-50 dark:bg-blue-950/30 p-1.5 rounded mt-1">
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

            <div className="flex justify-end pt-4 border-t border-gray-100 dark:border-gray-800">
              <button
                onClick={() => setSelectedStation(null)}
                className="px-4 py-2 bg-gray-100 dark:bg-gray-800 hover:bg-gray-200 dark:hover:bg-gray-700 text-gray-700 dark:text-gray-300 rounded-xl text-xs font-semibold transition-all"
              >
                Close
              </button>
            </div>
          </div>
        </div>
      )}

      {/* ADD / EDIT STATION MODAL */}
      {(addModalOpen || editStation) && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm animate-in fade-in duration-200">
          <div className="bg-white dark:bg-gray-900 border border-gray-200 dark:border-gray-800 rounded-2xl max-w-lg w-full shadow-2xl p-6 space-y-5">
            <div className="flex items-center justify-between border-b border-gray-100 dark:border-gray-800 pb-3">
              <h3 className="text-base font-bold text-gray-900 dark:text-gray-100">
                {editStation ? 'Edit Station' : 'Add New Charging Station'}
              </h3>
              <button
                onClick={() => { setAddModalOpen(false); setEditStation(null); }}
                className="p-1 text-gray-400 hover:text-gray-600 dark:hover:text-gray-200 rounded-lg"
              >
                <X size={18} />
              </button>
            </div>

            {formError && (
              <div className="bg-rose-50 dark:bg-rose-950/30 border border-rose-200 dark:border-rose-900/50 p-3 rounded-xl text-xs text-rose-600 dark:text-rose-400 flex items-center gap-2">
                <AlertTriangle size={15} /> {formError}
              </div>
            )}

            <div className="space-y-4 text-xs">
              <div>
                <label className="block font-semibold text-gray-700 dark:text-gray-300 mb-1">Station Name *</label>
                <input
                  type="text"
                  value={formData.name}
                  onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                  placeholder="e.g. Jaipur Tech Park Charging Hub"
                  className="w-full bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-xl px-3 py-2 text-xs focus:outline-none focus:border-emerald-500"
                />
              </div>

              <div>
                <label className="block font-semibold text-gray-700 dark:text-gray-300 mb-1">Address</label>
                <input
                  type="text"
                  value={formData.address}
                  onChange={(e) => setFormData({ ...formData, address: e.target.value })}
                  placeholder="Street address or location details"
                  className="w-full bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-xl px-3 py-2 text-xs focus:outline-none focus:border-emerald-500"
                />
              </div>

              <div className="grid grid-cols-3 gap-3">
                <div>
                  <label className="block font-semibold text-gray-700 dark:text-gray-300 mb-1">City</label>
                  <input
                    type="text"
                    value={formData.city}
                    onChange={(e) => setFormData({ ...formData, city: e.target.value })}
                    className="w-full bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-xl px-3 py-2 text-xs focus:outline-none focus:border-emerald-500"
                  />
                </div>
                <div>
                  <label className="block font-semibold text-gray-700 dark:text-gray-300 mb-1">State</label>
                  <input
                    type="text"
                    value={formData.state}
                    onChange={(e) => setFormData({ ...formData, state: e.target.value })}
                    className="w-full bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-xl px-3 py-2 text-xs focus:outline-none focus:border-emerald-500"
                  />
                </div>
                <div>
                  <label className="block font-semibold text-gray-700 dark:text-gray-300 mb-1">Country</label>
                  <input
                    type="text"
                    value={formData.country}
                    onChange={(e) => setFormData({ ...formData, country: e.target.value })}
                    className="w-full bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-xl px-3 py-2 text-xs focus:outline-none focus:border-emerald-500"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block font-semibold text-gray-700 dark:text-gray-300 mb-1">Latitude (-90 to 90) *</label>
                  <input
                    type="number"
                    step="any"
                    value={formData.latitude}
                    onChange={(e) => setFormData({ ...formData, latitude: e.target.value })}
                    placeholder="26.9124"
                    className="w-full bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-xl px-3 py-2 text-xs focus:outline-none focus:border-emerald-500"
                  />
                </div>
                <div>
                  <label className="block font-semibold text-gray-700 dark:text-gray-300 mb-1">Longitude (-180 to 180) *</label>
                  <input
                    type="number"
                    step="any"
                    value={formData.longitude}
                    onChange={(e) => setFormData({ ...formData, longitude: e.target.value })}
                    placeholder="75.7873"
                    className="w-full bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-xl px-3 py-2 text-xs focus:outline-none focus:border-emerald-500"
                  />
                </div>
              </div>

              <div>
                <label className="block font-semibold text-gray-700 dark:text-gray-300 mb-1">Status</label>
                <select
                  value={formData.status}
                  onChange={(e) => setFormData({ ...formData, status: e.target.value })}
                  className="w-full bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-xl px-3 py-2 text-xs focus:outline-none focus:border-emerald-500"
                >
                  <option value="ACTIVE">ACTIVE</option>
                  <option value="INACTIVE">INACTIVE / DISABLED</option>
                  <option value="UNDER_MAINTENANCE">UNDER MAINTENANCE</option>
                </select>
              </div>
            </div>

            <div className="flex justify-end gap-2 pt-3 border-t border-gray-100 dark:border-gray-800">
              <button
                onClick={() => { setAddModalOpen(false); setEditStation(null); }}
                className="px-4 py-2 bg-gray-100 dark:bg-gray-800 hover:bg-gray-200 dark:hover:bg-gray-700 text-gray-700 dark:text-gray-300 rounded-xl text-xs font-semibold transition-all"
              >
                Cancel
              </button>
              <button
                onClick={handleSaveStation}
                disabled={actionLoading}
                className="flex items-center gap-2 bg-emerald-600 hover:bg-emerald-700 text-white px-4 py-2 rounded-xl text-xs font-semibold shadow-md transition-all disabled:opacity-50"
              >
                {actionLoading && <RefreshCw size={14} className="animate-spin" />}
                {editStation ? 'Save Changes' : 'Create Station'}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* ENABLE / DISABLE CONFIRMATION MODAL */}
      {toggleModalStation && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm animate-in fade-in duration-200">
          <div className="bg-white dark:bg-gray-900 border border-gray-200 dark:border-gray-800 rounded-2xl max-w-md w-full shadow-2xl p-6 space-y-4">
            <div className="flex items-center gap-3">
              <div className="p-3 bg-amber-100 dark:bg-amber-950/60 rounded-xl text-amber-600 dark:text-amber-400">
                <AlertTriangle size={24} />
              </div>
              <div>
                <h3 className="text-base font-bold text-gray-900 dark:text-gray-100">
                  {toggleModalStation.status === 'ACTIVE' ? 'Disable this station?' : 'Enable this station?'}
                </h3>
                <p className="text-xs text-gray-500 dark:text-gray-400">
                  Station: <span className="font-semibold text-gray-800 dark:text-gray-200">{toggleModalStation.name}</span>
                </p>
              </div>
            </div>

            <p className="text-xs text-gray-600 dark:text-gray-300 bg-gray-50 dark:bg-gray-800/60 p-3 rounded-xl border border-gray-100 dark:border-gray-800">
              {toggleModalStation.status === 'ACTIVE'
                ? 'Disabling this station will prevent customer app users from starting new charging sessions on any associated chargers. Ongoing active sessions will NOT be interrupted.'
                : 'Enabling this station will restore customer visibility and allow new charging sessions to start.'}
            </p>

            <div className="flex items-center justify-end gap-3 pt-2">
              <button
                onClick={() => setToggleModalStation(null)}
                disabled={actionLoading}
                className="px-4 py-2 bg-gray-100 dark:bg-gray-800 hover:bg-gray-200 dark:hover:bg-gray-700 text-gray-700 dark:text-gray-300 rounded-xl text-xs font-semibold transition-all"
              >
                Cancel
              </button>
              <button
                onClick={handleToggleStatus}
                disabled={actionLoading}
                className={`flex items-center gap-2 text-white px-4 py-2 rounded-xl text-xs font-semibold shadow-md transition-all disabled:opacity-50 ${
                  toggleModalStation.status === 'ACTIVE'
                    ? 'bg-rose-600 hover:bg-rose-700'
                    : 'bg-emerald-600 hover:bg-emerald-700'
                }`}
              >
                {actionLoading && <RefreshCw size={14} className="animate-spin" />}
                Confirm {toggleModalStation.status === 'ACTIVE' ? 'Disable' : 'Enable'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
