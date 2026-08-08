import React, { useState } from 'react';
import { useNavigate, useLocation, Link } from 'react-router-dom';
import { Zap, Lock, Mail, AlertCircle, CheckCircle2 } from 'lucide-react';
import { api } from '../services/api';

export const LoginPage: React.FC = () => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);

  const navigate = useNavigate();
  const location = useLocation();
  const successMsg = (location.state as any)?.message;

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setErrorMsg(null);

    if (!email.trim() || !password) {
      setErrorMsg('Please enter your email and password.');
      return;
    }

    setLoading(true);

    try {
      const response = await api.post(
        '/auth/login',
        {
          email: email.trim(),
          password,
        },
        { timeout: 12000 }
      );

      const token = response.data?.accessToken || response.data?.token || response.data?.jwt;
      if (token) {
        localStorage.setItem('customer_token', token);
        navigate('/');
      } else {
        setErrorMsg('Invalid authentication response structure from server.');
      }
    } catch (err: any) {
      const statusCode = err?.response?.status;
      if (statusCode === 401 || statusCode === 403) {
        setErrorMsg('Invalid email or password.');
      } else {
        const msg = err?.response?.data?.message || err?.message;
        setErrorMsg(msg || 'Unable to connect to server. Please try again.');
      }
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-slate-950 flex items-center justify-center p-4">
      <div className="w-full max-w-md bg-slate-900 border border-slate-800 rounded-2xl p-8 shadow-2xl">
        <div className="flex flex-col items-center text-center mb-6">
          <div className="w-12 h-12 rounded-xl bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 flex items-center justify-center mb-4">
            <Zap className="w-7 h-7" />
          </div>
          <h1 className="text-2xl font-bold text-white">EV Driver Sign In</h1>
          <p className="text-sm text-slate-400 mt-1">Access Ultra-Fast EV Charging & Digital Wallet</p>
        </div>

        {successMsg && (
          <div className="mb-6 p-4 rounded-xl bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 text-sm flex items-center gap-3">
            <CheckCircle2 className="w-5 h-5 shrink-0" />
            <span>{successMsg}</span>
          </div>
        )}

        {errorMsg && (
          <div className="mb-6 p-4 rounded-xl bg-rose-500/10 border border-rose-500/20 text-rose-400 text-sm flex items-center gap-3">
            <AlertCircle className="w-5 h-5 shrink-0" />
            <span>{errorMsg}</span>
          </div>
        )}

        <form onSubmit={handleLogin} className="space-y-5">
          <div>
            <label className="block text-xs font-semibold text-slate-300 mb-2">Email Address</label>
            <div className="relative">
              <Mail className="w-5 h-5 absolute left-3 top-1/2 -translate-y-1/2 text-slate-500" />
              <input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="name@example.com"
                required
                disabled={loading}
                className="w-full pl-10 pr-4 py-3 bg-slate-950 border border-slate-800 rounded-xl text-slate-100 text-sm focus:outline-none focus:border-emerald-500 focus:ring-1 focus:ring-emerald-500"
              />
            </div>
          </div>

          <div>
            <label className="block text-xs font-semibold text-slate-300 mb-2">Password</label>
            <div className="relative">
              <Lock className="w-5 h-5 absolute left-3 top-1/2 -translate-y-1/2 text-slate-500" />
              <input
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="••••••••"
                required
                disabled={loading}
                className="w-full pl-10 pr-4 py-3 bg-slate-950 border border-slate-800 rounded-xl text-slate-100 text-sm focus:outline-none focus:border-emerald-500 focus:ring-1 focus:ring-emerald-500"
              />
            </div>
          </div>

          <button
            type="submit"
            disabled={loading}
            className="w-full py-3.5 bg-emerald-500 hover:bg-emerald-600 font-semibold text-white rounded-xl text-sm transition-all shadow-lg shadow-emerald-500/25 flex items-center justify-center disabled:opacity-50"
          >
            {loading ? 'Authenticating...' : 'Sign In'}
          </button>
        </form>

        <div className="mt-6 text-center text-sm text-slate-400">
          Don't have an account?{' '}
          <Link to="/register" className="text-emerald-400 hover:underline font-medium">
            Create New Account
          </Link>
        </div>
      </div>
    </div>
  );
};
