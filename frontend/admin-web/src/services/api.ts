import axios from 'axios';

export const getApiBaseUrl = () => {
  const envUrl = import.meta.env.VITE_API_BASE_URL;
  if (envUrl && envUrl.trim() !== '') {
    return envUrl.endsWith('/') ? envUrl.slice(0, -1) : envUrl;
  }
  if (typeof window !== 'undefined' && (window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1')) {
    return 'http://localhost:8080/api/v1';
  }
  return '/api/v1';
};

export const API_BASE_URL = getApiBaseUrl();

export const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

api.interceptors.request.use((config) => {
  const token = localStorage.getItem('admin_token') || localStorage.getItem('token');
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
      localStorage.removeItem('token');
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
  getDetailedStations: (search?: string, status?: string) => {
    const params = new URLSearchParams();
    if (search && search.trim()) params.append('search', search.trim());
    if (status && status !== 'ALL') params.append('status', status);
    return api.get(`/admin/stations/detailed?${params.toString()}`);
  },
  getStationById: (id: number) => api.get(`/admin/stations/${id}`),
  createStation: (data: any) => api.post('/admin/stations', data),
  updateStation: (id: number, data: any) => api.put(`/admin/stations/${id}`, data),
  changeStationStatus: (id: number, status: string) => api.put(`/admin/stations/${id}/status`, { status }),
  disableStation: (id: number) => api.put(`/admin/stations/${id}/disable`),
  enableStation: (id: number) => api.put(`/admin/stations/${id}/enable`),
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
