-- PostgreSQL Migration: V10__add_audit_logs_columns_and_sequence.sql
-- Add missing audit_logs tracking columns and ID sequence for enterprise audit logs

-- 1. Ensure sequence for audit_logs id column exists and set default
CREATE SEQUENCE IF NOT EXISTS audit_logs_id_seq START WITH 1 INCREMENT BY 1;
ALTER TABLE audit_logs ALTER COLUMN id SET DEFAULT nextval('audit_logs_id_seq');

-- 2. Synchronize sequence value with max existing id to prevent primary key conflicts
SELECT setval('audit_logs_id_seq', COALESCE((SELECT MAX(id) FROM audit_logs), 0) + 1, false);

-- 3. Add missing columns expected by AuditLog entity and AuditLogService
ALTER TABLE audit_logs ADD COLUMN IF NOT EXISTS performed_by VARCHAR(255);
ALTER TABLE audit_logs ADD COLUMN IF NOT EXISTS entity_name VARCHAR(255);
ALTER TABLE audit_logs ADD COLUMN IF NOT EXISTS entity_id VARCHAR(255);
ALTER TABLE audit_logs ADD COLUMN IF NOT EXISTS previous_value TEXT;
ALTER TABLE audit_logs ADD COLUMN IF NOT EXISTS new_value TEXT;
