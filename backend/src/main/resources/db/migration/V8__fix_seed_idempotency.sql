-- PostgreSQL Migration: V8__fix_seed_idempotency
-- Re-seeds all platform roles, permissions, users, stations, chargers, connectors, settings,
-- and schema extensions idempotently using ON CONFLICT DO NOTHING and WHERE NOT EXISTS.

--------------------------------------------------------------------------------
-- 1. Schema Extensions & Missing Column Safety
--------------------------------------------------------------------------------
ALTER TABLE users ADD COLUMN IF NOT EXISTS is_account_non_locked BOOLEAN DEFAULT TRUE NOT NULL;
ALTER TABLE users ADD COLUMN IF NOT EXISTS date_of_birth DATE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS gender VARCHAR(50);
ALTER TABLE users ADD COLUMN IF NOT EXISTS address TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS city VARCHAR(100);
ALTER TABLE users ADD COLUMN IF NOT EXISTS state VARCHAR(100);
ALTER TABLE users ADD COLUMN IF NOT EXISTS pin_code VARCHAR(20);
ALTER TABLE users ADD COLUMN IF NOT EXISTS emergency_contact_name VARCHAR(100);
ALTER TABLE users ADD COLUMN IF NOT EXISTS emergency_contact_number VARCHAR(20);
ALTER TABLE users ADD COLUMN IF NOT EXISTS profile_image_url TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS profile_image BYTEA;

ALTER TABLE charging_sessions ADD COLUMN IF NOT EXISTS ocpp_transaction_id VARCHAR(255);
ALTER TABLE charging_sessions ADD COLUMN IF NOT EXISTS meter_start_wh NUMERIC(12, 3) DEFAULT 0.000;
ALTER TABLE charging_sessions ADD COLUMN IF NOT EXISTS meter_stop_wh NUMERIC(12, 3) DEFAULT 0.000;
ALTER TABLE charging_sessions ADD COLUMN IF NOT EXISTS stop_reason VARCHAR(255);

CREATE TABLE IF NOT EXISTS vehicles (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    registration_number VARCHAR(100) NOT NULL,
    brand VARCHAR(100) NOT NULL,
    model VARCHAR(100) NOT NULL,
    variant VARCHAR(100),
    type VARCHAR(50),
    battery_capacity_kwh NUMERIC(5, 2),
    connector_type VARCHAR(50),
    nickname VARCHAR(100),
    is_default BOOLEAN DEFAULT FALSE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

--------------------------------------------------------------------------------
-- 2. Seed Permissions Idempotently
--------------------------------------------------------------------------------
INSERT INTO permissions (name, description) VALUES
('READ_STATIONS', 'Ability to view station details, availability, and connectors'),
('MANAGE_STATIONS', 'Ability to create, update, or delete station information (Vendor/Admin)'),
('START_CHARGING', 'Permission to initiate a charging session'),
('STOP_CHARGING', 'Permission to stop an active charging session'),
('VIEW_TRANSACTIONS', 'Ability to view personal transaction history'),
('MANAGE_FIRMWARE', 'Ability to upload and manage charger firmware configurations'),
('MANAGE_USERS', 'Full administrative user management access'),
('VIEW_SYSTEM_AUDIT', 'Ability to view global system audit logs')
ON CONFLICT (name) DO NOTHING;

--------------------------------------------------------------------------------
-- 3. Seed Roles Idempotently
--------------------------------------------------------------------------------
INSERT INTO roles (name, description) VALUES
('ROLE_CUSTOMER', 'Standard EV driver customer'),
('ROLE_VENDOR', 'Charge Point Operator (CPO) / Business Owner'),
('ROLE_ADMIN', 'Platform Administrator')
ON CONFLICT (name) DO NOTHING;

--------------------------------------------------------------------------------
-- 4. Map Permissions to Roles Idempotently
--------------------------------------------------------------------------------
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r CROSS JOIN permissions p WHERE r.name = 'ROLE_ADMIN'
ON CONFLICT (role_id, permission_id) DO NOTHING;

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r CROSS JOIN permissions p 
WHERE r.name = 'ROLE_VENDOR' AND p.name IN ('READ_STATIONS', 'MANAGE_STATIONS', 'VIEW_TRANSACTIONS')
ON CONFLICT (role_id, permission_id) DO NOTHING;

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r CROSS JOIN permissions p 
WHERE r.name = 'ROLE_CUSTOMER' AND p.name IN ('READ_STATIONS', 'START_CHARGING', 'STOP_CHARGING', 'VIEW_TRANSACTIONS')
ON CONFLICT (role_id, permission_id) DO NOTHING;

--------------------------------------------------------------------------------
-- 5. Seed Platform Users Idempotently
--------------------------------------------------------------------------------
INSERT INTO users (email, password, first_name, last_name, phone_number, is_verified, is_account_non_locked) VALUES
('admin@ecomargin.com', '$2a$12$R.S4wN6M2Xq8vK/h7F0.Qe.Hvx7K4U5tQ3BswY00sN1b8lO.Wd7iG', 'Platform', 'Admin', '+15550100', TRUE, TRUE),
('vendor@ecomargin.com', '$2a$12$R.S4wN6M2Xq8vK/h7F0.Qe.Hvx7K4U5tQ3BswY00sN1b8lO.Wd7iG', 'John', 'CPO', '+15550101', TRUE, TRUE),
('customer@ecomargin.com', '$2a$12$R.S4wN6M2Xq8vK/h7F0.Qe.Hvx7K4U5tQ3BswY00sN1b8lO.Wd7iG', 'Jane', 'Driver', '+15550102', TRUE, TRUE),
('driver@ecomargin.com', '$2a$12$R.S4wN6M2Xq8vK/h7F0.Qe.Hvx7K4U5tQ3BswY00sN1b8lO.Wd7iG', 'Driver', 'User', '+15550103', TRUE, TRUE)
ON CONFLICT (email) DO NOTHING;

-- Assign User Roles Idempotently
INSERT INTO user_roles (user_id, role_id)
SELECT u.id, r.id FROM users u JOIN roles r ON (
    (u.email = 'admin@ecomargin.com' AND r.name = 'ROLE_ADMIN') OR
    (u.email = 'vendor@ecomargin.com' AND r.name = 'ROLE_VENDOR') OR
    (u.email = 'customer@ecomargin.com' AND r.name = 'ROLE_CUSTOMER') OR
    (u.email = 'driver@ecomargin.com' AND r.name = 'ROLE_CUSTOMER')
)
ON CONFLICT (user_id, role_id) DO NOTHING;

-- Initialize Wallets Idempotently
INSERT INTO wallets (user_id, balance, currency)
SELECT u.id, 100.00, 'USD' FROM users u WHERE u.email = 'customer@ecomargin.com'
AND NOT EXISTS (SELECT 1 FROM wallets w WHERE w.user_id = u.id);

INSERT INTO wallets (user_id, balance, currency)
SELECT u.id, 100.00, 'USD' FROM users u WHERE u.email = 'driver@ecomargin.com'
AND NOT EXISTS (SELECT 1 FROM wallets w WHERE w.user_id = u.id);

INSERT INTO wallets (user_id, balance, currency)
SELECT u.id, 0.00, 'USD' FROM users u WHERE u.email = 'vendor@ecomargin.com'
AND NOT EXISTS (SELECT 1 FROM wallets w WHERE w.user_id = u.id);

--------------------------------------------------------------------------------
-- 6. Seed Vendor, Stations, Chargers & Connectors Idempotently
--------------------------------------------------------------------------------
INSERT INTO vendors (user_id, business_name, tax_id, address, status)
SELECT u.id, 'EcoCharge Networks LLC', 'TX-987654321', '456 CPO Boulevard, Austin, TX', 'ACTIVE'
FROM users u WHERE u.email = 'vendor@ecomargin.com'
AND NOT EXISTS (SELECT 1 FROM vendors v WHERE v.business_name = 'EcoCharge Networks LLC');

INSERT INTO stations (vendor_id, name, latitude, longitude, address, status)
SELECT v.id, 'Austin Downtown Hub', 30.267153, -97.743062, '120 E 6th St, Austin, TX 78701', 'ACTIVE'
FROM vendors v WHERE v.business_name = 'EcoCharge Networks LLC'
AND NOT EXISTS (SELECT 1 FROM stations s WHERE s.name = 'Austin Downtown Hub');

INSERT INTO stations (vendor_id, name, latitude, longitude, address, status)
SELECT v.id, 'North Loop Charger Point', 30.318858, -97.723789, '5310 Airport Blvd, Austin, TX 78751', 'ACTIVE'
FROM vendors v WHERE v.business_name = 'EcoCharge Networks LLC'
AND NOT EXISTS (SELECT 1 FROM stations s WHERE s.name = 'North Loop Charger Point');

INSERT INTO chargers (station_id, ocpp_id, model, brand, status, firmware_version)
SELECT s.id, 'TX_AUS_DWTN_01', 'Tritium RT50', 'Tritium', 'AVAILABLE', 'v1.4.2'
FROM stations s WHERE s.name = 'Austin Downtown Hub'
AND NOT EXISTS (SELECT 1 FROM chargers c WHERE c.ocpp_id = 'TX_AUS_DWTN_01');

INSERT INTO chargers (station_id, ocpp_id, model, brand, status, firmware_version)
SELECT s.id, 'TX_AUS_DWTN_02', 'ABB Terra 184', 'ABB', 'AVAILABLE', 'v2.1.0'
FROM stations s WHERE s.name = 'Austin Downtown Hub'
AND NOT EXISTS (SELECT 1 FROM chargers c WHERE c.ocpp_id = 'TX_AUS_DWTN_02');

INSERT INTO chargers (station_id, ocpp_id, model, brand, status, firmware_version)
SELECT s.id, 'TX_AUS_NL_01', 'Tritium RT50', 'Tritium', 'AVAILABLE', 'v1.4.2'
FROM stations s WHERE s.name = 'North Loop Charger Point'
AND NOT EXISTS (SELECT 1 FROM chargers c WHERE c.ocpp_id = 'TX_AUS_NL_01');

INSERT INTO connectors (charger_id, connector_index, type, status, max_power_kw)
SELECT c.id, 1, 'CCS2', 'AVAILABLE', 50.00 FROM chargers c WHERE c.ocpp_id = 'TX_AUS_DWTN_01'
AND NOT EXISTS (SELECT 1 FROM connectors conn WHERE conn.charger_id = c.id AND conn.connector_index = 1);

INSERT INTO connectors (charger_id, connector_index, type, status, max_power_kw)
SELECT c.id, 2, 'CHADEMO', 'AVAILABLE', 50.00 FROM chargers c WHERE c.ocpp_id = 'TX_AUS_DWTN_01'
AND NOT EXISTS (SELECT 1 FROM connectors conn WHERE conn.charger_id = c.id AND conn.connector_index = 2);

INSERT INTO connectors (charger_id, connector_index, type, status, max_power_kw)
SELECT c.id, 1, 'CCS2', 'AVAILABLE', 180.00 FROM chargers c WHERE c.ocpp_id = 'TX_AUS_DWTN_02'
AND NOT EXISTS (SELECT 1 FROM connectors conn WHERE conn.charger_id = c.id AND conn.connector_index = 1);

INSERT INTO connectors (charger_id, connector_index, type, status, max_power_kw)
SELECT c.id, 2, 'CCS2', 'AVAILABLE', 180.00 FROM chargers c WHERE c.ocpp_id = 'TX_AUS_DWTN_02'
AND NOT EXISTS (SELECT 1 FROM connectors conn WHERE conn.charger_id = c.id AND conn.connector_index = 2);

INSERT INTO connectors (charger_id, connector_index, type, status, max_power_kw)
SELECT c.id, 1, 'CCS2', 'AVAILABLE', 50.00 FROM chargers c WHERE c.ocpp_id = 'TX_AUS_NL_01'
AND NOT EXISTS (SELECT 1 FROM connectors conn WHERE conn.charger_id = c.id AND conn.connector_index = 1);

--------------------------------------------------------------------------------
-- 7. System Settings Idempotently
--------------------------------------------------------------------------------
INSERT INTO settings (setting_key, setting_value, description) VALUES
('default_charging_rate_per_kwh', '0.35', 'Standard charge per kWh in USD when not overridden by station settings'),
('idle_fee_per_minute', '0.15', 'Fee assessed per minute after charging completes and EV is still plugged in'),
('booking_timeout_minutes', '15', 'Time standard booking reserves a connector before auto-release'),
('min_wallet_balance_to_start', '10.00', 'Minimum required wallet balance to authorize session start')
ON CONFLICT (setting_key) DO NOTHING;
