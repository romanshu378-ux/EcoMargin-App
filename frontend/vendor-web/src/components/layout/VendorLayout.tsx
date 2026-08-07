import React from 'react';
import { Link, useLocation, useNavigate } from 'react-router-dom';
import { 
  LayoutDashboard, 
  Zap, 
  MapPin, 
  Receipt, 
  TrendingUp, 
  Cpu, 
  LifeBuoy, 
  User, 
  LogOut,
  Building2
} from 'lucide-react';

interface VendorLayoutProps {
  children: React.ReactNode;
}

export const VendorLayout: React.FC<VendorLayoutProps> = ({ children }) => {
  const location = useLocation();
  const navigate = useNavigate();

  const handleLogout = () => {
    localStorage.removeItem('vendor_token');
    navigate('/login');
  };

  const navItems = [
    { label: 'Dashboard', path: '/', icon: LayoutDashboard },
    { label: 'Chargers', path: '/chargers', icon: Zap },
    { label: 'Stations', path: '/stations', icon: MapPin },
    { label: 'Transactions', path: '/transactions', icon: Receipt },
    { label: 'Earnings', path: '/earnings', icon: TrendingUp },
    { label: 'Firmware OTA', path: '/firmware', icon: Cpu },
    { label: 'Support', path: '/support', icon: LifeBuoy },
    { label: 'Profile', path: '/profile', icon: User },
  ];

  return (
    <div className="flex h-screen bg-slate-950 text-slate-100 overflow-hidden">
      {/* Sidebar */}
      <aside className="w-64 bg-slate-900 border-r border-slate-800 flex flex-col justify-between">
        <div>
          {/* Logo */}
          <div className="p-6 border-b border-slate-800 flex flex-col items-start gap-2">
            <img src="/logo-dark.png" alt="EcoMargin Logo" className="h-12 w-auto object-contain" />
            <p className="text-xs text-amber-400 font-medium tracking-wider uppercase ml-1">Vendor Control Portal</p>
          </div>

          {/* Navigation */}
          <nav className="p-4 space-y-1">
            {navItems.map((item) => {
              const Icon = item.icon;
              const isActive = location.pathname === item.path;
              return (
                <Link
                  key={item.path}
                  to={item.path}
                  className={`flex items-center gap-3 px-4 py-3 rounded-xl text-sm font-medium transition-all ${
                    isActive
                      ? 'bg-amber-500 text-white shadow-lg shadow-amber-500/25'
                      : 'text-slate-400 hover:text-white hover:bg-slate-800/60'
                  }`}
                >
                  <Icon className="w-5 h-5" />
                  {item.label}
                </Link>
              );
            })}
          </nav>
        </div>

        {/* User Info & Logout */}
        <div className="p-4 border-t border-slate-800">
          <div className="flex items-center justify-between p-3 rounded-xl bg-slate-800/40 border border-slate-700/40 mb-2">
            <div>
              <p className="text-sm font-semibold text-white">ChargeTech Global</p>
              <p className="text-xs text-slate-400">vendor@chargetech.com</p>
            </div>
            <span className="w-2.5 h-2.5 rounded-full bg-emerald-400 animate-pulse"></span>
          </div>
          <button
            onClick={handleLogout}
            className="w-full flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl text-sm font-medium text-rose-400 hover:bg-rose-500/10 hover:text-rose-300 transition-all border border-rose-500/20"
          >
            <LogOut className="w-4 h-4" />
            Sign Out
          </button>
        </div>
      </aside>

      {/* Main Content Area */}
      <div className="flex-1 flex flex-col overflow-hidden">
        {/* Header */}
        <header className="h-16 bg-slate-900/80 backdrop-blur border-b border-slate-800 px-8 flex items-center justify-between">
          <h2 className="text-lg font-semibold text-white">
            {navItems.find(i => i.path === location.pathname)?.label || 'Overview'}
          </h2>
          <div className="flex items-center gap-4">
            <span className="px-3 py-1 text-xs font-semibold rounded-full bg-amber-500/10 text-amber-400 border border-amber-500/20">
              Verified CPO Vendor
            </span>
          </div>
        </header>

        {/* Dynamic Page View */}
        <main className="flex-1 overflow-y-auto p-8 bg-slate-950">
          {children}
        </main>
      </div>
    </div>
  );
};
