-- PostgreSQL Migration: V2__seed_data
-- Populates default constraints, roles, permissions, administrative settings, and sandbox entries.

--------------------------------------------------------------------------------
-- 1. Seed Permissions
--------------------------------------------------------------------------------
INSERT INTO permissions (name, description) VALUES
('READ_STATIONS', 'Ability to view station details, availability, and connectors'),
('MANAGE_STATIONS', 'Ability to create, update, or delete station information (Vendor/Admin)'),
('START_CHARGING', 'Permission to initiate a charging session'),
('STOP_CHARGING', 'Permission to stop an active charging session'),
('VIEW_TRANSACTIONS', 'Ability to view personal transaction history'),
('MANAGE_FIRMWARE', 'Ability to upload and manage charger firmware configurations'),
('MANAGE_USERS', 'Full administrative user management access'),
('VIEW_SYSTEM_AUDIT', 'Ability to view global system audit logs');

--------------------------------------------------------------------------------
-- 2. Seed Roles
--------------------------------------------------------------------------------
INSERT INTO roles (name, description) VALUES
('ROLE_CUSTOMER', 'Standard EV driver customer'),
('ROLE_VENDOR', 'Charge Point Operator (CPO) / Business Owner'),
('ROLE_ADMIN', 'Platform Administrator');

--------------------------------------------------------------------------------
-- 3. Map Permissions to Roles
--------------------------------------------------------------------------------
-- Admin Permissions (All)
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r CROSS JOIN permissions p WHERE r.name = 'ROLE_ADMIN';

-- Vendor Permissions
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r CROSS JOIN permissions p 
WHERE r.name = 'ROLE_VENDOR' AND p.name IN ('READ_STATIONS', 'MANAGE_STATIONS', 'VIEW_TRANSACTIONS');

-- Customer Permissions
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r CROSS JOIN permissions p 
WHERE r.name = 'ROLE_CUSTOMER' AND p.name IN ('READ_STATIONS', 'START_CHARGING', 'STOP_CHARGING', 'VIEW_TRANSACTIONS');

--------------------------------------------------------------------------------
-- 4. Seed Platform Users
--------------------------------------------------------------------------------
-- Passwords are encrypted standard BCrypt for 'password123' / 'driver123'
-- Admin: admin@ecomargin.com
-- Vendor: vendor@ecomargin.com
-- Customer: customer@ecomargin.com / driver@ecomargin.com
INSERT INTO users (email, password, first_name, last_name, phone_number, is_verified, is_locked) VALUES
('admin@ecomargin.com', '$2a$12$R.S4wN6M2Xq8vK/h7F0.Qe.Hvx7K4U5tQ3BswY00sN1b8lO.Wd7iG', 'Platform', 'Admin', '+15550100', TRUE, FALSE),
('vendor@ecomargin.com', '$2a$12$R.S4wN6M2Xq8vK/h7F0.Qe.Hvx7K4U5tQ3BswY00sN1b8lO.Wd7iG', 'John', 'CPO', '+15550101', TRUE, FALSE),
('customer@ecomargin.com', '$2a$12$R.S4wN6M2Xq8vK/h7F0.Qe.Hvx7K4U5tQ3BswY00sN1b8lO.Wd7iG', 'Jane', 'Driver', '+15550102', TRUE, FALSE),
('driver@ecomargin.com', '$2a$12$R.S4wN6M2Xq8vK/h7F0.Qe.Hvx7K4U5tQ3BswY00sN1b8lO.Wd7iG', 'Driver', 'User', '+15550103', TRUE, FALSE);

-- Assign User Roles
INSERT INTO user_roles (user_id, role_id) VALUES
((SELECT id FROM users WHERE email = 'admin@ecomargin.com'), (SELECT id FROM roles WHERE name = 'ROLE_ADMIN')),
((SELECT id FROM users WHERE email = 'vendor@ecomargin.com'), (SELECT id FROM roles WHERE name = 'ROLE_VENDOR')),
((SELECT id FROM users WHERE email = 'customer@ecomargin.com'), (SELECT id FROM roles WHERE name = 'ROLE_CUSTOMER')),
((SELECT id FROM users WHERE email = 'driver@ecomargin.com'), (SELECT id FROM roles WHERE name = 'ROLE_CUSTOMER'));

-- Initialize Wallets
INSERT INTO wallets (user_id, balance, currency) VALUES
((SELECT id FROM users WHERE email = 'customer@ecomargin.com'), 100.00, 'USD'),
((SELECT id FROM users WHERE email = 'driver@ecomargin.com'), 100.00, 'USD'),
((SELECT id FROM users WHERE email = 'vendor@ecomargin.com'), 0.00, 'USD');

--------------------------------------------------------------------------------
-- 5. Seed Vendor, Stations, Chargers & Connectors
--------------------------------------------------------------------------------
-- Create Vendor entry
INSERT INTO vendors (user_id, business_name, tax_id, address, status) VALUES
((SELECT id FROM users WHERE email = 'vendor@ecomargin.com'), 'EcoCharge Networks LLC', 'TX-987654321', '456 CPO Boulevard, Austin, TX', 'ACTIVE');

-- Create Sample Stations
INSERT INTO stations (vendor_id, name, latitude, longitude, address, status) VALUES
((SELECT id FROM vendors WHERE business_name = 'EcoCharge Networks LLC'), 'Austin Downtown Hub', 30.267153, -97.743062, '120 E 6th St, Austin, TX 78701', 'ACTIVE'),
((SELECT id FROM vendors WHERE business_name = 'EcoCharge Networks LLC'), 'North Loop Charger Point', 30.318858, -97.723789, '5310 Airport Blvd, Austin, TX 78751', 'ACTIVE');

-- Create Chargers (OCPP Compliant IDs)
INSERT INTO chargers (station_id, ocpp_id, model, brand, status, firmware_version) VALUES
((SELECT id FROM stations WHERE name = 'Austin Downtown Hub'), 'TX_AUS_DWTN_01', 'Tritium RT50', 'Tritium', 'AVAILABLE', 'v1.4.2'),
((SELECT id FROM stations WHERE name = 'Austin Downtown Hub'), 'TX_AUS_DWTN_02', 'ABB Terra 184', 'ABB', 'AVAILABLE', 'v2.1.0'),
((SELECT id FROM stations WHERE name = 'North Loop Charger Point'), 'TX_AUS_NL_01', 'Tritium RT50', 'Tritium', 'AVAILABLE', 'v1.4.2');

-- Create Connectors
INSERT INTO connectors (charger_id, connector_index, type, status, max_power_kw) VALUES
((SELECT id FROM chargers WHERE ocpp_id = 'TX_AUS_DWTN_01'), 1, 'CCS2', 'AVAILABLE', 50.00),
((SELECT id FROM chargers WHERE ocpp_id = 'TX_AUS_DWTN_01'), 2, 'CHADEMO', 'AVAILABLE', 50.00),
((SELECT id FROM chargers WHERE ocpp_id = 'TX_AUS_DWTN_02'), 1, 'CCS2', 'AVAILABLE', 180.00),
((SELECT id FROM chargers WHERE ocpp_id = 'TX_AUS_DWTN_02'), 2, 'CCS2', 'AVAILABLE', 180.00),
((SELECT id FROM chargers WHERE ocpp_id = 'TX_AUS_NL_01'), 1, 'CCS2', 'AVAILABLE', 50.00);

--------------------------------------------------------------------------------
-- 6. System Settings
--------------------------------------------------------------------------------
INSERT INTO settings (setting_key, value, description) VALUES
('default_charging_rate_per_kwh', '0.35', 'Standard charge per kWh in USD when not overridden by station settings'),
('idle_fee_per_minute', '0.15', 'Fee assessed per minute after charging completes and EV is still plugged in'),
('booking_timeout_minutes', '15', 'Time standard booking reserves a connector before auto-release'),
('min_wallet_balance_to_start', '10.00', 'Minimum required wallet balance to authorize session start');
