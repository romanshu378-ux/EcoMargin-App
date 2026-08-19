-- PostgreSQL Migration: V13__add_connector_unit_rate.sql
-- Safely add per-connector charging rate column with default 18.00 INR per kWh

ALTER TABLE connectors
ADD COLUMN IF NOT EXISTS unit_rate NUMERIC(10, 2) DEFAULT 18.00;

UPDATE connectors
SET unit_rate = 18.00
WHERE unit_rate IS NULL;
