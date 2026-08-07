import React from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { VendorLayout } from './components/layout/VendorLayout';
import { LoginPage } from './pages/LoginPage';
import { DashboardPage } from './pages/DashboardPage';
import { ChargersPage } from './pages/ChargersPage';
import { StationsPage } from './pages/StationsPage';
import { TransactionsPage } from './pages/TransactionsPage';
import { EarningsPage } from './pages/EarningsPage';
import { FirmwarePage } from './pages/FirmwarePage';
import { SupportPage } from './pages/SupportPage';
import { ProfilePage } from './pages/ProfilePage';

const ProtectedRoute = ({ children }: { children: React.ReactNode }) => {
  const token = localStorage.getItem('vendor_token');
  if (!token) {
    return <Navigate to="/login" replace />;
  }
  return <VendorLayout>{children}</VendorLayout>;
};

export const App: React.FC = () => {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/login" element={<LoginPage />} />
        <Route path="/" element={<ProtectedRoute><DashboardPage /></ProtectedRoute>} />
        <Route path="/chargers" element={<ProtectedRoute><ChargersPage /></ProtectedRoute>} />
        <Route path="/stations" element={<ProtectedRoute><StationsPage /></ProtectedRoute>} />
        <Route path="/transactions" element={<ProtectedRoute><TransactionsPage /></ProtectedRoute>} />
        <Route path="/earnings" element={<ProtectedRoute><EarningsPage /></ProtectedRoute>} />
        <Route path="/firmware" element={<ProtectedRoute><FirmwarePage /></ProtectedRoute>} />
        <Route path="/support" element={<ProtectedRoute><SupportPage /></ProtectedRoute>} />
        <Route path="/profile" element={<ProtectedRoute><ProfilePage /></ProtectedRoute>} />
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </BrowserRouter>
  );
};

export default App;
