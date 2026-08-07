import React from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { CustomerLayout } from './components/layout/CustomerLayout';
import { HomePage } from './pages/HomePage';
import { MapPage } from './pages/MapPage';
import { WalletPage } from './pages/WalletPage';
import { HistoryPage } from './pages/HistoryPage';
import { ProfilePage } from './pages/ProfilePage';
import { SupportPage } from './pages/SupportPage';
import { LoginPage } from './pages/LoginPage';

export const App: React.FC = () => {
  return (
    <BrowserRouter>
      <CustomerLayout>
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
      </CustomerLayout>
    </BrowserRouter>
  );
};

export default App;
