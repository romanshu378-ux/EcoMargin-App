import React, { Suspense } from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { CustomerLayout } from './components/layout/CustomerLayout';
import { AppInitializer } from './components/AppInitializer';
import { HomePage } from './pages/HomePage';
import { MapPage } from './pages/MapPage';
import { WalletPage } from './pages/WalletPage';
import { HistoryPage } from './pages/HistoryPage';
import { ProfilePage } from './pages/ProfilePage';
import { SupportPage } from './pages/SupportPage';
import { LoginPage } from './pages/LoginPage';

const LoadingFallback: React.FC = () => (
  <div className="min-h-[60vh] flex flex-col items-center justify-center p-8 space-y-4">
    <div className="w-10 h-10 border-4 border-emerald-600/20 border-t-emerald-600 rounded-full animate-spin"></div>
    <p className="text-sm font-semibold text-slate-700">Loading EcoMargin Platform...</p>
  </div>
);

export const App: React.FC = () => {
  return (
    <AppInitializer>
      <BrowserRouter>
        <CustomerLayout>
          <Suspense fallback={<LoadingFallback />}>
            <Routes>
              <Route path="/" element={<HomePage />} />
              <Route path="/dashboard" element={<HomePage />} />
              <Route path="/login" element={<LoginPage />} />
              <Route path="/register" element={<LoginPage />} />
              <Route path="/map" element={<MapPage />} />
              <Route path="/stations" element={<MapPage />} />
              <Route path="/wallet" element={<WalletPage />} />
              <Route path="/history" element={<HistoryPage />} />
              <Route path="/favorites" element={<MapPage />} />
              <Route path="/notifications" element={<HomePage />} />
              <Route path="/profile" element={<ProfilePage />} />
              <Route path="/settings" element={<ProfilePage />} />
              <Route path="/support" element={<SupportPage />} />
              <Route path="*" element={<Navigate to="/" replace />} />
            </Routes>
          </Suspense>
        </CustomerLayout>
      </BrowserRouter>
    </AppInitializer>
  );
};

export default App;
