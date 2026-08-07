import React, { useState, useEffect, useCallback, useRef } from 'react';
import { useJsApiLoader, GoogleMap, Marker, InfoWindow } from '@react-google-maps/api';
import { Search, MapPin, Navigation, Zap, AlertTriangle, RefreshCw, Compass } from 'lucide-react';

interface Station {
  id: string;
  name: string;
  address: string;
  lat: number;
  lng: number;
  totalChargers: number;
  availableChargers: number;
  plugs: string;
  price: string;
  isAvailable: boolean;
}

const DEFAULT_CENTER = { lat: 26.9124, lng: 75.7873 }; // Jaipur Default

const INITIAL_STATIONS: Station[] = [
  {
    id: 'ST-001',
    name: 'GreenCharge Hub Sector 62',
    address: 'Tonk Road, Jaipur, Rajasthan 302018',
    lat: 26.9150,
    lng: 75.7920,
    totalChargers: 6,
    availableChargers: 4,
    plugs: 'CCS2 (DC Fast 60kW)',
    price: '₹12 / kWh',
    isAvailable: true,
  },
  {
    id: 'ST-002',
    name: 'EcoFast Ultra Hub Malviya Nagar',
    address: 'Apex Circle, Malviya Nagar, Jaipur 302017',
    lat: 26.8540,
    lng: 75.8140,
    totalChargers: 8,
    availableChargers: 5,
    plugs: 'CCS2 / GB/T (DC 120kW)',
    price: '₹15 / kWh',
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
    plugs: 'Type 2 (AC 22kW)',
    price: '₹10 / kWh',
    isAvailable: true,
  },
  {
    id: 'ST-004',
    name: 'ChargeZone Express Vaishali Nagar',
    address: 'Queens Road, Vaishali Nagar, Jaipur 302021',
    lat: 26.9080,
    lng: 75.7480,
    totalChargers: 10,
    availableChargers: 7,
    plugs: 'CCS2 (DC 240kW Ultra)',
    price: '₹18 / kWh',
    isAvailable: true,
  },
];

const mapContainerStyle = {
  width: '100%',
  height: '100%',
};

export const MapPage: React.FC = () => {
  const apiKey = import.meta.env.VITE_GOOGLE_MAPS_API_KEY || 'AIzaSyCA9F7oYVMsSVIQosGoLMuUE5ZP-oHOt6g';

  const { isLoaded, loadError } = useJsApiLoader({
    googleMapsApiKey: apiKey,
    id: 'google-map-script',
  });

  const [map, setMap] = useState<google.maps.Map | null>(null);
  const [userLocation, setUserLocation] = useState<{ lat: number; lng: number }>(DEFAULT_CENTER);
  const [hasLocation, setHasLocation] = useState(false);
  const [selectedStation, setSelectedStation] = useState<Station | null>(null);
  const [selectedPlugFilter, setSelectedPlugFilter] = useState('ALL');
  const [searchQuery, setSearchQuery] = useState('');

  // Detect GPS position on mount
  useEffect(() => {
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(
        (position) => {
          const userPos = {
            lat: position.coords.latitude,
            lng: position.coords.longitude,
          };
          setUserLocation(userPos);
          setHasLocation(true);
          if (map) {
            map.panTo(userPos);
            map.setZoom(14);
          }
        },
        () => {
          // Fallback to Jaipur if permission denied
          setUserLocation(DEFAULT_CENTER);
        },
        { enableHighAccuracy: true, timeout: 10000 }
      );
    }
  }, [map]);

  const onMapLoad = useCallback((mapInstance: google.maps.Map) => {
    setMap(mapInstance);
  }, []);

  const calculateDistanceStr = (targetLat: number, targetLng: number): string => {
    const R = 6371; // Earth radius in km
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

  const filteredStations = INITIAL_STATIONS.filter((s) => {
    const matchesSearch =
      s.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      s.address.toLowerCase().includes(searchQuery.toLowerCase());
    const matchesPlug =
      selectedPlugFilter === 'ALL' || s.plugs.toUpperCase().includes(selectedPlugFilter);
    return matchesSearch && matchesPlug;
  });

  const handleSelectStation = (s: Station) => {
    setSelectedStation(s);
    if (map) {
      map.panTo({ lat: s.lat, lng: s.lng });
      map.setZoom(15);
    }
  };

  const handleRecenter = () => {
    if (map) {
      map.panTo(userLocation);
      map.setZoom(14);
    }
  };

  return (
    <div className="h-[calc(100vh-80px)] flex flex-col md:flex-row overflow-hidden bg-slate-50">
      {/* Sidebar Station Finder */}
      <div className="w-full md:w-96 bg-white border-r border-slate-200 flex flex-col overflow-hidden shadow-sm z-10">
        <div className="p-4 border-b border-slate-200 space-y-3">
          <div className="flex items-center justify-between">
            <h2 className="font-bold text-slate-900 text-base">Nearby Charging Hubs</h2>
            <button
              onClick={handleRecenter}
              className="p-1.5 rounded-lg bg-emerald-50 text-emerald-600 hover:bg-emerald-100 transition-all text-xs font-semibold flex items-center gap-1"
              title="Center on My Location"
            >
              <Compass className="w-4 h-4" /> My GPS
            </button>
          </div>

          <div className="relative">
            <Search className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="Search station or locality..."
              className="w-full pl-9 pr-4 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs text-slate-900 focus:outline-none focus:border-emerald-500"
            />
          </div>

          <select
            value={selectedPlugFilter}
            onChange={(e) => setSelectedPlugFilter(e.target.value)}
            className="w-full bg-slate-50 border border-slate-200 rounded-lg text-xs text-slate-700 px-3 py-1.5 focus:outline-none"
          >
            <option value="ALL">All Connectors</option>
            <option value="CCS2">DC Fast CCS2</option>
            <option value="TYPE 2">AC Type 2</option>
            <option value="GB/T">GB/T DC</option>
          </select>
        </div>

        <div className="flex-1 overflow-y-auto p-4 space-y-3">
          {filteredStations.map((s) => {
            const distance = calculateDistanceStr(s.lat, s.lng);
            const isSelected = selectedStation?.id === s.id;
            return (
              <div
                key={s.id}
                onClick={() => handleSelectStation(s)}
                className={`p-4 rounded-xl border transition-all cursor-pointer space-y-2 ${
                  isSelected
                    ? 'bg-emerald-50/80 border-emerald-500 shadow-md'
                    : 'bg-white border-slate-200 hover:border-slate-300 shadow-sm'
                }`}
              >
                <div className="flex justify-between items-start">
                  <div>
                    <h4 className="font-bold text-slate-900 text-sm">{s.name}</h4>
                    <p className="text-[11px] text-slate-500">{s.address}</p>
                  </div>
                  <span className="text-xs font-bold text-emerald-600">{distance}</span>
                </div>
                <div className="flex items-center justify-between text-[11px] pt-2 border-t border-slate-100">
                  <span className="text-slate-600 font-medium">{s.plugs}</span>
                  <span className="text-emerald-600 font-bold">
                    {s.availableChargers}/{s.totalChargers} Available
                  </span>
                </div>
              </div>
            );
          })}
        </div>
      </div>

      {/* Main Google Maps Section */}
      <div className="flex-1 relative bg-slate-900">
        {loadError ? (
          <div className="h-full flex items-center justify-center p-6 text-center">
            <div className="max-w-sm bg-slate-800 border border-slate-700 rounded-2xl p-6 space-y-4">
              <AlertTriangle className="w-10 h-10 text-amber-400 mx-auto" />
              <h3 className="text-lg font-bold text-white">Google Maps Error</h3>
              <p className="text-xs text-slate-400">
                Failed to load Google Maps script. Check `VITE_GOOGLE_MAPS_API_KEY` configuration.
              </p>
            </div>
          </div>
        ) : !isLoaded ? (
          <div className="h-full flex items-center justify-center space-y-3 flex-col">
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
            {/* User Live Location Blue Marker */}
            <Marker
              position={userLocation}
              title="Your Current Location"
              icon={{
                url: 'https://maps.google.com/mapfiles/ms/icons/blue-dot.png',
              }}
            />

            {/* EV Charging Stations Green Markers */}
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

            {/* InfoWindow for Selected Station */}
            {selectedStation && (
              <InfoWindow
                position={{ lat: selectedStation.lat, lng: selectedStation.lng }}
                onCloseClick={() => setSelectedStation(null)}
              >
                <div className="p-2 max-w-xs space-y-2 text-slate-900">
                  <div className="flex items-center gap-1.5">
                    <Zap className="w-4 h-4 text-emerald-600" />
                    <h4 className="font-bold text-sm leading-tight text-slate-900">{selectedStation.name}</h4>
                  </div>
                  <p className="text-[11px] text-slate-600">{selectedStation.address}</p>
                  
                  <div className="text-xs pt-1 border-t border-slate-200 space-y-1">
                    <p className="font-semibold text-emerald-700">
                      Connectors: <span className="text-slate-800">{selectedStation.plugs}</span>
                    </p>
                    <p className="font-semibold text-emerald-700">
                      Available: <span className="text-slate-800">{selectedStation.availableChargers}/{selectedStation.totalChargers} Chargers</span>
                    </p>
                    <p className="font-semibold text-emerald-700">
                      Rate: <span className="text-slate-800">{selectedStation.price}</span>
                    </p>
                    <p className="font-semibold text-emerald-700">
                      Distance: <span className="text-slate-800">{calculateDistanceStr(selectedStation.lat, selectedStation.lng)}</span>
                    </p>
                  </div>

                  <div className="pt-2 flex gap-2">
                    <a
                      href={`https://www.google.com/maps/dir/?api=1&destination=${selectedStation.lat},${selectedStation.lng}`}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="flex-1 px-3 py-1.5 bg-slate-900 text-white rounded-lg text-center text-xs font-semibold hover:bg-slate-800 inline-flex items-center justify-center gap-1"
                    >
                      <Navigation className="w-3 h-3" /> Navigate
                    </a>
                    <button
                      onClick={() => alert(`Initiating charging session at ${selectedStation.name}`)}
                      className="flex-1 px-3 py-1.5 bg-emerald-600 text-white rounded-lg text-center text-xs font-bold hover:bg-emerald-700"
                    >
                      Start Charge
                    </button>
                  </div>
                </div>
              </InfoWindow>
            )}
          </GoogleMap>
        )}
      </div>
    </div>
  );
};
