import React, { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
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
  Shield, 
  ArrowRight,
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
  const navigate = useNavigate();
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
      <div className="relative rounded-3xl bg-gradient-to-r from-slate-950 via-slate-900 to-emerald-950/80 border border-emerald-500/20 p-8 md:p-10 overflow-hidden shadow-2xl">
        <div className="absolute right-0 top-0 bottom-0 w-1/2 opacity-20 md:opacity-30 pointer-events-none bg-no-repeat bg-cover bg-center" style={{ backgroundImage: `url('https://images.unsplash.com/photo-1563720223185-11003d516935?w=800&q=80')` }}></div>
        
        <div className="relative z-10 max-w-xl space-y-4">
          <div className="space-y-1">
            <h1 className="text-3xl md:text-5xl font-black text-white tracking-tight leading-tight">
              Powering <br />
              <span className="text-emerald-400">a Greener Future</span>
            </h1>
            <p className="text-slate-300 text-sm md:text-base pt-1">
              Find, Book & Charge at the best EV charging stations.
            </p>
          </div>

          <div className="pt-2">
            <Link
              to="/map"
              className="inline-flex items-center gap-2 px-6 py-3 bg-emerald-600 hover:bg-emerald-500 font-bold text-white text-sm rounded-xl transition-all shadow-lg shadow-emerald-600/30"
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
                  : 'w-2 bg-slate-700 hover:bg-slate-600'
              }`}
            />
          ))}
        </div>
      </div>

      {/* 2. Search & Location Filter Section */}
      <div className="bg-slate-900 border border-slate-800 rounded-2xl p-4 shadow-xl flex flex-col md:flex-row items-center gap-4">
        <div className="flex items-center gap-3 w-full md:w-auto">
          <div className="p-2.5 rounded-xl bg-emerald-500/10 border border-emerald-500/20 text-emerald-400">
            <MapPin className="w-5 h-5" />
          </div>
          <div>
            <p className="text-[11px] font-bold text-emerald-400 uppercase tracking-wider">Current Location</p>
            <p className="text-xs font-semibold text-white">Jaipur, Rajasthan, India</p>
          </div>
        </div>

        <div className="h-8 w-px bg-slate-800 hidden md:block"></div>

        <div className="relative flex-1 w-full">
          <Search className="w-4 h-4 text-slate-400 absolute left-4 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Search charging stations..."
            className="w-full bg-slate-950 border border-slate-800 focus:border-emerald-500 rounded-xl pl-11 pr-4 py-2.5 text-xs text-white placeholder-slate-500 focus:outline-none transition-all"
          />
        </div>

        <button className="flex items-center justify-center gap-2 px-4 py-2.5 bg-slate-800 hover:bg-slate-700 border border-slate-700 rounded-xl text-xs font-semibold text-emerald-400 transition-all w-full md:w-auto">
          <SlidersHorizontal className="w-4 h-4" /> Filters
        </button>
      </div>

      {/* 3. Nearby Stations Section */}
      <div className="space-y-4">
        <div className="flex items-center justify-between">
          <h2 className="text-xl font-bold text-white tracking-tight">Nearby Stations</h2>
          <Link to="/map" className="flex items-center gap-1 text-xs font-bold text-emerald-400 hover:text-emerald-300 transition-all">
            View all <ChevronRight className="w-4 h-4" />
          </Link>
        </div>

        <div className="grid grid-cols-1 gap-4">
          {filteredStations.map((station) => (
            <div
              key={station.id}
              className="bg-slate-900 border border-slate-800 rounded-2xl p-5 hover:border-slate-700 transition-all space-y-4 shadow-lg"
            >
              <div className="flex flex-col sm:flex-row items-start sm:items-center gap-4">
                <img
                  src={station.imageUrl}
                  alt={station.name}
                  className="w-full sm:w-28 h-24 object-cover rounded-xl border border-slate-800"
                />
                
                <div className="flex-1 space-y-1.5 w-full">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-2">
                      <h3 className="text-base font-bold text-white">{station.name}</h3>
                      {station.isVerified && (
                        <CheckCircle2 className="w-4 h-4 text-emerald-400 fill-emerald-400/20" />
                      )}
                    </div>
                    <button
                      onClick={() => toggleFavorite(station.id)}
                      className="p-2 text-slate-400 hover:text-rose-400 transition-all"
                    >
                      <Heart className={`w-5 h-5 ${station.isFavorite ? 'fill-rose-500 text-rose-500' : ''}`} />
                    </button>
                  </div>

                  <div className="flex items-center gap-1.5 text-xs text-slate-400">
                    <MapPin className="w-3.5 h-3.5 text-slate-500" />
                    <span>{station.address}</span>
                  </div>

                  <div>
                    <span className="inline-block px-2.5 py-1 rounded-md bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 text-[11px] font-bold">
                      {station.distanceStr}
                    </span>
                  </div>
                </div>
              </div>

              <div className="pt-3 border-t border-slate-800/80 flex flex-wrap items-center justify-between gap-4">
                <div className="flex flex-wrap items-center gap-6 text-xs">
                  <div className="flex items-center gap-2">
                    <div className="p-1.5 rounded-lg bg-emerald-500/10 text-emerald-400">
                      <PlugZap className="w-4 h-4" />
                    </div>
                    <div>
                      <p className="font-bold text-white">{station.availableChargers} / {station.totalChargers}</p>
                      <p className="text-[10px] text-slate-400">Available</p>
                    </div>
                  </div>

                  <div className="flex items-center gap-2">
                    <div className="p-1.5 rounded-lg bg-emerald-500/10 text-emerald-400">
                      <Zap className="w-4 h-4" />
                    </div>
                    <div>
                      <p className="font-bold text-white">{station.chargerType}</p>
                      <p className="text-[10px] text-slate-400">{station.chargerCategory}</p>
                    </div>
                  </div>

                  <div className="flex items-center gap-2">
                    <div className="p-1.5 rounded-lg bg-emerald-500/10 text-emerald-400">
                      <Coins className="w-4 h-4" />
                    </div>
                    <div>
                      <p className="font-bold text-white">{station.priceStr}</p>
                      <p className="text-[10px] text-slate-400">{station.priceSubtext}</p>
                    </div>
                  </div>
                </div>

                <Link
                  to="/map"
                  className="px-5 py-2.5 bg-emerald-600 hover:bg-emerald-500 font-bold text-white text-xs rounded-xl transition-all shadow-md shadow-emerald-600/20 w-full sm:w-auto text-center"
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
        <h2 className="text-xl font-bold text-white tracking-tight">Quick Actions</h2>
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-4">
          <Link
            to="/map"
            className="bg-slate-900 border border-slate-800 rounded-2xl p-5 hover:border-emerald-500/40 transition-all flex flex-col items-center justify-center space-y-3 group shadow-lg"
          >
            <div className="w-12 h-12 rounded-2xl bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 flex items-center justify-center group-hover:scale-110 transition-all">
              <QrCode className="w-6 h-6" />
            </div>
            <span className="text-xs font-bold text-white">Scan QR</span>
          </Link>

          <Link
            to="/map"
            className="bg-slate-900 border border-slate-800 rounded-2xl p-5 hover:border-emerald-500/40 transition-all flex flex-col items-center justify-center space-y-3 group shadow-lg"
          >
            <div className="w-12 h-12 rounded-2xl bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 flex items-center justify-center group-hover:scale-110 transition-all">
              <Heart className="w-6 h-6" />
            </div>
            <span className="text-xs font-bold text-white">Favorites</span>
          </Link>

          <Link
            to="/history"
            className="bg-slate-900 border border-slate-800 rounded-2xl p-5 hover:border-emerald-500/40 transition-all flex flex-col items-center justify-center space-y-3 group shadow-lg"
          >
            <div className="w-12 h-12 rounded-2xl bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 flex items-center justify-center group-hover:scale-110 transition-all">
              <History className="w-6 h-6" />
            </div>
            <span className="text-xs font-bold text-white">Charging History</span>
          </Link>

          <Link
            to="/wallet"
            className="bg-slate-900 border border-slate-800 rounded-2xl p-5 hover:border-emerald-500/40 transition-all flex flex-col items-center justify-center space-y-3 group shadow-lg"
          >
            <div className="w-12 h-12 rounded-2xl bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 flex items-center justify-center group-hover:scale-110 transition-all">
              <Wallet className="w-6 h-6" />
            </div>
            <span className="text-xs font-bold text-white">Wallet</span>
          </Link>
        </div>
      </div>

      {/* 5. Wallet Balance Card */}
      <div className="bg-slate-900 border border-slate-800 rounded-2xl p-6 shadow-xl flex items-center justify-between flex-wrap gap-4">
        <div className="space-y-1">
          <p className="text-xs font-semibold text-slate-400">Wallet Balance</p>
          <p className="text-3xl font-black text-white tracking-tight">₹256.50</p>
          <div className="pt-2">
            <Link
              to="/wallet"
              className="inline-flex items-center gap-1.5 px-4 py-2 bg-emerald-600 hover:bg-emerald-500 font-bold text-white text-xs rounded-xl transition-all shadow-md shadow-emerald-600/20"
            >
              <Plus className="w-4 h-4" /> Add Money
            </Link>
          </div>
        </div>

        <div className="w-16 h-16 rounded-2xl bg-gradient-to-br from-emerald-500/20 to-emerald-700/10 border border-emerald-500/30 flex items-center justify-center text-emerald-400">
          <Wallet className="w-8 h-8" />
        </div>
      </div>

      {/* 6. Promotional Banner */}
      <div className="rounded-2xl bg-gradient-to-r from-slate-950 via-slate-900 to-emerald-950 border border-emerald-500/20 p-6 flex items-center justify-between flex-wrap gap-4 shadow-xl">
        <div className="space-y-1">
          <h3 className="text-lg font-extrabold text-white">Drive Green, Save More</h3>
          <p className="text-xs text-slate-400">Special offers on every charging session.</p>
        </div>
        <div className="px-4 py-2 bg-emerald-500/10 border border-emerald-500/20 rounded-xl text-emerald-400 text-xs font-bold flex items-center gap-2">
          <Sparkles className="w-4 h-4" /> EcoPass Ready
        </div>
      </div>
    </div>
  );
};
