import axios from 'axios';

const API_BASE_URL = import.meta.env.VITE_API_URL || import.meta.env.VITE_API_BASE_URL || 'https://ecomargin-app.onrender.com/api/v1';

export const api = axios.create({
  baseURL: API_BASE_URL,
  timeout: 15000, // 15 seconds timeout to accommodate Render backend cold starts
  headers: {
    'Content-Type': 'application/json',
  },
});

api.interceptors.request.use((config) => {
  const token = localStorage.getItem('customer_token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

api.interceptors.response.use(
  (response) => response,
  (error) => {
    console.warn('[EcoMargin API Error]:', error?.message || 'Network/Server Error');

    if (error.response && error.response.status === 401 && !window.location.pathname.startsWith('/login')) {
      localStorage.removeItem('customer_token');
      window.location.href = '/login';
    }
    return Promise.reject(error);
  }
);


