-- Migration V5: Rename RFID and Privacy Settings constraints to explicit custom names

-- For privacy_settings:
ALTER TABLE privacy_settings DROP CONSTRAINT IF EXISTS privacy_settings_user_id_key;
ALTER TABLE privacy_settings DROP CONSTRAINT IF EXISTS uk_8im8nq9irhhgjmw7pnfl2awu2;
ALTER TABLE privacy_settings ADD CONSTRAINT uk_privacy_settings_user_id UNIQUE (user_id);

-- For rfid_cards:
ALTER TABLE rfid_cards DROP CONSTRAINT IF EXISTS rfid_cards_user_id_key;
ALTER TABLE rfid_cards DROP CONSTRAINT IF EXISTS uk_rgdkvsjwq3131jxgt6jjvqjcd;
ALTER TABLE rfid_cards ADD CONSTRAINT uk_rfid_cards_user_id UNIQUE (user_id);

ALTER TABLE rfid_cards DROP CONSTRAINT IF EXISTS rfid_cards_card_number_key;
ALTER TABLE rfid_cards DROP CONSTRAINT IF EXISTS uk_5q2foy0er5yn7jq8dgu89r4vi;
ALTER TABLE rfid_cards ADD CONSTRAINT uk_rfid_cards_card_number UNIQUE (card_number);

ALTER TABLE rfid_cards DROP CONSTRAINT IF EXISTS rfid_cards_card_uid_key;
ALTER TABLE rfid_cards DROP CONSTRAINT IF EXISTS uk_qur23cnm5t76ar7gpdkvo4bc;
ALTER TABLE rfid_cards ADD CONSTRAINT uk_rfid_cards_card_uid UNIQUE (card_uid);
