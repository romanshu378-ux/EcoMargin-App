import React from 'react';
import { BrowserRouter, Routes, Route } from 'react-router-dom';
import AdminLayout from './components/layout/AdminLayout';
import DashboardPage from './pages/DashboardPage';
import StationsPage from './pages/StationsPage';
import ChargersPage from './pages/ChargersPage';
import UsersPage from './pages/UsersPage';
import VendorsPage from './pages/VendorsPage';
import TransactionsPage from './pages/TransactionsPage';
import FirmwareDiagnosticsPage from './pages/FirmwareDiagnosticsPage';

import VendorLayout from './components/layout/VendorLayout';
import VendorDashboard from './pages/vendor/VendorDashboard';
import VendorChargers from './pages/vendor/VendorChargers';
import VendorPricing from './pages/vendor/VendorPricing';
import VendorDiagnostics from './pages/vendor/VendorDiagnostics';
import VendorSupport from './pages/vendor/VendorSupport';

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        {/* Admin Routes */}
        <Route path="/" element={<AdminLayout />}>
          <Route index element={<DashboardPage />} />
          <Route path="dashboard" element={<DashboardPage />} />
          <Route path="stations" element={<StationsPage />} />
          <Route path="chargers" element={<ChargersPage />} />
          <Route path="users" element={<UsersPage />} />
          <Route path="vendors" element={<VendorsPage />} />
          <Route path="orders" element={<TransactionsPage />} />
          <Route path="payments" element={<TransactionsPage />} />
          <Route path="transactions" element={<TransactionsPage />} />
          <Route path="audit-logs" element={<FirmwareDiagnosticsPage />} />
          <Route path="diagnostics" element={<FirmwareDiagnosticsPage />} />
          <Route path="reports" element={<DashboardPage />} />
          <Route path="settings" element={<DashboardPage />} />
          <Route path="*" element={<DashboardPage />} />
        </Route>

        {/* CPO Vendor Routes */}
        <Route path="/vendor" element={<VendorLayout />}>
          <Route index element={<VendorDashboard />} />
          <Route path="chargers" element={<VendorChargers />} />
          <Route path="pricing" element={<VendorPricing />} />
          <Route path="diagnostics" element={<VendorDiagnostics />} />
          <Route path="support" element={<VendorSupport />} />
        </Route>
      </Routes>
    </BrowserRouter>
  );
}
