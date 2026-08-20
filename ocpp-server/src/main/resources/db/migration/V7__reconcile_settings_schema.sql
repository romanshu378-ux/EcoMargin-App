-- PostgreSQL Migration: V7__reconcile_settings_schema.sql
-- Safely reconcile settings table to use 'setting_key' as the canonical primary key column
-- and 'setting_value' as the canonical value column.
-- Target / Defensive / Non-destructive / Deterministic / Production-ready.

DO $$
DECLARE
    v_dup_count INT := 0;
    v_null_count INT := 0;
    v_fk_count INT := 0;
    v_pk_constraint_name TEXT;
BEGIN
    ----------------------------------------------------------------------------
    -- A. Verify that settings table exists
    ----------------------------------------------------------------------------
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_name = 'settings' AND table_schema = 'public'
    ) THEN
        RAISE NOTICE 'V7 Migration: settings table does not exist. Skipping reconciliation.';
        RETURN;
    END IF;

    ----------------------------------------------------------------------------
    -- B. Ensure 'setting_key' column exists
    ----------------------------------------------------------------------------
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'settings' AND column_name = 'setting_key' AND table_schema = 'public'
    ) THEN
        ALTER TABLE settings ADD COLUMN setting_key VARCHAR(100);
        RAISE NOTICE 'V7 Migration: Added setting_key column to settings table.';
    END IF;

    -- If legacy 'key' column exists, copy data to setting_key where null
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'settings' AND column_name = 'key' AND table_schema = 'public'
    ) THEN
        UPDATE settings 
        SET setting_key = "key"
        WHERE setting_key IS NULL AND "key" IS NOT NULL;

        RAISE NOTICE 'V7 Migration: Copied data from legacy key to setting_key.';
    END IF;

    ----------------------------------------------------------------------------
    -- C. Ensure 'setting_value' column exists
    ----------------------------------------------------------------------------
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'settings' AND column_name = 'setting_value' AND table_schema = 'public'
    ) THEN
        ALTER TABLE settings ADD COLUMN setting_value TEXT;
        RAISE NOTICE 'V7 Migration: Added setting_value column to settings table.';
    END IF;

    -- If legacy 'value' column exists, copy data to setting_value where null
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'settings' AND column_name = 'value' AND table_schema = 'public'
    ) THEN
        UPDATE settings 
        SET setting_value = "value"
        WHERE setting_value IS NULL AND "value" IS NOT NULL;

        ALTER TABLE settings DROP COLUMN "value";
        RAISE NOTICE 'V7 Migration: Copied data from legacy value to setting_value and dropped value column.';
    END IF;

    ----------------------------------------------------------------------------
    -- D. Data Integrity Validation — Assert no NULL or duplicate setting_key
    ----------------------------------------------------------------------------
    -- Check for NULL setting_key values
    SELECT COUNT(*) INTO v_null_count 
    FROM settings 
    WHERE setting_key IS NULL;

    IF v_null_count > 0 THEN
        RAISE EXCEPTION 'V7 Migration Aborted! Found % row(s) with NULL setting_key in settings table. Data cleanup required before migration.', v_null_count;
    END IF;

    -- Check for duplicate setting_key values
    SELECT COUNT(*) INTO v_dup_count FROM (
        SELECT setting_key 
        FROM settings 
        GROUP BY setting_key 
        HAVING COUNT(*) > 1
    ) dups;

    IF v_dup_count > 0 THEN
        RAISE EXCEPTION 'V7 Migration Aborted! Found % duplicate setting_key value(s) in settings table. Deduplication required before migration.', v_dup_count;
    END IF;

    -- Check if any Foreign Key constraint references settings table
    SELECT COUNT(*) INTO v_fk_count
    FROM information_schema.table_constraints tc
    JOIN information_schema.constraint_column_usage ccu
      ON ccu.constraint_name = tc.constraint_name
    WHERE tc.constraint_type = 'FOREIGN KEY'
      AND ccu.table_name = 'settings';

    IF v_fk_count > 0 THEN
        RAISE EXCEPTION 'V7 Migration Aborted! Found % foreign key(s) referencing settings table. Manual inspection required.', v_fk_count;
    END IF;

    ----------------------------------------------------------------------------
    -- E. Drop ONLY the specific Primary Key constraint on settings.key (if present)
    ----------------------------------------------------------------------------
    SELECT tc.constraint_name INTO v_pk_constraint_name
    FROM information_schema.table_constraints tc
    JOIN information_schema.key_column_usage kcu
      ON tc.constraint_name = kcu.constraint_name
    WHERE tc.table_name = 'settings'
      AND tc.constraint_type = 'PRIMARY KEY'
      AND kcu.column_name = 'key';

    IF v_pk_constraint_name IS NOT NULL THEN
        EXECUTE 'ALTER TABLE settings DROP CONSTRAINT ' || quote_ident(v_pk_constraint_name);
        RAISE NOTICE 'V7 Migration: Dropped legacy primary key constraint % from settings.key.', v_pk_constraint_name;
    END IF;

    ----------------------------------------------------------------------------
    -- F. Set setting_key & setting_value NOT NULL and add Primary Key on setting_key
    ----------------------------------------------------------------------------
    ALTER TABLE settings ALTER COLUMN setting_key SET NOT NULL;
    ALTER TABLE settings ALTER COLUMN setting_value SET NOT NULL;

    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.table_constraints tc
        JOIN information_schema.key_column_usage kcu
          ON tc.constraint_name = kcu.constraint_name
        WHERE tc.table_name = 'settings'
          AND tc.constraint_type = 'PRIMARY KEY'
          AND kcu.column_name = 'setting_key'
    ) THEN
        ALTER TABLE settings ADD CONSTRAINT settings_pkey PRIMARY KEY (setting_key);
        RAISE NOTICE 'V7 Migration: Established setting_key as PRIMARY KEY on settings table.';
    END IF;

    ----------------------------------------------------------------------------
    -- G. Remove legacy 'key' column ONLY if it exists and setting_key is active
    ----------------------------------------------------------------------------
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'settings' AND column_name = 'key' AND table_schema = 'public'
    ) THEN
        ALTER TABLE settings DROP COLUMN "key";
        RAISE NOTICE 'V7 Migration: Dropped legacy key column from settings table.';
    END IF;

    RAISE NOTICE 'V7 Migration Completed Successfully: settings table now uses setting_key as primary key and setting_value as value column.';
END $$;
