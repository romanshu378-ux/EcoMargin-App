import React, { Component, ErrorInfo, ReactNode } from 'react';
import { RefreshCw, AlertTriangle, Trash2 } from 'lucide-react';

interface Props {
  children: ReactNode;
}

interface State {
  hasError: boolean;
  error?: Error;
  isChunkError: boolean;
}

export class ErrorBoundary extends Component<Props, State> {
  public state: State = {
    hasError: false,
    isChunkError: false,
  };

  public static getDerivedStateFromError(error: Error): State {
    const isChunkError = 
      error?.message?.includes('Loading chunk') ||
      error?.message?.includes('dynamically imported module') ||
      error?.message?.includes('SyntaxError') ||
      error?.name === 'ChunkLoadError';
      
    return { hasError: true, error, isChunkError };
  }

  public componentDidCatch(error: Error, errorInfo: ErrorInfo) {
    console.error('EcoMargin Uncaught Error:', error, errorInfo);

    if (this.state.isChunkError && !sessionStorage.getItem('ecomargin_eb_reloaded')) {
      sessionStorage.setItem('ecomargin_eb_reloaded', 'true');
      this.clearCacheAndReload();
    }
  }

  private clearCacheAndReload = () => {
    if ('serviceWorker' in navigator) {
      navigator.serviceWorker.getRegistrations().then((registrations) => {
        registrations.forEach((reg) => reg.unregister());
      });
    }
    if ('caches' in window) {
      caches.keys().then((keys) => {
        keys.forEach((key) => caches.delete(key));
      });
    }
    window.location.href = '/';
  };

  public render() {
    if (this.state.hasError) {
      return (
        <div className="min-h-screen bg-slate-900 text-slate-100 flex items-center justify-center p-6">
          <div className="max-w-md w-full bg-slate-800 border border-slate-700 rounded-3xl p-8 text-center space-y-6 shadow-2xl">
            <div className="w-16 h-16 bg-rose-500/10 border border-rose-500/20 rounded-2xl flex items-center justify-center mx-auto text-rose-400">
              <AlertTriangle className="w-8 h-8" />
            </div>

            <div className="space-y-2">
              <h2 className="text-2xl font-bold text-white tracking-tight">EcoMargin Portal</h2>
              <p className="text-sm font-medium text-slate-300">
                {this.state.isChunkError
                  ? 'A new deployment update is available.'
                  : 'An unexpected application runtime issue occurred.'}
              </p>
              <p className="text-xs text-slate-400 font-mono bg-slate-900/60 p-2.5 rounded-xl border border-slate-700/50 break-words">
                {this.state.error?.message || 'Application initialization error'}
              </p>
            </div>

            <div className="space-y-2">
              <button
                onClick={() => {
                  this.setState({ hasError: false });
                  window.location.reload();
                }}
                className="w-full inline-flex items-center justify-center gap-2 px-6 py-3.5 bg-emerald-600 hover:bg-emerald-500 font-bold text-white text-sm rounded-xl transition-all shadow-lg shadow-emerald-600/30"
              >
                <RefreshCw className="w-4 h-4" /> Reload Portal
              </button>
              
              <button
                onClick={this.clearCacheAndReload}
                className="w-full inline-flex items-center justify-center gap-2 px-4 py-2.5 bg-slate-700/60 hover:bg-slate-700 font-semibold text-slate-300 hover:text-white text-xs rounded-xl transition-all border border-slate-600/50"
              >
                <Trash2 className="w-3.5 h-3.5" /> Clear Cache & Reset
              </button>
            </div>
          </div>
        </div>
      );
    }

    return this.props.children;
  }
}
