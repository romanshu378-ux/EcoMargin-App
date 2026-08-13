import React, { useEffect, useState } from 'react';
import { Settings, Save, Shield, Sliders, AlertTriangle, Phone, HelpCircle, LayoutGrid, CheckCircle } from 'lucide-react';
import { adminApi } from '../services/api';

export const SettingsPage: React.FC = () => {
  const [loading, setLoading] = useState(false);
  const [savedSuccess, setSavedSuccess] = useState(false);
  const [errorMsg, setErrorMsg] = useState('');

  // Tariff & Wallet settings
  const [baseRate, setBaseRate] = useState('15.00');
  const [minBalance, setMinBalance] = useState('50.00');
  const [idleFee, setIdleFee] = useState('2.00');

  // Home sections visibility
  const [homeSections, setHomeSections] = useState({
    hero_slider: true,
    quick_actions: true,
    wallet_card: true,
    nearby_stations: true,
    promo_banner: true,
    search_section: true,
  });

  // Support & Helpline info
  const [supportPhone, setSupportPhone] = useState('1800-123-4567');
  const [supportEmail, setSupportEmail] = useState('support@ecomargin.com');
  const [supportHours, setSupportHours] = useState('24/7 Helpline');

  // Maintenance & Session rules
  const [maintenanceEnabled, setMaintenanceEnabled] = useState(false);
  const [maintenanceMsg, setMaintenanceMsg] = useState(
    'EcoMargin is currently undergoing scheduled maintenance. Please check back shortly.'
  );

  useEffect(() => {
    fetchSettings();
  }, []);

  const fetchSettings = async () => {
    try {
      setLoading(true);
      const res = await adminApi.getSettings();
      const data = res.data || {};

      if (data.default_charging_rate_per_kwh) setBaseRate(data.default_charging_rate_per_kwh);
      if (data.min_wallet_balance_to_start) setMinBalance(data.min_wallet_balance_to_start);
      
      if (data.home_sections) {
        try {
          const parsed = JSON.parse(data.home_sections);
          setHomeSections((prev) => ({ ...prev, ...parsed }));
        } catch (_) {}
      }

      if (data.support_info) {
        try {
          const parsed = JSON.parse(data.support_info);
          if (parsed.phone) setSupportPhone(parsed.phone);
          if (parsed.email) setSupportEmail(parsed.email);
          if (parsed.hours) setSupportHours(parsed.hours);
        } catch (_) {}
      }

      if (data.app_maintenance) {
        try {
          const parsed = JSON.parse(data.app_maintenance);
          setMaintenanceEnabled(!!parsed.enabled);
          if (parsed.message) setMaintenanceMsg(parsed.message);
        } catch (_) {}
      }
    } catch (err: any) {
      console.error('Failed to load settings:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleSaveAll = async () => {
    try {
      setLoading(true);
      setErrorMsg('');
      setSavedSuccess(false);

      const batchData = {
        default_charging_rate_per_kwh: baseRate,
        min_wallet_balance_to_start: minBalance,
        home_sections: JSON.stringify(homeSections),
        support_info: JSON.stringify({
          phone: supportPhone,
          email: supportEmail,
          hours: supportHours,
        }),
        app_maintenance: JSON.stringify({
          enabled: maintenanceEnabled,
          message: maintenanceMsg,
        }),
      };

      await adminApi.updateSettingsBatch(batchData);
      setSavedSuccess(true);
      setTimeout(() => setSavedSuccess(false), 4000);
    } catch (err: any) {
      setErrorMsg(err?.response?.data?.message || 'Failed to save settings');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="space-y-6 max-w-5xl">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-xl font-bold text-white">Central Control & System Settings</h1>
          <p className="text-xs text-slate-400">Manage Customer App configuration, home sections, wallet thresholds, and maintenance mode</p>
        </div>
        <button
          onClick={handleSaveAll}
          disabled={loading}
          className="flex items-center gap-2 px-5 py-2.5 bg-emerald-500 hover:bg-emerald-600 font-semibold text-white text-xs rounded-xl transition-all shadow-lg shadow-emerald-500/20 disabled:opacity-50"
        >
          <Save className="w-4 h-4" /> {loading ? 'Saving...' : 'Save All Settings'}
        </button>
      </div>

      {savedSuccess && (
        <div className="p-4 bg-emerald-500/10 border border-emerald-500/30 rounded-xl text-emerald-400 text-xs flex items-center gap-2">
          <CheckCircle className="w-4 h-4" /> Settings updated successfully! Changes will take effect immediately on Customer App.
        </div>
      )}

      {errorMsg && (
        <div className="p-4 bg-red-500/10 border border-red-500/30 rounded-xl text-red-400 text-xs flex items-center gap-2">
          <AlertTriangle className="w-4 h-4" /> {errorMsg}
        </div>
      )}

      {/* 1. Customer App Home Screen Sections */}
      <div className="bg-slate-900 border border-slate-800 rounded-2xl p-6 space-y-4">
        <h3 className="text-sm font-bold text-white border-b border-slate-800 pb-3 flex items-center gap-2">
          <LayoutGrid className="w-4 h-4 text-emerald-400" /> Customer App Home Screen Sections
        </h3>
        <p className="text-xs text-slate-400">Enable or disable individual components displayed on the Customer App main screen</p>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 pt-2">
          {Object.entries(homeSections).map(([key, isEnabled]) => (
            <div key={key} className="flex items-center justify-between p-3.5 bg-slate-950/60 rounded-xl border border-slate-800/80">
              <span className="text-xs font-semibold capitalize text-slate-200">{key.replace('_', ' ')}</span>
              <button
                type="button"
                onClick={() => setHomeSections((prev) => ({ ...prev, [key]: !isEnabled }))}
                className={`w-11 h-6 rounded-full transition-colors relative ${
                  isEnabled ? 'bg-emerald-500' : 'bg-slate-700'
                }`}
              >
                <div
                  className={`w-4 h-4 bg-white rounded-full transition-transform absolute top-1 ${
                    isEnabled ? 'left-6' : 'left-1'
                  }`}
                />
              </button>
            </div>
          ))}
        </div>
      </div>

      {/* 2. Tariff & Wallet Rules */}
      <div className="bg-slate-900 border border-slate-800 rounded-2xl p-6 space-y-6">
        <h3 className="text-sm font-bold text-white border-b border-slate-800 pb-3 flex items-center gap-2">
          <Sliders className="w-4 h-4 text-emerald-400" /> Tariff & Wallet Thresholds
        </h3>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          <div>
            <label className="block text-xs font-semibold text-slate-300 mb-2">Default Charging Tariff (₹ / kWh)</label>
            <input
              type="text"
              value={baseRate}
              onChange={(e) => setBaseRate(e.target.value)}
              className="w-full px-4 py-2.5 bg-slate-950 border border-slate-800 rounded-xl text-xs text-slate-100 focus:outline-none focus:border-emerald-500"
            />
          </div>

          <div>
            <label className="block text-xs font-semibold text-slate-300 mb-2">Minimum Wallet Balance to Charge (₹)</label>
            <input
              type="text"
              value={minBalance}
              onChange={(e) => setMinBalance(e.target.value)}
              className="w-full px-4 py-2.5 bg-slate-950 border border-slate-800 rounded-xl text-xs text-slate-100 focus:outline-none focus:border-emerald-500"
            />
          </div>

          <div>
            <label className="block text-xs font-semibold text-slate-300 mb-2">Post-charge Idle Fee (₹ / min)</label>
            <input
              type="text"
              value={idleFee}
              onChange={(e) => setIdleFee(e.target.value)}
              className="w-full px-4 py-2.5 bg-slate-950 border border-slate-800 rounded-xl text-xs text-slate-100 focus:outline-none focus:border-emerald-500"
            />
          </div>
        </div>
      </div>

      {/* 3. Support & Helpline Information */}
      <div className="bg-slate-900 border border-slate-800 rounded-2xl p-6 space-y-4">
        <h3 className="text-sm font-bold text-white border-b border-slate-800 pb-3 flex items-center gap-2">
          <Phone className="w-4 h-4 text-emerald-400" /> Support & Helpline Information
        </h3>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          <div>
            <label className="block text-xs font-semibold text-slate-300 mb-2">Helpline Phone Number</label>
            <input
              type="text"
              value={supportPhone}
              onChange={(e) => setSupportPhone(e.target.value)}
              className="w-full px-4 py-2.5 bg-slate-950 border border-slate-800 rounded-xl text-xs text-slate-100 focus:outline-none focus:border-emerald-500"
            />
          </div>

          <div>
            <label className="block text-xs font-semibold text-slate-300 mb-2">Support Email</label>
            <input
              type="text"
              value={supportEmail}
              onChange={(e) => setSupportEmail(e.target.value)}
              className="w-full px-4 py-2.5 bg-slate-950 border border-slate-800 rounded-xl text-xs text-slate-100 focus:outline-none focus:border-emerald-500"
            />
          </div>

          <div>
            <label className="block text-xs font-semibold text-slate-300 mb-2">Operating Hours</label>
            <input
              type="text"
              value={supportHours}
              onChange={(e) => setSupportHours(e.target.value)}
              className="w-full px-4 py-2.5 bg-slate-950 border border-slate-800 rounded-xl text-xs text-slate-100 focus:outline-none focus:border-emerald-500"
            />
          </div>
        </div>
      </div>

      {/* 4. App Maintenance Control */}
      <div className="bg-slate-900 border border-slate-800 rounded-2xl p-6 space-y-4">
        <div className="flex items-center justify-between border-b border-slate-800 pb-3">
          <h3 className="text-sm font-bold text-white flex items-center gap-2">
            <AlertTriangle className="w-4 h-4 text-amber-400" /> Maintenance Mode & App Status
          </h3>
          <div className="flex items-center gap-2">
            <span className="text-xs text-slate-400 font-semibold">Enable Maintenance Mode:</span>
            <button
              type="button"
              onClick={() => setMaintenanceEnabled(!maintenanceEnabled)}
              className={`w-11 h-6 rounded-full transition-colors relative ${
                maintenanceEnabled ? 'bg-amber-500' : 'bg-slate-700'
              }`}
            >
              <div
                className={`w-4 h-4 bg-white rounded-full transition-transform absolute top-1 ${
                  maintenanceEnabled ? 'left-6' : 'left-1'
                }`}
              />
            </button>
          </div>
        </div>

        <div>
          <label className="block text-xs font-semibold text-slate-300 mb-2">Maintenance Screen Message</label>
          <textarea
            rows={2}
            value={maintenanceMsg}
            onChange={(e) => setMaintenanceMsg(e.target.value)}
            className="w-full px-4 py-2.5 bg-slate-950 border border-slate-800 rounded-xl text-xs text-slate-100 focus:outline-none focus:border-emerald-500 resize-none"
          />
        </div>
      </div>
    </div>
  );
};
