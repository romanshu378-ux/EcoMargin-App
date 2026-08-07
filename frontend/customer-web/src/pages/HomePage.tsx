import React, { useState } from 'react';
import { Link } from 'react-router-dom';
import { 
  Search, 
  SlidersHorizontal, 
  MapPin, 
  Heart, 
  CheckCircle2, 
  Zap, 
  QrCode, 
  History, 
  Wallet, 
  ChevronRight, 
  Plus, 
  Sparkles,
  PlugZap,
  Coins
} from 'lucide-react';

interface Station {
  id: string;
  name: string;
  address: string;
  distanceStr: string;
  totalChargers: number;
  availableChargers: number;
  chargerType: string;
  chargerCategory: string;
  priceStr: string;
  priceSubtext: string;
  imageUrl: string;
  isVerified: boolean;
  isFavorite: boolean;
}

export const HomePage: React.FC = () => {
  const [searchQuery, setSearchQuery] = useState('');
  const [heroSlide, setHeroSlide] = useState(1);

  const [stations, setStations] = useState<Station[]>([
    {
      id: '1',
      name: 'EcoMargin Charging Station',
      address: 'Tonk Road, Jaipur, Rajasthan',
      distanceStr: '0.8 km Away',
      totalChargers: 6,
      availableChargers: 4,
      chargerType: 'DC 60kW',
      chargerCategory: 'Fast Charger',
      priceStr: '₹12 / kWh',
      priceSubtext: 'Starting from',
      imageUrl: 'https://images.unsplash.com/photo-1563720223185-11003d516935?w=500&q=80',
      isVerified: true,
      isFavorite: false,
    },
    {
      id: '2',
      name: 'EcoMargin Express Hub',
      address: 'Malviya Nagar, Jaipur, Rajasthan',
      distanceStr: '2.4 km Away',
      totalChargers: 8,
      availableChargers: 5,
      chargerType: 'DC 120kW',
      chargerCategory: 'Super Charger',
      priceStr: '₹15 / kWh',
      priceSubtext: 'Starting from',
      imageUrl: 'https://images.unsplash.com/photo-1558441719-6705166e2860?w=500&q=80',
      isVerified: true,
      isFavorite: true,
    },
  ]);

  const toggleFavorite = (id: string) => {
    setStations(prev =>
      prev.map(s => (s.id === id ? { ...s, isFavorite: !s.isFavorite } : s))
    );
  };

  const filteredStations = stations.filter(
    s =>
      s.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      s.address.toLowerCase().includes(searchQuery.toLowerCase())
  );

  return (
    <div className="max-w-6xl mx-auto px-4 sm:px-6 py-6 space-y-8">
      {/* 1. Hero Banner Slider */}
      <div className="relative rounded-3xl bg-gradient-to-r from-slate-900 via-emerald-950 to-slate-900 border border-slate-200 p-8 md:p-10 overflow-hidden shadow-xl">
        <div className="absolute right-0 top-0 bottom-0 w-1/2 opacity-25 pointer-events-none bg-no-repeat bg-cover bg-center" style={{ backgroundImage: `url('https://images.unsplash.com/photo-1563720223185-11003d516935?w=800&q=80')` }}></div>
        
        <div className="relative z-10 max-w-xl space-y-4">
          <div className="space-y-1">
            <h1 className="text-3xl md:text-5xl font-black text-white tracking-tight leading-tight">
              Powering <br />
              <span className="text-emerald-400">a Greener Future</span>
            </h1>
            <p className="text-slate-200 text-sm md:text-base pt-1">
              Find, Book & Charge at the best EV charging stations.
            </p>
          </div>

          <div className="pt-2">
            <Link
              to="/map"
              className="inline-flex items-center gap-2 px-6 py-3 bg-emerald-600 hover:bg-emerald-500 font-bold text-white text-sm rounded-xl transition-all shadow-md shadow-emerald-600/30"
            >
              Find Stations <ChevronRight className="w-4 h-4" />
            </Link>
          </div>
        </div>

        {/* Carousel Page Dots */}
        <div className="relative z-10 flex items-center justify-center gap-1.5 pt-6">
          {[0, 1, 2, 3, 4].map((dot) => (
            <button
              key={dot}
              onClick={() => setHeroSlide(dot)}
              className={`h-2 rounded-full transition-all ${
                heroSlide === dot
                  ? 'w-6 bg-emerald-400'
                  : 'w-2 bg-slate-600 hover:bg-slate-500'
              }`}
            />
          ))}
        </div>
      </div>

      {/* 2. Search & Location Filter Section */}
      <div className="bg-white border border-slate-200 rounded-2xl p-4 shadow-sm flex flex-col md:flex-row items-center gap-4">
        <div className="flex items-center gap-3 w-full md:w-auto">
          <div className="p-2.5 rounded-xl bg-emerald-50 text-emerald-600 border border-emerald-100">
            <MapPin className="w-5 h-5" />
          </div>
          <div>
            <p className="text-[11px] font-bold text-emerald-600 uppercase tracking-wider">Current Location</p>
            <p className="text-xs font-bold text-slate-900">Jaipur, Rajasthan, India</p>
          </div>
        </div>

        <div className="h-8 w-px bg-slate-200 hidden md:block"></div>

        <div className="relative flex-1 w-full">
          <Search className="w-4 h-4 text-slate-400 absolute left-4 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Search charging stations..."
            className="w-full bg-slate-50 border border-slate-200 focus:border-emerald-500 rounded-xl pl-11 pr-4 py-2.5 text-xs text-slate-900 placeholder-slate-400 focus:outline-none transition-all"
          />
        </div>

        <button className="flex items-center justify-center gap-2 px-4 py-2.5 bg-slate-50 hover:bg-slate-100 border border-slate-200 rounded-xl text-xs font-semibold text-emerald-600 transition-all w-full md:w-auto">
          <SlidersHorizontal className="w-4 h-4" /> Filters
        </button>
      </div>

      {/* 3. Nearby Stations Section */}
      <div className="space-y-4">
        <div className="flex items-center justify-between">
          <h2 className="text-xl font-bold text-slate-900 tracking-tight">Nearby Stations</h2>
          <Link to="/map" className="flex items-center gap-1 text-xs font-bold text-emerald-600 hover:text-emerald-700 transition-all">
            View all <ChevronRight className="w-4 h-4" />
          </Link>
        </div>

        <div className="grid grid-cols-1 gap-4">
          {filteredStations.map((station) => (
            <div
              key={station.id}
              className="bg-white border border-slate-200 rounded-2xl p-5 hover:border-slate-300 transition-all space-y-4 shadow-sm"
            >
              <div className="flex flex-col sm:flex-row items-start sm:items-center gap-4">
                <img
                  src={station.imageUrl}
                  alt={station.name}
                  className="w-full sm:w-28 h-24 object-cover rounded-xl border border-slate-100"
                />
                
                <div className="flex-1 space-y-1.5 w-full">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-2">
                      <h3 className="text-base font-bold text-slate-900">{station.name}</h3>
                      {station.isVerified && (
                        <CheckCircle2 className="w-4 h-4 text-emerald-600 fill-emerald-100" />
                      )}
                    </div>
                    <button
                      onClick={() => toggleFavorite(station.id)}
                      className="p-2 text-slate-400 hover:text-rose-500 transition-all"
                    >
                      <Heart className={`w-5 h-5 ${station.isFavorite ? 'fill-rose-500 text-rose-500' : ''}`} />
                    </button>
                  </div>

                  <div className="flex items-center gap-1.5 text-xs text-slate-500">
                    <MapPin className="w-3.5 h-3.5 text-slate-400" />
                    <span>{station.address}</span>
                  </div>

                  <div>
                    <span className="inline-block px-2.5 py-1 rounded-md bg-emerald-50 border border-emerald-100 text-emerald-700 text-[11px] font-bold">
                      {station.distanceStr}
                    </span>
                  </div>
                </div>
              </div>

              <div className="pt-3 border-t border-slate-100 flex flex-wrap items-center justify-between gap-4">
                <div className="flex flex-wrap items-center gap-6 text-xs">
                  <div className="flex items-center gap-2">
                    <div className="p-1.5 rounded-lg bg-emerald-50 text-emerald-600">
                      <PlugZap className="w-4 h-4" />
                    </div>
                    <div>
                      <p className="font-bold text-slate-900">{station.availableChargers} / {station.totalChargers}</p>
                      <p className="text-[10px] text-slate-500">Available</p>
                    </div>
                  </div>

                  <div className="flex items-center gap-2">
                    <div className="p-1.5 rounded-lg bg-emerald-50 text-emerald-600">
                      <Zap className="w-4 h-4" />
                    </div>
                    <div>
                      <p className="font-bold text-slate-900">{station.chargerType}</p>
                      <p className="text-[10px] text-slate-500">{station.chargerCategory}</p>
                    </div>
                  </div>

                  <div className="flex items-center gap-2">
                    <div className="p-1.5 rounded-lg bg-emerald-50 text-emerald-600">
                      <Coins className="w-4 h-4" />
                    </div>
                    <div>
                      <p className="font-bold text-slate-900">{station.priceStr}</p>
                      <p className="text-[10px] text-slate-500">{station.priceSubtext}</p>
                    </div>
                  </div>
                </div>

                <Link
                  to="/map"
                  className="px-5 py-2.5 bg-emerald-600 hover:bg-emerald-700 font-bold text-white text-xs rounded-xl transition-all shadow-sm shadow-emerald-600/20 w-full sm:w-auto text-center"
                >
                  View Details
                </Link>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* 4. Quick Actions Grid */}
      <div className="space-y-4">
        <h2 className="text-xl font-bold text-slate-900 tracking-tight">Quick Actions</h2>
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-4">
          <Link
            to="/map"
            className="bg-white border border-slate-200 rounded-2xl p-5 hover:border-emerald-500/40 transition-all flex flex-col items-center justify-center space-y-3 group shadow-sm"
          >
            <div className="w-12 h-12 rounded-2xl bg-emerald-50 border border-emerald-100 text-emerald-600 flex items-center justify-center group-hover:scale-110 transition-all">
              <QrCode className="w-6 h-6" />
            </div>
            <span className="text-xs font-bold text-slate-900">Scan QR</span>
          </Link>

          <Link
            to="/map"
            className="bg-white border border-slate-200 rounded-2xl p-5 hover:border-emerald-500/40 transition-all flex flex-col items-center justify-center space-y-3 group shadow-sm"
          >
            <div className="w-12 h-12 rounded-2xl bg-emerald-50 border border-emerald-100 text-emerald-600 flex items-center justify-center group-hover:scale-110 transition-all">
              <Heart className="w-6 h-6" />
            </div>
            <span className="text-xs font-bold text-slate-900">Favorites</span>
          </Link>

          <Link
            to="/history"
            className="bg-white border border-slate-200 rounded-2xl p-5 hover:border-emerald-500/40 transition-all flex flex-col items-center justify-center space-y-3 group shadow-sm"
          >
            <div className="w-12 h-12 rounded-2xl bg-emerald-50 border border-emerald-100 text-emerald-600 flex items-center justify-center group-hover:scale-110 transition-all">
              <History className="w-6 h-6" />
            </div>
            <span className="text-xs font-bold text-slate-900">Charging History</span>
          </Link>

          <Link
            to="/wallet"
            className="bg-white border border-slate-200 rounded-2xl p-5 hover:border-emerald-500/40 transition-all flex flex-col items-center justify-center space-y-3 group shadow-sm"
          >
            <div className="w-12 h-12 rounded-2xl bg-emerald-50 border border-emerald-100 text-emerald-600 flex items-center justify-center group-hover:scale-110 transition-all">
              <Wallet className="w-6 h-6" />
            </div>
            <span className="text-xs font-bold text-slate-900">Wallet</span>
          </Link>
        </div>
      </div>

      {/* 5. Wallet Balance Card */}
      <div className="bg-white border border-slate-200 rounded-2xl p-6 shadow-sm flex items-center justify-between flex-wrap gap-4">
        <div className="space-y-1">
          <p className="text-xs font-semibold text-slate-500">Wallet Balance</p>
          <p className="text-3xl font-black text-slate-900 tracking-tight">₹256.50</p>
          <div className="pt-2">
            <Link
              to="/wallet"
              className="inline-flex items-center gap-1.5 px-4 py-2 bg-emerald-600 hover:bg-emerald-700 font-bold text-white text-xs rounded-xl transition-all shadow-sm shadow-emerald-600/20"
            >
              <Plus className="w-4 h-4" /> Add Money
            </Link>
          </div>
        </div>

        <div className="w-16 h-16 rounded-2xl bg-emerald-50 border border-emerald-100 flex items-center justify-center text-emerald-600">
          <Wallet className="w-8 h-8" />
        </div>
      </div>

      {/* 6. Promotional Banner */}
      <div className="rounded-2xl bg-gradient-to-r from-slate-900 via-emerald-950 to-slate-900 border border-slate-200 p-6 flex items-center justify-between flex-wrap gap-4 shadow-sm">
        <div className="space-y-1">
          <h3 className="text-lg font-extrabold text-white">Drive Green, Save More</h3>
          <p className="text-xs text-slate-300">Special offers on every charging session.</p>
        </div>
        <div className="px-4 py-2 bg-emerald-500/20 border border-emerald-400/30 rounded-xl text-emerald-300 text-xs font-bold flex items-center gap-2">
          <Sparkles className="w-4 h-4" /> EcoPass Ready
        </div>
      </div>
    </div>
  );
};
