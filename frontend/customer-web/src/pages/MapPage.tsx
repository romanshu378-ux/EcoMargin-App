import React, { useState, useEffect, useCallback } from 'react';
import { useJsApiLoader, GoogleMap, Marker, InfoWindow } from '@react-google-maps/api';
import { 
  Search, 
  MapPin, 
  Navigation, 
  Zap, 
  AlertTriangle, 
  Compass, 
  Star, 
  SlidersHorizontal, 
  RefreshCw, 
  Mic, 
  List, 
  CheckCircle2, 
  Coffee, 
  Wifi, 
  Car, 
  ShieldCheck,
  ChevronRight,
  X
} from 'lucide-react';
import { api } from '../services/api';

interface Station {
  id: string;
  name: string;
  address: string;
  lat: number;
  lng: number;
  totalChargers: number;
  availableChargers: number;
  plugs: string[];
  powerKw: number;
  pricePerKwh: number;
  rating: number;
  reviewsCount: number;
  imageUrl: string;
  isOpen247: boolean;
  amenities: string[];
  isAvailable: boolean;
}

const DEFAULT_CENTER = { lat: 26.9124, lng: 75.7873 }; // Jaipur Default

const FALLBACK_STATIONS: Station[] = [
  {
    id: 'ST-001',
    name: 'EcoMargin Fast Charging Hub',
    address: 'Tonk Road, Sector 62, Jaipur, Rajasthan 302018',
    lat: 26.9150,
    lng: 75.7920,
    totalChargers: 6,
    availableChargers: 4,
    plugs: ['CCS2', 'Type 2', 'DC Fast'],
    powerKw: 60,
    pricePerKwh: 12.0,
    rating: 4.8,
    reviewsCount: 42,
    imageUrl: 'https://images.unsplash.com/photo-1593941707882-a5bba14938c7?auto=format&fit=crop&w=600&q=80',
    isOpen247: true,
    amenities: ['Cafe', 'WiFi', 'Washroom', 'Parking'],
    isAvailable: true,
  },
  {
    id: 'ST-002',
    name: 'EcoMargin Supercharge Station',
    address: 'Apex Circle, Malviya Nagar, Jaipur 302017',
    lat: 26.8540,
    lng: 75.8140,
    totalChargers: 8,
    availableChargers: 5,
    plugs: ['CCS2', 'GB/T', 'DC 120kW'],
    powerKw: 120,
    pricePerKwh: 15.0,
    rating: 4.9,
    reviewsCount: 88,
    imageUrl: 'https://images.unsplash.com/photo-1647427017067-8f33ccbae493?auto=format&fit=crop&w=600&q=80',
    isOpen247: true,
    amenities: ['Cafe', 'Washroom', 'Parking'],
    isAvailable: true,
  },
  {
    id: 'ST-003',
    name: 'PowerGrid Hub C-Scheme',
    address: 'MI Road, C-Scheme, Jaipur 302001',
    lat: 26.9180,
    lng: 75.8010,
    totalChargers: 4,
    availableChargers: 2,
    plugs: ['Type 2', 'AC 22kW'],
    powerKw: 22,
    pricePerKwh: 10.0,
    rating: 4.6,
    reviewsCount: 19,
    imageUrl: 'https://images.unsplash.com/photo-1593941707882-a5bba14938c7?auto=format&fit=crop&w=600&q=80',
    isOpen247: false,
    amenities: ['WiFi', 'Parking'],
    isAvailable: true,
  },
  {
    id: 'ST-004',
    name: 'ChargeZone Ultra Vaishali',
    address: 'Queens Road, Vaishali Nagar, Jaipur 302021',
    lat: 26.9080,
    lng: 75.7480,
    totalChargers: 10,
    availableChargers: 7,
    plugs: ['CCS2', 'Hyper 240kW'],
    powerKw: 240,
    pricePerKwh: 18.0,
    rating: 4.95,
    reviewsCount: 124,
    imageUrl: 'https://images.unsplash.com/photo-1647427017067-8f33ccbae493?auto=format&fit=crop&w=600&q=80',
    isOpen247: true,
    amenities: ['Cafe', 'WiFi', 'Washroom', 'Parking'],
    isAvailable: true,
  },
];

const mapContainerStyle = {
  width: '100%',
  height: '100%',
};

export const MapPage: React.FC = () => {
  const apiKey = import.meta.env.VITE_GOOGLE_MAPS_API_KEY;

  const { isLoaded, loadError } = useJsApiLoader({
    googleMapsApiKey: apiKey || '',
    id: 'google-map-script',
  });

  const [map, setMap] = useState<google.maps.Map | null>(null);
  const [userLocation, setUserLocation] = useState<{ lat: number; lng: number }>(DEFAULT_CENTER);
  const [stations, setStations] = useState<Station[]>(FALLBACK_STATIONS);
  const [selectedStation, setSelectedStation] = useState<Station | null>(FALLBACK_STATIONS[0]);
  const [selectedPlugFilter, setSelectedPlugFilter] = useState('ALL');
  const [searchQuery, setSearchQuery] = useState('');
  const [sidebarOpen, setSidebarOpen] = useState(true);
  const [isRefreshing, setIsRefreshing] = useState(false);

  // Auto-refresh stations availability every 30 seconds
  const fetchStations = useCallback(() => {
    setIsRefreshing(true);
    api.get('/stations')
      .then((res) => {
        if (res.data && Array.isArray(res.data) && res.data.length > 0) {
          setStations(res.data);
        } else {
          setStations(FALLBACK_STATIONS);
        }
      })
      .catch(() => {
        setStations(FALLBACK_STATIONS);
      })
      .finally(() => {
        setIsRefreshing(false);
      });
  }, []);

  useEffect(() => {
    fetchStations();
    const interval = setInterval(() => {
      fetchStations();
    }, 30000);
    return () => clearInterval(interval);
  }, [fetchStations]);

  // Detect GPS position
  useEffect(() => {
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(
        (position) => {
          const userPos = {
            lat: position.coords.latitude,
            lng: position.coords.longitude,
          };
          setUserLocation(userPos);
          if (map) {
            map.panTo(userPos);
          }
        },
        () => {
          setUserLocation(DEFAULT_CENTER);
        },
        { enableHighAccuracy: true, timeout: 10000 }
      );
    }
  }, [map]);

  const onMapLoad = useCallback((mapInstance: google.maps.Map) => {
    setMap(mapInstance);
    if (window.google) {
      const bounds = new window.google.maps.LatLngBounds();
      bounds.extend(DEFAULT_CENTER);
      FALLBACK_STATIONS.forEach((s) => bounds.extend({ lat: s.lat, lng: s.lng }));
      mapInstance.fitBounds(bounds);
    }
  }, []);

  const calculateDistanceStr = (targetLat: number, targetLng: number): string => {
    const R = 6371; // Radius of the Earth in km
    const dLat = ((targetLat - userLocation.lat) * Math.PI) / 180;
    const dLon = ((targetLng - userLocation.lng) * Math.PI) / 180;
    const a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos((userLocation.lat * Math.PI) / 180) *
        Math.cos((targetLat * Math.PI) / 180) *
        Math.sin(dLon / 2) *
        Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    const d = R * c;
    return d < 1 ? `${Math.round(d * 1000)} m` : `${d.toFixed(1)} km`;
  };

  const filteredStations = stations.filter((s) => {
    const matchesSearch =
      s.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      s.address.toLowerCase().includes(searchQuery.toLowerCase());
    const matchesPlug =
      selectedPlugFilter === 'ALL' || s.plugs.some(p => p.toUpperCase().includes(selectedPlugFilter));

    return matchesSearch && matchesPlug;
  });

  const handleSelectStation = (s: Station) => {
    setSelectedStation(s);
    if (map) {
      map.panTo({ lat: s.lat, lng: s.lng });
      map.setZoom(15.5);
    }
  };

  const handleRecenter = () => {
    if (map) {
      map.panTo(userLocation);
      map.setZoom(14);
    }
  };

  return (
    <div className="h-[calc(100vh-80px)] flex flex-col md:flex-row overflow-hidden bg-slate-50 relative font-sans">
      {/* 1. Left Collapsible Station List Sidebar */}
      <div
        className={`${
          sidebarOpen ? 'translate-x-0' : '-translate-x-full md:translate-x-0'
        } transition-transform duration-300 w-full md:w-96 bg-white border-r border-slate-200 flex flex-col overflow-hidden shadow-xl z-20 absolute md:relative inset-y-0 left-0`}
      >
        <div className="p-4 border-b border-slate-200 space-y-3 bg-white">
          <div className="flex items-center justify-between">
            <h2 className="font-extrabold text-slate-900 text-base flex items-center gap-2">
              <Zap className="w-5 h-5 text-emerald-600 fill-emerald-600" /> Nearby Stations
            </h2>
            <button
              onClick={() => setSidebarOpen(false)}
              className="md:hidden p-1.5 text-slate-400 hover:text-slate-600"
            >
              <X className="w-5 h-5" />
            </button>
          </div>

          {/* Search Box */}
          <div className="relative">
            <Search className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="Search station or locality..."
              className="w-full pl-9 pr-8 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-xs text-slate-900 focus:outline-none focus:border-emerald-500 font-medium"
            />
            <Mic className="w-4 h-4 absolute right-3 top-1/2 -translate-y-1/2 text-emerald-600 cursor-pointer" />
          </div>

          <div className="flex gap-2">
            {['ALL', 'CCS2', 'TYPE 2', 'DC'].map((plug) => (
              <button
                key={plug}
                onClick={() => setSelectedPlugFilter(plug)}
                className={`px-3 py-1.5 rounded-lg text-xs font-bold transition-all ${
                  selectedPlugFilter === plug
                    ? 'bg-emerald-600 text-white shadow-sm'
                    : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
                }`}
              >
                {plug}
              </button>
            ))}
          </div>
        </div>

        {/* Station Scroll List */}
        <div className="flex-1 overflow-y-auto p-4 space-y-3">
          {filteredStations.map((s) => {
            const distance = calculateDistanceStr(s.lat, s.lng);
            const isSelected = selectedStation?.id === s.id;
            return (
              <div
                key={s.id}
                onClick={() => handleSelectStation(s)}
                className={`p-4 rounded-2xl border transition-all cursor-pointer space-y-2.5 ${
                  isSelected
                    ? 'bg-emerald-50/80 border-emerald-500 shadow-md ring-2 ring-emerald-500/20'
                    : 'bg-white border-slate-200 hover:border-slate-300 shadow-sm'
                }`}
              >
                <div className="flex justify-between items-start gap-2">
                  <div>
                    <div className="flex items-center gap-1.5">
                      <h4 className="font-bold text-slate-900 text-sm leading-tight">{s.name}</h4>
                      <CheckCircle2 className="w-4 h-4 text-emerald-600 fill-emerald-100 shrink-0" />
                    </div>
                    <p className="text-[11px] text-slate-500 mt-0.5">{s.address}</p>
                  </div>
                  <span className="text-xs font-extrabold text-emerald-600 shrink-0 bg-emerald-50 px-2 py-0.5 rounded-md">
                    {distance}
                  </span>
                </div>

                <div className="flex items-center justify-between text-xs pt-2 border-t border-slate-100">
                  <div className="flex items-center gap-1 font-bold text-slate-700">
                    <Zap className="w-3.5 h-3.5 text-emerald-600" /> {s.powerKw} kW DC
                  </div>
                  <span className="font-extrabold text-emerald-700 bg-emerald-100/60 px-2 py-0.5 rounded-md text-[11px]">
                    {s.availableChargers}/{s.totalChargers} Available
                  </span>
                </div>
              </div>
            );
          })}
        </div>
      </div>

      {/* 2. Main Google Maps Visual Section */}
      <div className="flex-1 relative bg-slate-900">
        {/* Top Floating Search Bar (Web & Mobile overlay) */}
        <div className="absolute top-4 left-4 right-4 md:left-6 md:right-auto md:w-96 z-10 flex items-center gap-2">
          <div className="flex-1 bg-white/95 backdrop-blur border border-slate-200 shadow-lg rounded-2xl p-2.5 flex items-center gap-3">
            <Search className="w-4 h-4 text-slate-400" />
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="Search station or city..."
              className="w-full bg-transparent text-xs text-slate-900 placeholder-slate-400 focus:outline-none font-medium"
            />
            <Mic className="w-4 h-4 text-emerald-600 cursor-pointer" />
            <SlidersHorizontal className="w-4 h-4 text-slate-400 cursor-pointer hover:text-slate-600" />
          </div>
        </div>

        {/* Right Floating Controls */}
        <div className="absolute top-4 right-4 z-10 flex flex-col gap-2">
          <button
            onClick={fetchStations}
            className={`p-3 bg-white border border-slate-200 shadow-lg rounded-2xl text-slate-700 hover:bg-slate-50 transition-all ${
              isRefreshing ? 'animate-spin text-emerald-600' : ''
            }`}
            title="Refresh Stations"
          >
            <RefreshCw className="w-5 h-5" />
          </button>

          <button
            onClick={handleRecenter}
            className="p-3 bg-white border border-slate-200 shadow-lg rounded-2xl text-emerald-600 hover:bg-emerald-50 transition-all"
            title="My Location"
          >
            <Compass className="w-5 h-5" />
          </button>

          <button
            onClick={() => setSidebarOpen(!sidebarOpen)}
            className="p-3 bg-slate-900 border border-slate-800 shadow-lg rounded-2xl text-white hover:bg-slate-800 transition-all md:hidden"
            title="Toggle Station List"
          >
            <List className="w-5 h-5" />
          </button>
        </div>

        {/* Map Canvas */}
        {!apiKey ? (
          <div className="h-full flex items-center justify-center p-6 text-center">
            <div className="max-w-md bg-slate-800 border border-slate-700 rounded-3xl p-8 space-y-4 shadow-2xl">
              <AlertTriangle className="w-12 h-12 text-amber-400 mx-auto" />
              <h3 className="text-xl font-bold text-white">Google Maps API Key Missing</h3>
              <p className="text-xs text-slate-400 leading-relaxed">
                Add <code className="text-emerald-400 bg-slate-900 px-1.5 py-0.5 rounded">VITE_GOOGLE_MAPS_API_KEY</code> to environment settings.
              </p>
            </div>
          </div>
        ) : loadError ? (
          <div className="h-full flex items-center justify-center p-6 text-center">
            <div className="max-w-md bg-slate-800 border border-slate-700 rounded-3xl p-8 space-y-4 shadow-2xl">
              <AlertTriangle className="w-12 h-12 text-rose-400 mx-auto" />
              <h3 className="text-xl font-bold text-white">Google Maps Failed to Load</h3>
              <p className="text-xs text-slate-400 leading-relaxed">
                Check network connection or Maps key permissions.
              </p>
            </div>
          </div>
        ) : !isLoaded ? (
          <div className="h-full flex items-center justify-center space-y-3 flex-col bg-slate-900">
            <div className="w-10 h-10 border-4 border-emerald-500/20 border-t-emerald-500 rounded-full animate-spin"></div>
            <p className="text-xs font-semibold text-slate-400">Loading Interactive Google Map...</p>
          </div>
        ) : (
          <GoogleMap
            mapContainerStyle={mapContainerStyle}
            center={userLocation}
            zoom={13}
            onLoad={onMapLoad}
            options={{
              disableDefaultUI: false,
              zoomControl: true,
              streetViewControl: false,
              mapTypeControl: false,
            }}
          >
            {/* User Location Blue Marker */}
            <Marker
              position={userLocation}
              title="Your Location"
              icon={{
                url: 'https://maps.google.com/mapfiles/ms/icons/blue-dot.png',
              }}
            />

            {/* Charging Stations Green Markers */}
            {filteredStations.map((s) => (
              <Marker
                key={s.id}
                position={{ lat: s.lat, lng: s.lng }}
                title={s.name}
                icon={{
                  url: 'https://maps.google.com/mapfiles/ms/icons/green-dot.png',
                }}
                onClick={() => setSelectedStation(s)}
              />
            ))}
          </GoogleMap>
        )}

        {/* 3. Bottom Floating Station Card (Reference Design UI) */}
        {selectedStation && (
          <div className="absolute bottom-4 left-4 right-4 md:left-auto md:right-6 md:w-[420px] z-20 transition-all duration-300">
            <div className="bg-white border border-slate-200 rounded-3xl p-5 shadow-2xl space-y-4">
              <div className="flex gap-4">
                <img
                  src={selectedStation.imageUrl}
                  alt={selectedStation.name}
                  loading="lazy"
                  onError={(e) => {
                    (e.currentTarget as HTMLImageElement).src = 'https://images.unsplash.com/photo-1593941707882-a5bba14938c7?auto=format&fit=crop&w=600&q=80';
                  }}
                  className="w-24 h-24 object-cover rounded-2xl border border-slate-100 shrink-0"
                />

                <div className="flex-1 space-y-1">
                  <div className="flex items-center justify-between">
                    <span className="text-[10px] font-extrabold uppercase tracking-wider text-emerald-700 bg-emerald-100/60 px-2 py-0.5 rounded-md">
                      {selectedStation.isOpen247 ? '24x7 Open' : 'Open Now'}
                    </span>
                    <span className="flex items-center gap-0.5 text-xs font-bold text-amber-600 bg-amber-50 px-1.5 py-0.5 rounded">
                      <Star className="w-3.5 h-3.5 fill-amber-500 text-amber-500" /> {selectedStation.rating}
                    </span>
                  </div>

                  <h3 className="font-extrabold text-slate-900 text-base leading-tight pt-1">
                    {selectedStation.name}
                  </h3>
                  <p className="text-xs text-slate-500 line-clamp-1">{selectedStation.address}</p>

                  <div className="pt-1 flex items-center justify-between text-xs">
                    <span className="font-extrabold text-emerald-600">
                      {calculateDistanceStr(selectedStation.lat, selectedStation.lng)} away
                    </span>
                    <span className="font-extrabold text-slate-900">
                      ₹{selectedStation.pricePerKwh.toFixed(1)} / kWh
                    </span>
                  </div>
                </div>
              </div>

              {/* Connectors Chips & Amenities */}
              <div className="pt-2 border-t border-slate-100 flex items-center justify-between flex-wrap gap-2 text-xs">
                <div className="flex items-center gap-1.5 flex-wrap">
                  {selectedStation.plugs.map((p) => (
                    <span key={p} className="px-2.5 py-1 bg-slate-100 text-slate-700 rounded-lg text-[11px] font-bold">
                      {p}
                    </span>
                  ))}
                  <span className="px-2.5 py-1 bg-emerald-50 text-emerald-700 border border-emerald-100 rounded-lg text-[11px] font-bold">
                    {selectedStation.availableChargers}/{selectedStation.totalChargers} Available
                  </span>
                </div>
              </div>

              {/* Action Buttons */}
              <div className="flex items-center gap-3 pt-1">
                <a
                  href={`https://www.google.com/maps/dir/?api=1&destination=${selectedStation.lat},${selectedStation.lng}`}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="flex-1 py-3 bg-blue-600 hover:bg-blue-700 font-bold text-white text-xs rounded-xl transition-all shadow-md shadow-blue-600/20 text-center inline-flex items-center justify-center gap-1.5"
                >
                  <Navigation className="w-4 h-4" /> Get Directions
                </a>

                <button
                  onClick={() => alert(`Starting EV charging session at ${selectedStation.name}`)}
                  className="flex-1 py-3 bg-emerald-600 hover:bg-emerald-700 font-bold text-white text-xs rounded-xl transition-all shadow-md shadow-emerald-600/20 text-center inline-flex items-center justify-center gap-1.5"
                >
                  <Zap className="w-4 h-4 fill-white" /> Start Charging
                </button>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};
