import React, { Suspense, lazy } from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { CustomerLayout } from './components/layout/CustomerLayout';
import { AppInitializer } from './components/AppInitializer';

// Dynamic Code Splitting for Routes
const HomePage = lazy(() => import('./pages/HomePage').then(m => ({ default: m.HomePage })));
const MapPage = lazy(() => import('./pages/MapPage').then(m => ({ default: m.MapPage })));
const WalletPage = lazy(() => import('./pages/WalletPage').then(m => ({ default: m.WalletPage })));
const HistoryPage = lazy(() => import('./pages/HistoryPage').then(m => ({ default: m.HistoryPage })));
const ProfilePage = lazy(() => import('./pages/ProfilePage').then(m => ({ default: m.ProfilePage })));
const SupportPage = lazy(() => import('./pages/SupportPage').then(m => ({ default: m.SupportPage })));
const LoginPage = lazy(() => import('./pages/LoginPage').then(m => ({ default: m.LoginPage })));
const RegisterPage = lazy(() => import('./pages/RegisterPage').then(m => ({ default: m.RegisterPage })));


const PageSkeleton: React.FC = () => (
  <div className="max-w-6xl mx-auto px-4 sm:px-6 py-6 space-y-6 animate-pulse">
    <div className="h-44 bg-slate-200/80 rounded-3xl w-full"></div>
    <div className="h-28 bg-slate-200/70 rounded-3xl w-full"></div>
    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
      <div className="h-36 bg-slate-200/60 rounded-2xl"></div>
      <div className="h-36 bg-slate-200/60 rounded-2xl"></div>
    </div>
  </div>
);

export const App: React.FC = () => {
  return (
    <AppInitializer>
      <BrowserRouter>
        <CustomerLayout>
          <Suspense fallback={<PageSkeleton />}>
            <Routes>
              <Route path="/" element={<HomePage />} />
              <Route path="/dashboard" element={<HomePage />} />
              <Route path="/login" element={<LoginPage />} />
              <Route path="/register" element={<RegisterPage />} />

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

