-- PostgreSQL Migration: V9__ensure_users_email_unique.sql
-- Safely ensures users(email) has a full UNIQUE index/constraint, handling any pre-existing duplicate emails cleanly.

DO $$
DECLARE
    rec RECORD;
    v_dup_count INT := 0;
BEGIN
    ----------------------------------------------------------------------------
    -- A. Handle potential duplicate active emails safely before creating UNIQUE index
    ----------------------------------------------------------------------------
    -- Find emails with multiple active records (deleted_at IS NULL)
    FOR rec IN 
        SELECT LOWER(email) AS clean_email, COUNT(*) AS cnt 
        FROM users 
        WHERE deleted_at IS NULL 
        GROUP BY LOWER(email) 
        HAVING COUNT(*) > 1
    LOOP
        v_dup_count := v_dup_count + 1;
        RAISE NOTICE 'V9 Migration: Resolving duplicate active email %', rec.clean_email;

        -- Keep the earliest record (min id), anonymize older duplicate emails
        UPDATE users u
        SET email = 'dup_' || u.id || '_' || u.email,
            updated_at = CURRENT_TIMESTAMP
        WHERE LOWER(u.email) = rec.clean_email 
          AND u.deleted_at IS NULL
          AND u.id NOT IN (
              SELECT MIN(id) 
              FROM users 
              WHERE LOWER(email) = rec.clean_email AND deleted_at IS NULL
          );
    END LOOP;

    ----------------------------------------------------------------------------
    -- B. Ensure UNIQUE constraint / index on users(email)
    ----------------------------------------------------------------------------
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE tablename = 'users' 
          AND indexname IN ('users_email_key', 'idx_users_email_unique')
    ) AND NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name = 'users' AND constraint_type = 'UNIQUE' AND constraint_name = 'users_email_key'
    ) THEN
        CREATE UNIQUE INDEX idx_users_email_unique ON users (email);
        RAISE NOTICE 'V9 Migration: Established idx_users_email_unique on users(email).';
    END IF;

END $$;
