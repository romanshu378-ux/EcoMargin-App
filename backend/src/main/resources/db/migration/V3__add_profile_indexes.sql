-- Migration V3: Add Expression Index on LOWER(email) for Ultra-Fast Profile and Auth Lookups
CREATE INDEX IF NOT EXISTS idx_users_lower_email ON users (LOWER(email));
