import React, { useState, useEffect, useCallback, useRef } from 'react';
import { useJsApiLoader, GoogleMap, Marker, InfoWindow } from '@react-google-maps/api';
import { Search, MapPin, Navigation, Zap, AlertTriangle, Compass, Star } from 'lucide-react';
import { api } from '../services/api';

interface Station {
  id: string;
  name: string;
  address: string;
  lat: number;
  lng: number;
  totalChargers: number;
  availableChargers: number;
  plugs: string;
  powerKw: number;
  pricePerKwh: number;
  rating: number;
  imageUrl: string;
  isAvailable: boolean;
}

const DEFAULT_CENTER = { lat: 26.9124, lng: 75.7873 }; // Jaipur Default

const FALLBACK_STATIONS: Station[] = [
  {
    id: 'ST-001',
    name: 'GreenCharge Hub Sector 62',
    address: 'Tonk Road, Jaipur, Rajasthan 302018',
    lat: 26.9150,
    lng: 75.7920,
    totalChargers: 6,
    availableChargers: 4,
    plugs: 'CCS2 (DC Fast)',
    powerKw: 60,
    pricePerKwh: 12,
    rating: 4.8,
    imageUrl: 'https://images.unsplash.com/photo-1563720223185-11003d516935?w=400&q=80',
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
    plugs: 'CCS2 / GB/T (DC Fast)',
    powerKw: 120,
    pricePerKwh: 15,
    rating: 4.9,
    imageUrl: 'https://images.unsplash.com/photo-1558441719-6705166e2860?w=400&q=80',
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
    plugs: 'Type 2 (AC Standard)',
    powerKw: 22,
    pricePerKwh: 10,
    rating: 4.6,
    imageUrl: 'https://images.unsplash.com/photo-1563720223185-11003d516935?w=400&q=80',
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
    plugs: 'CCS2 (DC Hyper Fast)',
    powerKw: 240,
    pricePerKwh: 18,
    rating: 4.95,
    imageUrl: 'https://images.unsplash.com/photo-1558441719-6705166e2860?w=400&q=80',
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
  const [locationDenied, setLocationDenied] = useState(false);
  const [stations, setStations] = useState<Station[]>(FALLBACK_STATIONS);
  const [isLoadingStations, setIsLoadingStations] = useState(false);
  const [selectedStation, setSelectedStation] = useState<Station | null>(null);
  const [selectedPlugFilter, setSelectedPlugFilter] = useState('ALL');
  const [minPowerFilter, setMinPowerFilter] = useState(0);
  const [searchQuery, setSearchQuery] = useState('');

  // Fetch stations from backend API
  useEffect(() => {
    setIsLoadingStations(true);
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
        setIsLoadingStations(false);
      });
  }, []);

  // Detect GPS user position
  useEffect(() => {
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(
        (position) => {
          const userPos = {
            lat: position.coords.latitude,
            lng: position.coords.longitude,
          };
          setUserLocation(userPos);
          setLocationDenied(false);
          if (map) {
            map.panTo(userPos);
          }
        },
        () => {
          setUserLocation(DEFAULT_CENTER);
          setLocationDenied(true);
        },
        { enableHighAccuracy: true, timeout: 10000 }
      );
    } else {
      setLocationDenied(true);
    }
  }, [map]);

  const onMapLoad = useCallback((mapInstance: google.maps.Map) => {
    setMap(mapInstance);
    // Fit map bounds to encompass user location and station markers
    if (window.google) {
      const bounds = new window.google.maps.LatLngBounds();
      bounds.extend(DEFAULT_CENTER);
      FALLBACK_STATIONS.forEach((s) => bounds.extend({ lat: s.lat, lng: s.lng }));
      mapInstance.fitBounds(bounds);
    }
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

  const filteredStations = stations.filter((s) => {
    const matchesSearch =
      s.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      s.address.toLowerCase().includes(searchQuery.toLowerCase());
    const matchesPlug =
      selectedPlugFilter === 'ALL' || s.plugs.toUpperCase().includes(selectedPlugFilter);
    const matchesPower = s.powerKw >= minPowerFilter;

    return matchesSearch && matchesPlug && matchesPower;
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
    <div className="h-[calc(100vh-80px)] flex flex-col md:flex-row overflow-hidden bg-slate-50 relative">
      {/* Sidebar Station Finder */}
      <div className="w-full md:w-96 bg-white border-r border-slate-200 flex flex-col overflow-hidden shadow-sm z-10">
        <div className="p-4 border-b border-slate-200 space-y-3">
          <div className="flex items-center justify-between">
            <h2 className="font-extrabold text-slate-900 text-base">EV Station Finder</h2>
            <button
              onClick={handleRecenter}
              className="p-1.5 rounded-lg bg-emerald-50 text-emerald-600 hover:bg-emerald-100 transition-all text-xs font-bold flex items-center gap-1"
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

          <div className="grid grid-cols-2 gap-2">
            <select
              value={selectedPlugFilter}
              onChange={(e) => setSelectedPlugFilter(e.target.value)}
              className="bg-slate-50 border border-slate-200 rounded-lg text-xs text-slate-700 px-3 py-1.5 focus:outline-none font-medium"
            >
              <option value="ALL">All Plugs</option>
              <option value="CCS2">DC CCS2</option>
              <option value="TYPE 2">AC Type 2</option>
              <option value="GB/T">GB/T DC</option>
            </select>

            <select
              value={minPowerFilter}
              onChange={(e) => setMinPowerFilter(Number(e.target.value))}
              className="bg-slate-50 border border-slate-200 rounded-lg text-xs text-slate-700 px-3 py-1.5 focus:outline-none font-medium"
            >
              <option value={0}>Any Power</option>
              <option value={50}>Fast (&gt;50kW)</option>
              <option value={100}>Ultra (&gt;100kW)</option>
            </select>
          </div>
        </div>

        {/* Station List */}
        <div className="flex-1 overflow-y-auto p-4 space-y-3">
          {isLoadingStations ? (
            [1, 2, 3].map((i) => (
              <div key={i} className="p-4 bg-slate-100 rounded-xl space-y-3 animate-pulse">
                <div className="h-4 bg-slate-200 rounded w-3/4"></div>
                <div className="h-3 bg-slate-200 rounded w-1/2"></div>
                <div className="h-3 bg-slate-200 rounded w-full"></div>
              </div>
            ))
          ) : filteredStations.length === 0 ? (
            <div className="py-12 text-center space-y-3">
              <MapPin className="w-10 h-10 text-slate-300 mx-auto" />
              <p className="text-sm font-bold text-slate-700">No charging stations found</p>
              <p className="text-xs text-slate-400">Try adjusting your search or power filters.</p>
            </div>
          ) : (
            filteredStations.map((s) => {
              const distance = calculateDistanceStr(s.lat, s.lng);
              const isSelected = selectedStation?.id === s.id;
              return (
                <div
                  key={s.id}
                  onClick={() => handleSelectStation(s)}
                  className={`p-4 rounded-xl border transition-all cursor-pointer space-y-2 ${
                    isSelected
                      ? 'bg-emerald-50/80 border-emerald-500 shadow-md ring-2 ring-emerald-500/20'
                      : 'bg-white border-slate-200 hover:border-slate-300 shadow-sm'
                  }`}
                >
                  <div className="flex justify-between items-start gap-2">
                    <div>
                      <h4 className="font-bold text-slate-900 text-sm leading-snug">{s.name}</h4>
                      <p className="text-[11px] text-slate-500 mt-0.5">{s.address}</p>
                    </div>
                    <span className="text-xs font-bold text-emerald-600 shrink-0">{distance}</span>
                  </div>

                  <div className="flex items-center justify-between text-[11px] pt-2 border-t border-slate-100">
                    <span className="text-slate-600 font-semibold">{s.plugs}</span>
                    <span className="text-emerald-700 font-bold bg-emerald-100/60 px-2 py-0.5 rounded">
                      {s.availableChargers}/{s.totalChargers} Available
                    </span>
                  </div>
                </div>
              );
            })
          )}
        </div>
      </div>

      {/* Main Interactive Google Map View */}
      <div className="flex-1 relative bg-slate-900">
        {!apiKey ? (
          <div className="h-full flex items-center justify-center p-6 text-center">
            <div className="max-w-md bg-slate-800 border border-slate-700 rounded-3xl p-8 space-y-4 shadow-2xl">
              <AlertTriangle className="w-12 h-12 text-amber-400 mx-auto" />
              <h3 className="text-xl font-bold text-white">Google Maps API Key Missing</h3>
              <p className="text-xs text-slate-400 leading-relaxed">
                Add <code className="text-emerald-400 bg-slate-900 px-1.5 py-0.5 rounded">VITE_GOOGLE_MAPS_API_KEY</code> to your environment configuration to enable interactive station mapping.
              </p>
            </div>
          </div>
        ) : loadError ? (
          <div className="h-full flex items-center justify-center p-6 text-center">
            <div className="max-w-md bg-slate-800 border border-slate-700 rounded-3xl p-8 space-y-4 shadow-2xl">
              <AlertTriangle className="w-12 h-12 text-rose-400 mx-auto" />
              <h3 className="text-xl font-bold text-white">Google Maps Failed to Load</h3>
              <p className="text-xs text-slate-400 leading-relaxed">
                Could not connect to Google Maps JS API. Verify network connection or key credentials.
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
            {/* User Live Location Blue Marker */}
            <Marker
              position={userLocation}
              title="Your Location"
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

            {/* InfoWindow Popup */}
            {selectedStation && (
              <InfoWindow
                position={{ lat: selectedStation.lat, lng: selectedStation.lng }}
                onCloseClick={() => setSelectedStation(null)}
              >
                <div className="p-1.5 max-w-xs space-y-2 text-slate-900">
                  <img
                    src={selectedStation.imageUrl}
                    alt={selectedStation.name}
                    className="w-full h-24 object-cover rounded-lg border border-slate-200"
                  />

                  <div>
                    <div className="flex items-center justify-between">
                      <h4 className="font-bold text-sm text-slate-900 leading-tight">{selectedStation.name}</h4>
                      <span className="flex items-center gap-0.5 text-xs font-bold text-amber-600 bg-amber-50 px-1.5 py-0.5 rounded ml-1">
                        <Star className="w-3 h-3 fill-amber-500 text-amber-500" /> {selectedStation.rating}
                      </span>
                    </div>
                    <p className="text-[11px] text-slate-600 mt-0.5">{selectedStation.address}</p>
                  </div>

                  <div className="text-xs pt-1.5 border-t border-slate-200 space-y-1">
                    <div className="flex justify-between">
                      <span className="text-slate-500">Power Rating:</span>
                      <span className="font-bold text-slate-900">{selectedStation.powerKw} kW Fast</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-slate-500">Tariff Rate:</span>
                      <span className="font-bold text-emerald-600">₹{selectedStation.pricePerKwh} / kWh</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-slate-500">Availability:</span>
                      <span className="font-bold text-slate-900">{selectedStation.availableChargers}/{selectedStation.totalChargers} Free</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-slate-500">Distance:</span>
                      <span className="font-bold text-slate-900">{calculateDistanceStr(selectedStation.lat, selectedStation.lng)}</span>
                    </div>
                  </div>

                  <div className="pt-2 flex gap-2">
                    <a
                      href={`https://www.google.com/maps/dir/?api=1&destination=${selectedStation.lat},${selectedStation.lng}`}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="flex-1 px-3 py-1.5 bg-slate-900 text-white rounded-lg text-center text-xs font-semibold hover:bg-slate-800 inline-flex items-center justify-center gap-1"
                    >
                      <Navigation className="w-3 h-3" /> Directions
                    </a>
                    <button
                      onClick={() => alert(`Starting EV charging session at ${selectedStation.name}`)}
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
