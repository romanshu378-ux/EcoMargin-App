-- Migration V12: Add location taxonomy columns (city, state, country) to stations table safely
-- Ensures full schema compatibility with Station entity while maintaining existing data integrity.

ALTER TABLE stations ADD COLUMN IF NOT EXISTS city VARCHAR(100);
ALTER TABLE stations ADD COLUMN IF NOT EXISTS state VARCHAR(100);
ALTER TABLE stations ADD COLUMN IF NOT EXISTS country VARCHAR(100);

-- Populate sensible defaults for existing station rows where location fields are null
UPDATE stations SET city = 'Jaipur' WHERE city IS NULL;
UPDATE stations SET state = 'Rajasthan' WHERE state IS NULL;
UPDATE stations SET country = 'India' WHERE country IS NULL;

-- Refine known seeded station locations if applicable
UPDATE stations SET city = 'Alwar', state = 'Rajasthan', country = 'India' WHERE name = 'Alwar Charging Hub';
UPDATE stations SET city = 'Austin', state = 'Texas', country = 'USA' WHERE name = 'Austin Downtown Hub';
