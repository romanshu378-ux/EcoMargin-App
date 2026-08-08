import React, { useEffect } from 'react';
import { api } from '../services/api';

interface AppInitializerProps {
  children: React.ReactNode;
}

export const AppInitializer: React.FC<AppInitializerProps> = ({ children }) => {
  useEffect(() => {
    // Non-blocking silent background health check with max 3s timeout
    const controller = new AbortController();
    const timeoutId = setTimeout(() => {
      controller.abort();
    }, 3000);

    console.log('[EcoMargin] Background API health check initiated...');
    api.get('/health', { signal: controller.signal })
      .then(() => {
        console.log('[EcoMargin] Backend API connection established.');
      })
      .catch((err) => {
        if (err?.name === 'CanceledError' || err?.name === 'AbortError') {
          console.warn('[EcoMargin] Health check timed out after 3s. App operating with cached/offline capabilities.');
        } else {
          console.warn('[EcoMargin] Health check endpoint unavailable:', err?.message);
        }
      })
      .finally(() => {
        clearTimeout(timeoutId);
      });

    return () => {
      clearTimeout(timeoutId);
      controller.abort();
    };
  }, []); // Run ONCE on mount

  // Render children immediately without blocking initial UI paint or showing warning banners
  return <>{children}</>;
};


