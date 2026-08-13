import axios from 'axios';

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:8080/api/v1';

export const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

api.interceptors.request.use((config) => {
  const token = localStorage.getItem('admin_token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response && error.response.status === 401) {
      localStorage.removeItem('admin_token');
      if (window.location.pathname !== '/login') {
        window.location.href = '/login';
      }
    }
    return Promise.reject(error);
  }
);

// Admin API Endpoints
export const adminApi = {
  // System Settings
  getSettings: () => api.get('/admin/settings'),
  updateSetting: (key: string, value: string, description?: string) =>
    api.put(`/admin/settings/${key}`, { value, description }),
  updateSettingsBatch: (settings: Record<string, string>) =>
    api.post('/admin/settings/batch', settings),

  // Stations & Chargers
  getStations: () => api.get('/admin/stations'),
  createStation: (data: any) => api.post('/admin/stations', data),
  updateStation: (id: number, data: any) => api.put(`/admin/stations/${id}`, data),
  deleteStation: (id: number) => api.delete(`/admin/stations/${id}`),
  createCharger: (data: any) => api.post('/admin/chargers', data),
  updateChargerStatus: (id: number, status: string) =>
    api.put(`/admin/chargers/${id}/status`, { status }),

  // Users & Access Control
  getUsers: () => api.get('/admin/users'),
  updateUserStatus: (id: number, status: { isLocked?: boolean; isVerified?: boolean }) =>
    api.put(`/admin/users/${id}/status`, status),
  updateUserRole: (id: number, role: string) =>
    api.put(`/admin/users/${id}/role`, { role }),
  creditUserWallet: (id: number, amount: number, reason: string) =>
    api.post(`/admin/users/${id}/wallet/credit`, { amount, reason }),

  // Charging Sessions
  getActiveSessions: () => api.get('/admin/sessions/active'),
  getSessionHistory: () => api.get('/admin/sessions/history'),

  // Transactions & Audit Logs
  getTransactions: () => api.get('/admin/transactions'),
  getAuditLogs: () => api.get('/admin/audit-logs'),
};
