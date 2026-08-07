import React from 'react';
import { Link } from 'react-router-dom';
import { Zap, MapPin, ShieldCheck, Wallet, ArrowRight, BatteryCharging } from 'lucide-react';

export const HomePage: React.FC = () => {
  return (
    <div className="space-y-16 py-12 px-8 max-w-7xl mx-auto">
      {/* Hero Section */}
      <div className="relative rounded-3xl bg-gradient-to-r from-emerald-950 via-slate-900 to-slate-950 border border-emerald-500/20 p-12 overflow-hidden shadow-2xl">
        <div className="relative z-10 max-w-2xl space-y-6">
          <div className="inline-flex items-center gap-2 px-3 py-1.5 rounded-full bg-emerald-500/10 text-emerald-400 border border-emerald-500/20 text-xs font-semibold">
            <BatteryCharging className="w-4 h-4 animate-pulse" /> Next-Gen Ultra-Fast EV Network
          </div>
          <h1 className="text-4xl md:text-5xl font-extrabold text-white leading-tight">
            Charge Your EV Anywhere with Zero Downtime
          </h1>
          <p className="text-slate-300 text-base">
            Discover thousands of high-speed CCS2 and Type 2 charging stations, reserve connectors in advance, and pay seamlessly with your digital wallet.
          </p>
          <div className="flex flex-wrap items-center gap-4 pt-2">
            <Link
              to="/map"
              className="flex items-center gap-2 px-6 py-3.5 bg-emerald-500 hover:bg-emerald-600 font-semibold text-white text-sm rounded-xl transition-all shadow-lg shadow-emerald-500/25"
            >
              <MapPin className="w-4 h-4" /> Find Nearby Stations
            </Link>
            <Link
              to="/wallet"
              className="flex items-center gap-2 px-6 py-3.5 bg-slate-900 hover:bg-slate-800 font-semibold text-slate-200 text-sm rounded-xl border border-slate-800 transition-all"
            >
              <Wallet className="w-4 h-4" /> Manage Wallet
            </Link>
          </div>
        </div>
      </div>

      {/* Feature Highlights */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
        <div className="bg-slate-900 border border-slate-800 rounded-2xl p-6 space-y-3 hover:border-slate-700 transition-all">
          <div className="w-12 h-12 rounded-xl bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 flex items-center justify-center">
            <MapPin className="w-6 h-6" />
          </div>
          <h3 className="text-lg font-bold text-white">Live Station Finder</h3>
          <p className="text-xs text-slate-400 leading-relaxed">
            Real-time availability status for every connector. Filter by power output (up to 350kW) and plug type.
          </p>
        </div>

        <div className="bg-slate-900 border border-slate-800 rounded-2xl p-6 space-y-3 hover:border-slate-700 transition-all">
          <div className="w-12 h-12 rounded-xl bg-blue-500/10 border border-blue-500/20 text-blue-400 flex items-center justify-center">
            <Zap className="w-6 h-6" />
          </div>
          <h3 className="text-lg font-bold text-white">Instant QR Start</h3>
          <p className="text-xs text-slate-400 leading-relaxed">
            Simply scan the QR code on any charger pillar to initiate charging immediately from your browser or mobile app.
          </p>
        </div>

        <div className="bg-slate-900 border border-slate-800 rounded-2xl p-6 space-y-3 hover:border-slate-700 transition-all">
          <div className="w-12 h-12 rounded-xl bg-purple-500/10 border border-purple-500/20 text-purple-400 flex items-center justify-center">
            <ShieldCheck className="w-6 h-6" />
          </div>
          <h3 className="text-lg font-bold text-white">Automated Payments</h3>
          <p className="text-xs text-slate-400 leading-relaxed">
            Seamless auto-debit from your EcoMargin Wallet or linked credit card with transparent per-kWh billing.
          </p>
        </div>
      </div>
    </div>
  );
};
