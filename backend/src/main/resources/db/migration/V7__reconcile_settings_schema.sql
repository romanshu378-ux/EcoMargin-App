-- PostgreSQL Migration: V7__reconcile_settings_schema.sql
-- Safely reconcile settings table to use 'setting_key' as the canonical primary key column.
-- Non-destructive, idempotent, and safe for production Render environment.

DO $$
BEGIN
    ----------------------------------------------------------------------------
    -- 1. Ensure 'setting_key' column exists
    ----------------------------------------------------------------------------
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'settings' AND column_name = 'setting_key'
    ) THEN
        ALTER TABLE settings ADD COLUMN setting_key VARCHAR(100);
        RAISE NOTICE 'V7 Migration: Added setting_key column to settings table.';
    END IF;

    ----------------------------------------------------------------------------
    -- 2. Data Migration: Copy data from legacy 'key' to 'setting_key' if 'key' exists
    ----------------------------------------------------------------------------
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'settings' AND column_name = 'key'
    ) THEN
        -- Copy 'key' to 'setting_key' where setting_key is NULL
        UPDATE settings 
        SET setting_key = key 
        WHERE setting_key IS NULL AND key IS NOT NULL;

        RAISE NOTICE 'V7 Migration: Synchronized legacy key values to setting_key.';

        -- Drop primary key and unique constraints on legacy 'key' column
        DECLARE
            r RECORD;
        BEGIN
            FOR r IN (
                SELECT constraint_name 
                FROM information_schema.table_constraints 
                WHERE table_name = 'settings' 
                  AND constraint_type IN ('PRIMARY KEY', 'UNIQUE')
            ) LOOP
                EXECUTE 'ALTER TABLE settings DROP CONSTRAINT IF EXISTS ' || quote_ident(r.constraint_name) || ' CASCADE;';
            END LOOP;
        END;

        -- Drop NOT NULL constraint on legacy 'key' column and drop column
        ALTER TABLE settings ALTER COLUMN "key" DROP NOT NULL;
        ALTER TABLE settings DROP COLUMN IF EXISTS "key";
        RAISE NOTICE 'V7 Migration: Dropped legacy key column from settings table.';
    END IF;

    ----------------------------------------------------------------------------
    -- 3. Ensure 'setting_key' is NOT NULL and is PRIMARY KEY
    ----------------------------------------------------------------------------
    -- Ensure setting_key has NOT NULL constraint
    ALTER TABLE settings ALTER COLUMN setting_key SET NOT NULL;

    -- Add Primary Key constraint on setting_key if not present
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name = 'settings' AND constraint_type = 'PRIMARY KEY'
    ) THEN
        ALTER TABLE settings ADD CONSTRAINT settings_pkey PRIMARY KEY (setting_key);
        RAISE NOTICE 'V7 Migration: Established setting_key as PRIMARY KEY on settings table.';
    END IF;

END $$;
