import React, { useState, useEffect } from 'react';
import { AlertCircle, RefreshCw, WifiOff } from 'lucide-react';
import { api } from '../services/api';

interface AppInitializerProps {
  children: React.ReactNode;
}

export const AppInitializer: React.FC<AppInitializerProps> = ({ children }) => {
  const [isInitializing, setIsInitializing] = useState(true);
  const [initError, setInitError] = useState<string | null>(null);
  const [isRetrying, setIsRetrying] = useState(false);

  const checkHealth = async () => {
    setIsRetrying(true);
    try {
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), 4000);

      await api.get('/health', { signal: controller.signal }).catch(() => {
        // Even if 404 or backend unavailable, treat as handled response
      });
      clearTimeout(timeoutId);
      setInitError(null);
    } catch (err: any) {
      if (err?.name === 'AbortError') {
        setInitError('Backend service response timeout. Running in offline mode.');
      } else {
        setInitError('Unable to connect to EcoMargin API servers.');
      }
    } finally {
      setIsInitializing(false);
      setIsRetrying(false);
    }
  };

  useEffect(() => {
    const bootTimer = setTimeout(() => {
      checkHealth();
    }, 300);

    return () => clearTimeout(bootTimer);
  }, []);

  if (isInitializing) {
    return (
      <div className="min-h-screen bg-slate-900 text-slate-100 flex flex-col items-center justify-center p-6 space-y-5">
        <div className="relative flex items-center justify-center">
          <div className="w-16 h-16 border-4 border-emerald-500/20 border-t-emerald-500 rounded-full animate-spin"></div>
          <div className="absolute w-8 h-8 rounded-xl bg-emerald-600/30 flex items-center justify-center">
            <div className="w-3 h-3 bg-emerald-400 rounded-full animate-pulse"></div>
          </div>
        </div>
        <div className="text-center space-y-1.5">
          <h2 className="text-xl font-bold text-white tracking-tight">EcoMargin Web Platform</h2>
          <p className="text-xs text-slate-400">Initializing EV Charging Services...</p>
        </div>
      </div>
    );
  }

  return (
    <>
      {initError && (
        <div className="bg-amber-500/15 border-b border-amber-500/30 px-4 py-2.5 text-xs text-amber-200 flex items-center justify-between gap-3 sticky top-0 z-[60] backdrop-blur-md">
          <div className="flex items-center gap-2">
            <WifiOff className="w-4 h-4 text-amber-400 shrink-0" />
            <span>
              <strong>Server Notice:</strong> {initError} Demo data and cached views are available.
            </span>
          </div>
          <button
            onClick={checkHealth}
            disabled={isRetrying}
            className="inline-flex items-center gap-1.5 px-3 py-1 bg-amber-500/20 hover:bg-amber-500/30 text-amber-300 text-xs font-semibold rounded-lg transition-all shrink-0 disabled:opacity-50"
          >
            <RefreshCw className={`w-3 h-3 ${isRetrying ? 'animate-spin' : ''}`} />
            {isRetrying ? 'Retrying...' : 'Retry Connection'}
          </button>
        </div>
      )}
      {children}
    </>
  );
};
