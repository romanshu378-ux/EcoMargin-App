import React from 'react';
import { Link, useLocation, useNavigate } from 'react-router-dom';
import { 
  Zap, 
  MapPin, 
  Wallet, 
  History, 
  Calendar, 
  User, 
  LifeBuoy, 
  LogOut,
  Home
} from 'lucide-react';

interface CustomerLayoutProps {
  children: React.ReactNode;
}

export const CustomerLayout: React.FC<CustomerLayoutProps> = ({ children }) => {
  const location = useLocation();
  const navigate = useNavigate();
  const token = localStorage.getItem('customer_token');

  const handleLogout = () => {
    localStorage.removeItem('customer_token');
    navigate('/login');
  };

  const navItems = [
    { label: 'Home', path: '/', icon: Home },
    { label: 'Find Stations', path: '/map', icon: MapPin },
    { label: 'Wallet', path: '/wallet', icon: Wallet },
    { label: 'History', path: '/history', icon: History },
    { label: 'Reservations', path: '/booking', icon: Calendar },
    { label: 'Support', path: '/support', icon: LifeBuoy },
    { label: 'Profile', path: '/profile', icon: User },
  ];

  return (
    <div className="min-h-screen bg-slate-950 text-slate-100 flex flex-col">
      {/* Top Navbar */}
      <header className="h-20 bg-slate-900/90 backdrop-blur border-b border-slate-800 px-8 flex items-center justify-between sticky top-0 z-50">
        <Link to="/" className="flex items-center gap-3">
          <div className="bg-emerald-500/10 p-2.5 rounded-xl text-emerald-400 border border-emerald-500/20">
            <Zap className="w-6 h-6" />
          </div>
          <div>
            <h1 className="font-bold text-xl text-white tracking-tight">EcoMargin</h1>
            <p className="text-[11px] text-emerald-400 font-semibold tracking-wide uppercase">EV Driver Portal</p>
          </div>
        </Link>

        {/* Navigation Links */}
        <nav className="hidden md:flex items-center gap-1 bg-slate-950/60 p-1.5 rounded-2xl border border-slate-800/80">
          {navItems.map((item) => {
            const Icon = item.icon;
            const isActive = location.pathname === item.path;
            return (
              <Link
                key={item.path}
                to={item.path}
                className={`flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-semibold transition-all ${
                  isActive
                    ? 'bg-emerald-500 text-white shadow-lg shadow-emerald-500/20'
                    : 'text-slate-400 hover:text-white hover:bg-slate-800/60'
                }`}
              >
                <Icon className="w-4 h-4" />
                {item.label}
              </Link>
            );
          })}
        </nav>

        {/* User Auth State */}
        <div className="flex items-center gap-4">
          {token ? (
            <div className="flex items-center gap-3">
              <div className="hidden sm:block text-right">
                <p className="text-xs font-semibold text-white">Alex Rivers</p>
                <p className="text-[10px] text-emerald-400 font-mono font-bold">$45.00 Balance</p>
              </div>
              <button
                onClick={handleLogout}
                className="p-2.5 text-rose-400 hover:bg-rose-500/10 rounded-xl transition-all border border-rose-500/20"
                title="Sign Out"
              >
                <LogOut className="w-4 h-4" />
              </button>
            </div>
          ) : (
            <Link
              to="/login"
              className="px-5 py-2.5 bg-emerald-500 hover:bg-emerald-600 font-semibold text-white text-xs rounded-xl transition-all shadow-lg shadow-emerald-500/20"
            >
              Sign In
            </Link>
          )}
        </div>
      </header>

      {/* Main Content */}
      <main className="flex-1">
        {children}
      </main>

      {/* Footer */}
      <footer className="bg-slate-900 border-t border-slate-800 py-8 px-8 text-center text-xs text-slate-500">
        <p>© 2026 EcoMargin Enterprise EV Network. All rights reserved.</p>
      </footer>
    </div>
  );
};
