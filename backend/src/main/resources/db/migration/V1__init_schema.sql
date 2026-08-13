-- PostgreSQL Migration: V1__init_schema
-- Optimized for Enterprise Scale, High Concurrency, Soft Deletes, and Partitioning

-- Enable UUID extension if needed
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

--------------------------------------------------------------------------------
-- 1. Roles & Permissions (RBAC)
--------------------------------------------------------------------------------
CREATE TABLE permissions (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

CREATE TABLE roles (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

CREATE TABLE role_permissions (
    role_id INT REFERENCES roles(id) ON DELETE CASCADE,
    permission_id INT REFERENCES permissions(id) ON DELETE CASCADE,
    PRIMARY KEY (role_id, permission_id)
);

--------------------------------------------------------------------------------
-- 2. Users, Refresh Tokens & Wallets
--------------------------------------------------------------------------------
CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    email VARCHAR(255) NOT NULL,
    password VARCHAR(255),
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    phone_number VARCHAR(20),
    google_id VARCHAR(255),
    is_verified BOOLEAN DEFAULT FALSE NOT NULL,
    is_locked BOOLEAN DEFAULT FALSE NOT NULL,
    jwt_version INT DEFAULT 0 NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted_at TIMESTAMP WITH TIME ZONE -- Soft delete support
);

-- Soft-delete aware unique indexes for users
CREATE UNIQUE INDEX idx_users_email_active ON users (email) WHERE deleted_at IS NULL;
CREATE UNIQUE INDEX idx_users_phone_active ON users (phone_number) WHERE deleted_at IS NULL;
CREATE UNIQUE INDEX idx_users_google_id_active ON users (google_id) WHERE deleted_at IS NULL;

CREATE TABLE user_roles (
    user_id BIGINT REFERENCES users(id) ON DELETE CASCADE,
    role_id INT REFERENCES roles(id) ON DELETE CASCADE,
    PRIMARY KEY (user_id, role_id)
);

CREATE TABLE refresh_tokens (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    token VARCHAR(255) UNIQUE NOT NULL,
    expiry_date TIMESTAMP WITH TIME ZONE NOT NULL
);

CREATE TABLE wallets (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT UNIQUE REFERENCES users(id) ON DELETE RESTRICT, -- Keep wallet even if user is archived
    balance NUMERIC(12, 2) DEFAULT 0.00 NOT NULL,
    currency VARCHAR(10) DEFAULT 'USD' NOT NULL,
    version INT DEFAULT 0 NOT NULL, -- Optimistic locking version
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

--------------------------------------------------------------------------------
-- 3. Vendors, Stations, Chargers & Connectors
--------------------------------------------------------------------------------
CREATE TABLE vendors (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT UNIQUE REFERENCES users(id) ON DELETE RESTRICT,
    business_name VARCHAR(255) NOT NULL,
    tax_id VARCHAR(100),
    address TEXT,
    status VARCHAR(50) DEFAULT 'PENDING' NOT NULL, -- PENDING, ACTIVE, SUSPENDED
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted_at TIMESTAMP WITH TIME ZONE -- Soft delete support
);

-- Soft-delete aware unique index for vendors
CREATE UNIQUE INDEX idx_vendors_tax_id_active ON vendors (tax_id) WHERE deleted_at IS NULL;

CREATE TABLE stations (
    id BIGSERIAL PRIMARY KEY,
    vendor_id BIGINT REFERENCES vendors(id) ON DELETE RESTRICT,
    name VARCHAR(255) NOT NULL,
    latitude DECIMAL(9, 6) NOT NULL,
    longitude DECIMAL(9, 6) NOT NULL,
    address TEXT,
    status VARCHAR(50) DEFAULT 'ACTIVE' NOT NULL, -- ACTIVE, INACTIVE, UNDER_MAINTENANCE
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted_at TIMESTAMP WITH TIME ZONE -- Soft delete support
);

CREATE TABLE chargers (
    id BIGSERIAL PRIMARY KEY,
    station_id BIGINT REFERENCES stations(id) ON DELETE RESTRICT,
    ocpp_id VARCHAR(100) NOT NULL, -- Unique identifier used in OCPP messages
    model VARCHAR(100),
    brand VARCHAR(100),
    status VARCHAR(50) DEFAULT 'UNAVAILABLE' NOT NULL, -- AVAILABLE, CHARGING, FAULTED, etc.
    firmware_version VARCHAR(50),
    metadata JSONB, -- For extensible vendor configurations
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted_at TIMESTAMP WITH TIME ZONE -- Soft delete support
);

-- Soft-delete aware unique index for chargers
CREATE UNIQUE INDEX idx_chargers_ocpp_id_active ON chargers (ocpp_id) WHERE deleted_at IS NULL;

CREATE TABLE connectors (
    id BIGSERIAL PRIMARY KEY,
    charger_id BIGINT REFERENCES chargers(id) ON DELETE RESTRICT,
    connector_index INT NOT NULL, -- e.g., 1 or 2 on a dual-connector charger
    type VARCHAR(50) NOT NULL, -- CCS2, TYPE2, CHADEMO, GB_T
    status VARCHAR(50) DEFAULT 'AVAILABLE' NOT NULL,
    max_power_kw DECIMAL(5, 2) DEFAULT 50.00 NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted_at TIMESTAMP WITH TIME ZONE -- Soft delete support
);

-- Soft-delete aware composite unique constraint for connectors
CREATE UNIQUE INDEX idx_connectors_charger_index_active ON connectors (charger_id, connector_index) WHERE deleted_at IS NULL;

--------------------------------------------------------------------------------
-- 4. Bookings & Sessions
--------------------------------------------------------------------------------
CREATE TABLE bookings (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT REFERENCES users(id) ON DELETE RESTRICT, -- Prevent hard-deleting historical records
    connector_id BIGINT REFERENCES connectors(id) ON DELETE RESTRICT,
    start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    end_time TIMESTAMP WITH TIME ZONE NOT NULL,
    status VARCHAR(50) DEFAULT 'PENDING' NOT NULL, -- PENDING, CONFIRMED, COMPLETED, CANCELLED
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

CREATE TABLE charging_sessions (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT REFERENCES users(id) ON DELETE RESTRICT,
    connector_id BIGINT REFERENCES connectors(id) ON DELETE RESTRICT,
    booking_id BIGINT REFERENCES bookings(id) ON DELETE SET NULL,
    status VARCHAR(50) DEFAULT 'STARTING' NOT NULL, -- STARTING, ACTIVE, STOPPING, COMPLETED, FAILED
    start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    end_time TIMESTAMP WITH TIME ZONE,
    total_energy_kwh NUMERIC(8, 3) DEFAULT 0.000,
    total_cost NUMERIC(10, 2) DEFAULT 0.00,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

--------------------------------------------------------------------------------
-- 5. Transactions & Payments
--------------------------------------------------------------------------------
CREATE TABLE transactions (
    id BIGSERIAL PRIMARY KEY,
    wallet_id BIGINT REFERENCES wallets(id) ON DELETE RESTRICT,
    session_id BIGINT REFERENCES charging_sessions(id) ON DELETE SET NULL,
    amount NUMERIC(10, 2) NOT NULL,
    type VARCHAR(50) NOT NULL, -- CREDIT (deposit), DEBIT (session charge)
    status VARCHAR(50) DEFAULT 'SUCCESS' NOT NULL, -- SUCCESS, FAILED, PENDING
    reference_id VARCHAR(255) UNIQUE, -- Stripe payment intent, etc.
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

CREATE TABLE payments (
    id BIGSERIAL PRIMARY KEY,
    transaction_id BIGINT REFERENCES transactions(id) ON DELETE RESTRICT,
    amount NUMERIC(10, 2) NOT NULL,
    gateway_name VARCHAR(50) NOT NULL, -- STRIPE, RAZORPAY, PAYPAL
    gateway_status VARCHAR(50) NOT NULL,
    gateway_transaction_id VARCHAR(255) UNIQUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

--------------------------------------------------------------------------------
-- 6. OCPP - Firmware & Diagnostics
--------------------------------------------------------------------------------
CREATE TABLE firmware_versions (
    id SERIAL PRIMARY KEY,
    version_string VARCHAR(100) UNIQUE NOT NULL,
    file_url TEXT NOT NULL,
    md5_checksum VARCHAR(32) NOT NULL,
    status VARCHAR(50) DEFAULT 'ACTIVE' NOT NULL, -- ACTIVE, DEPRECATED
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

CREATE TABLE diagnostics_logs (
    id BIGSERIAL PRIMARY KEY,
    charger_id BIGINT REFERENCES chargers(id) ON DELETE CASCADE,
    log_url TEXT,
    status VARCHAR(50) DEFAULT 'PENDING' NOT NULL, -- PENDING, UPLOADING, COMPLETED, FAILED
    requested_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    uploaded_at TIMESTAMP WITH TIME ZONE
);

--------------------------------------------------------------------------------
-- 7. High-Volume Partitioned Tables (Meter Values & Audit Logs)
--------------------------------------------------------------------------------

-- 7.1 Meter Values Partitioned by Month
CREATE TABLE meter_values (
    id BIGINT NOT NULL,
    session_id BIGINT NOT NULL,
    timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
    value NUMERIC(10, 3) NOT NULL,
    unit VARCHAR(20) DEFAULT 'Wh',
    measurand VARCHAR(100) DEFAULT 'Energy.Active.Import.Register',
    PRIMARY KEY (id, timestamp)
) PARTITION BY RANGE (timestamp);

-- Pre-creating Monthly Partitions for Meter Values
CREATE TABLE meter_values_y2026m08 PARTITION OF meter_values
    FOR VALUES FROM ('2026-08-01 00:00:00+00') TO ('2026-09-01 00:00:00+00');
CREATE TABLE meter_values_y2026m09 PARTITION OF meter_values
    FOR VALUES FROM ('2026-09-01 00:00:00+00') TO ('2026-10-01 00:00:00+00');
CREATE TABLE meter_values_y2026m10 PARTITION OF meter_values
    FOR VALUES FROM ('2026-10-01 00:00:00+00') TO ('2026-11-01 00:00:00+00');
CREATE TABLE meter_values_y2026m11 PARTITION OF meter_values
    FOR VALUES FROM ('2026-11-01 00:00:00+00') TO ('2026-12-01 00:00:00+00');
CREATE TABLE meter_values_y2026m12 PARTITION OF meter_values
    FOR VALUES FROM ('2026-12-01 00:00:00+00') TO ('2027-01-01 00:00:00+00');
CREATE TABLE meter_values_y2027m01 PARTITION OF meter_values
    FOR VALUES FROM ('2027-01-01 00:00:00+00') TO ('2027-02-01 00:00:00+00');
CREATE TABLE meter_values_y2027m02 PARTITION OF meter_values
    FOR VALUES FROM ('2027-02-01 00:00:00+00') TO ('2027-03-01 00:00:00+00');

-- Default Partition as a fallback
CREATE TABLE meter_values_default PARTITION OF meter_values DEFAULT;

-- 7.2 Audit Logs Partitioned by Year
CREATE TABLE audit_logs (
    id BIGINT NOT NULL,
    user_id BIGINT,
    action VARCHAR(100) NOT NULL,
    ip_address VARCHAR(45),
    details TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (id, created_at)
) PARTITION BY RANGE (created_at);

-- Pre-creating Yearly Partitions for Audit Logs
CREATE TABLE audit_logs_y2026 PARTITION OF audit_logs
    FOR VALUES FROM ('2026-01-01 00:00:00+00') TO ('2027-01-01 00:00:00+00');
CREATE TABLE audit_logs_y2027 PARTITION OF audit_logs
    FOR VALUES FROM ('2027-01-01 00:00:00+00') TO ('2028-01-01 00:00:00+00');

-- Default Partition as a fallback
CREATE TABLE audit_logs_default PARTITION OF audit_logs DEFAULT;

--------------------------------------------------------------------------------
-- 8. Notifications, Support & Settings
--------------------------------------------------------------------------------
CREATE TABLE notifications (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE NOT NULL,
    type VARCHAR(50) DEFAULT 'SYSTEM' NOT NULL, -- SYSTEM, CHARGING, TRANSACTION, PROMOTIONAL
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

CREATE TABLE support_tickets (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT REFERENCES users(id) ON DELETE SET NULL,
    subject VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    status VARCHAR(50) DEFAULT 'OPEN' NOT NULL, -- OPEN, IN_PROGRESS, RESOLVED, CLOSED
    priority VARCHAR(50) DEFAULT 'MEDIUM' NOT NULL, -- LOW, MEDIUM, HIGH, URGENT
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

CREATE TABLE settings (
    key VARCHAR(100) PRIMARY KEY,
    value TEXT NOT NULL,
    description TEXT,
    metadata JSONB, -- For configurations with complex structural requirements
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

--------------------------------------------------------------------------------
-- 9. Performance-Optimizing Indexes
--------------------------------------------------------------------------------

-- Geographical index for fast search of nearby active stations
CREATE INDEX idx_stations_location ON stations (latitude, longitude) WHERE deleted_at IS NULL;

-- Composite Index for fast active session lookups by charger/connector
CREATE INDEX idx_charging_sessions_active ON charging_sessions (connector_id, status)
WHERE status IN ('STARTING', 'ACTIVE', 'STOPPING');

-- Composite Index for finding active bookings for validation
CREATE INDEX idx_bookings_active ON bookings (connector_id, status, start_time, end_time)
WHERE status IN ('PENDING', 'CONFIRMED');

-- Index on active chargers for fast lookups via OCPP messages
CREATE INDEX idx_chargers_ocpp_id ON chargers (ocpp_id) WHERE deleted_at IS NULL;

-- Index on active connectors
CREATE INDEX idx_connectors_active ON connectors (charger_id) WHERE deleted_at IS NULL;

-- Partition-friendly index on meter_values session_id
CREATE INDEX idx_meter_values_session ON meter_values (session_id);

-- Index for searching user notifications
CREATE INDEX idx_notifications_user_unread ON notifications (user_id) WHERE is_read = FALSE;

-- Index on audit logs user search
CREATE INDEX idx_audit_logs_user ON audit_logs (user_id);
