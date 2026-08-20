-- Migration V11: Align wallets.version column type to BIGINT
ALTER TABLE wallets
ALTER COLUMN version TYPE BIGINT;
