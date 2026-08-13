-- Migration V6: Create refresh_tokens, add jwt_version, and apply financial check constraints

-- Add jwt_version to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS jwt_version INT NOT NULL DEFAULT 0;

-- Ensure transaction ledger has balance tracking columns
ALTER TABLE transactions ADD COLUMN IF NOT EXISTS balance_before NUMERIC(12, 2);
ALTER TABLE transactions ADD COLUMN IF NOT EXISTS balance_after NUMERIC(12, 2);
ALTER TABLE transactions ADD COLUMN IF NOT EXISTS reference_type VARCHAR(100);

-- Apply non-negative constraint to wallet balance
ALTER TABLE wallets DROP CONSTRAINT IF EXISTS chk_wallets_balance_non_negative;
ALTER TABLE wallets ADD CONSTRAINT chk_wallets_balance_non_negative CHECK (balance >= 0.00);

-- Apply non-zero constraint to transaction amounts (allows positive/negative for Credit/Debit)
ALTER TABLE transactions DROP CONSTRAINT IF EXISTS chk_transactions_amount_non_zero;
ALTER TABLE transactions ADD CONSTRAINT chk_transactions_amount_non_zero CHECK (amount <> 0.00);

-- Recreate refresh_tokens to support status tracking and reuse detection
DROP TABLE IF EXISTS refresh_tokens CASCADE;

CREATE TABLE refresh_tokens (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token VARCHAR(255) UNIQUE NOT NULL,
    expiry_date TIMESTAMP WITH TIME ZONE NOT NULL,
    revoked BOOLEAN NOT NULL DEFAULT FALSE,
    used BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);
