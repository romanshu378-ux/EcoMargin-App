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
    <div className="min-h-screen bg-slate-50 text-slate-900 flex flex-col">
      {/* Top Navbar */}
      <header className="h-20 bg-white/90 backdrop-blur border-b border-slate-200 shadow-sm px-8 flex items-center justify-between sticky top-0 z-50">
        <Link to="/" className="flex items-center gap-3">
          <img src="/logo-dark.png" alt="EcoMargin Logo" className="h-10 w-auto object-contain" />
          <div className="hidden sm:block">
            <h1 className="font-bold text-xl text-slate-900 tracking-tight leading-none">EcoMargin</h1>
            <p className="text-[11px] text-emerald-600 font-semibold tracking-wide uppercase mt-0.5">EV Driver Portal</p>
          </div>
        </Link>

        {/* Navigation Links */}
        <nav className="hidden md:flex items-center gap-1 bg-slate-100 p-1.5 rounded-2xl border border-slate-200">
          {navItems.map((item) => {
            const Icon = item.icon;
            const isActive = location.pathname === item.path;
            return (
              <Link
                key={item.path}
                to={item.path}
                className={`flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-semibold transition-all ${
                  isActive
                    ? 'bg-emerald-600 text-white shadow-md shadow-emerald-600/20'
                    : 'text-slate-600 hover:text-slate-900 hover:bg-white'
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
                <p className="text-xs font-semibold text-slate-900">Alex Rivers</p>
                <p className="text-[10px] text-emerald-600 font-mono font-bold">₹256.50 Balance</p>
              </div>
              <button
                onClick={handleLogout}
                className="p-2.5 text-rose-500 hover:bg-rose-50 rounded-xl transition-all border border-rose-200"
                title="Sign Out"
              >
                <LogOut className="w-4 h-4" />
              </button>
            </div>
          ) : (
            <Link
              to="/login"
              className="px-5 py-2.5 bg-emerald-600 hover:bg-emerald-700 font-semibold text-white text-xs rounded-xl transition-all shadow-md shadow-emerald-600/20"
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
      <footer className="bg-white border-t border-slate-200 py-8 px-8 text-center text-xs text-slate-500">
        <p>© 2026 EcoMargin Enterprise EV Network. All rights reserved.</p>
      </footer>
    </div>
  );
};
