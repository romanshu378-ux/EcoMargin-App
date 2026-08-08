import React, { useState, useEffect, useCallback } from 'react';
import { RefreshCw, WifiOff, AlertTriangle } from 'lucide-react';
import { api } from '../services/api';

interface AppInitializerProps {
  children: React.ReactNode;
}

export const AppInitializer: React.FC<AppInitializerProps> = ({ children }) => {
  const [isInitializing, setIsInitializing] = useState(true);
  const [initError, setInitError] = useState<string | null>(null);
  const [isRetrying, setIsRetrying] = useState(false);
  const [fatalError, setFatalError] = useState<string | null>(null);

  const checkHealth = useCallback(async () => {
    setIsRetrying(true);
    console.log('[EcoMargin] Initializing backend health check...');
    try {
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), 3500);

      await api.get('/health', { signal: controller.signal }).catch((err) => {
        console.warn('[EcoMargin] Health endpoint check non-200 or unhandled response:', err?.message);
      });
      clearTimeout(timeoutId);
      setInitError(null);
      setFatalError(null);
      console.log('[EcoMargin] Initialization complete.');
    } catch (err: any) {
      console.warn('[EcoMargin] Health check error:', err?.message);
      if (err?.name === 'AbortError') {
        setInitError('Backend service response timeout. Running in offline mode.');
      } else {
        setInitError('Unable to connect to EcoMargin API servers.');
      }
    } finally {
      setIsInitializing(false);
      setIsRetrying(false);
    }
  }, []);

  useEffect(() => {
    // 1. Boot health check
    const bootTimer = setTimeout(() => {
      checkHealth();
    }, 100);

    // 2. Strict 5-second hard timeout guard: FORCEFULLY exit loading screen after 5000ms
    const hardTimeoutGuard = setTimeout(() => {
      if (isInitializing) {
        console.warn('[EcoMargin] Hard 5s initialization timeout triggered. Unblocking loading screen.');
        setIsInitializing(false);
        setIsRetrying(false);
        setInitError('Initialization timed out. Operating in fallback offline mode.');
      }
    }, 5000);

    return () => {
      clearTimeout(bootTimer);
      clearTimeout(hardTimeoutGuard);
    };
  }, [checkHealth]);

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

  if (fatalError) {
    return (
      <div className="min-h-screen bg-slate-900 text-slate-100 flex flex-col items-center justify-center p-6 space-y-5">
        <div className="w-16 h-16 rounded-2xl bg-rose-500/10 border border-rose-500/20 flex items-center justify-center text-rose-400">
          <AlertTriangle className="w-8 h-8" />
        </div>
        <div className="text-center space-y-2 max-w-sm">
          <h2 className="text-xl font-bold text-white">Initialization Error</h2>
          <p className="text-xs text-slate-400">{fatalError}</p>
        </div>
        <button
          onClick={() => {
            setFatalError(null);
            checkHealth();
          }}
          className="inline-flex items-center gap-2 px-6 py-3 bg-emerald-600 hover:bg-emerald-500 font-bold text-white text-xs rounded-xl transition-all shadow-lg shadow-emerald-600/25"
        >
          <RefreshCw className="w-4 h-4" /> Retry Connection
        </button>
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

