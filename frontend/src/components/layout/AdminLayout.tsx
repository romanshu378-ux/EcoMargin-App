import React, { useState, useEffect } from 'react';
import { Link, useLocation, Outlet } from 'react-router-dom';
import { 
  LayoutDashboard, Map, BatteryCharging, Users, ShieldAlert,
  Wallet, ShieldCheck, Settings, Bell, Sun, Moon, Menu, X, ArrowUpRight
} from 'lucide-react';
import { useThemeStore } from '../../store/themeStore';
import { useNotificationStore } from '../../store/notificationStore';

const navItems = [
  { path: '/', label: 'Dashboard', icon: LayoutDashboard },
  { path: '/stations', label: 'Stations', icon: Map },
  { path: '/chargers', label: 'Chargers', icon: BatteryCharging },
  { path: '/users', label: 'Users', icon: Users },
  { path: '/vendors', label: 'Vendors', icon: ShieldCheck },
  { path: '/transactions', label: 'Transactions', icon: Wallet },
  { path: '/diagnostics', label: 'Operations & Firmware', icon: ShieldAlert },
];

export default function AdminLayout() {
  const location = useLocation();
  const { darkMode, toggleDarkMode } = useThemeStore();
  const { notifications, clearAll } = useNotificationStore();
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [showNotifications, setShowNotifications] = useState(false);

  // Initialize theme class on mount
  useEffect(() => {
    if (darkMode) {
      document.documentElement.classList.add('dark');
    } else {
      document.documentElement.classList.remove('dark');
    }
  }, [darkMode]);

  return (
    <div className={`min-h-screen flex ${darkMode ? 'dark bg-gray-950 text-gray-100' : 'bg-gray-50 text-gray-900'}`}>
      
      {/* Sidebar for Desktop */}
      <aside className={`fixed inset-y-0 left-0 z-20 w-64 bg-white dark:bg-gray-900 border-r border-gray-200 dark:border-gray-800 transition-transform duration-300 transform lg:translate-x-0 ${sidebarOpen ? 'translate-x-0' : '-translate-x-full'}`}>
        <div className="h-16 flex items-center justify-between px-6 border-b border-gray-200 dark:border-gray-800">
          <Link to="/" className="flex items-center gap-2 font-bold text-xl tracking-tight text-emerald-600 dark:text-emerald-500">
            <span>🌱 EcoMargin</span>
            <span className="text-[10px] bg-emerald-100 dark:bg-emerald-950 text-emerald-800 dark:text-emerald-300 px-2 py-0.5 rounded-full font-normal">CPO</span>
          </Link>
          <button onClick={() => setSidebarOpen(false)} className="lg:hidden text-gray-500 hover:text-gray-700 dark:hover:text-gray-300">
            <X size={20} />
          </button>
        </div>

        <nav className="p-4 space-y-1">
          {navItems.map((item) => {
            const Icon = item.icon;
            const isActive = location.pathname === item.path;
            return (
              <Link
                key={item.path}
                to={item.path}
                onClick={() => setSidebarOpen(false)}
                className={`flex items-center gap-3 px-4 py-3 rounded-lg text-sm font-medium transition-all ${
                  isActive 
                    ? 'bg-emerald-600 text-white shadow-lg shadow-emerald-600/20' 
                    : 'text-gray-600 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-800 hover:text-gray-900 dark:hover:text-gray-200'
                }`}
              >
                <Icon size={18} />
                <span>{item.label}</span>
              </Link>
            );
          })}
        </nav>
      </aside>

      {/* Main Content Wrapper */}
      <div className="flex-1 lg:pl-64 flex flex-col min-h-screen">
        
        {/* Topbar */}
        <header className="h-16 bg-white dark:bg-gray-900 border-b border-gray-200 dark:border-gray-800 flex items-center justify-between px-6 sticky top-0 z-10">
          <div className="flex items-center gap-4">
            <button onClick={() => setSidebarOpen(true)} className="lg:hidden text-gray-500 hover:text-gray-700 dark:hover:text-gray-300">
              <Menu size={22} />
            </button>
            <h1 className="font-semibold text-lg hidden sm:block">
              {navItems.find(item => item.path === location.pathname)?.label || 'EcoMargin Hub'}
            </h1>
          </div>

          <div className="flex items-center gap-4">
            {/* Theme Toggle */}
            <button 
              onClick={toggleDarkMode} 
              className="p-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 text-gray-500 dark:text-gray-400 transition-colors"
            >
              {darkMode ? <Sun size={20} /> : <Moon size={20} />}
            </button>

            {/* Notifications */}
            <div className="relative">
              <button 
                onClick={() => setShowNotifications(!showNotifications)}
                className="p-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 text-gray-500 dark:text-gray-400 transition-colors relative"
              >
                <Bell size={20} />
                {notifications.length > 0 && (
                  <span className="absolute top-1.5 right-1.5 w-2.5 h-2.5 bg-red-500 rounded-full border-2 border-white dark:border-gray-900"></span>
                )}
              </button>

              {showNotifications && (
                <div className="absolute right-0 mt-2 w-80 bg-white dark:bg-gray-900 border border-gray-200 dark:border-gray-800 rounded-xl shadow-xl z-30 p-2">
                  <div className="flex items-center justify-between px-4 py-2 border-b border-gray-100 dark:border-gray-800 mb-2">
                    <span className="font-semibold text-sm">System Alerts</span>
                    <button onClick={clearAll} className="text-xs text-gray-500 hover:text-red-500">Clear</button>
                  </div>
                  <div className="max-h-64 overflow-y-auto space-y-1">
                    {notifications.length === 0 ? (
                      <div className="text-center py-6 text-gray-400 text-xs">No active alerts</div>
                    ) : (
                      notifications.map(n => (
                        <div key={n.id} className="p-3 hover:bg-gray-50 dark:hover:bg-gray-800/50 rounded-lg text-xs transition-colors">
                          <div className="flex items-center justify-between font-semibold mb-1">
                            <span className={n.type === 'warning' ? 'text-amber-500' : n.type === 'error' ? 'text-red-500' : 'text-emerald-500'}>
                              {n.title}
                            </span>
                            <span className="text-[10px] text-gray-400 font-normal">
                              {n.timestamp.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                            </span>
                          </div>
                          <p className="text-gray-600 dark:text-gray-400">{n.message}</p>
                        </div>
                      ))
                    )}
                  </div>
                </div>
              )}
            </div>

            {/* Profile Avatar */}
            <div className="flex items-center gap-3 border-l border-gray-200 dark:border-gray-800 pl-4">
              <div className="w-8 h-8 rounded-full bg-emerald-600 flex items-center justify-center font-semibold text-white text-sm">
                A
              </div>
              <div className="hidden md:block text-left">
                <p className="text-xs font-semibold">Admin User</p>
                <p className="text-[10px] text-gray-400">admin@ecomargin.com</p>
              </div>
            </div>
          </div>
        </header>

        {/* Content Outlet */}
        <main className="flex-1 p-6 overflow-x-hidden">
          <Outlet />
        </main>
      </div>

    </div>
  );
}
