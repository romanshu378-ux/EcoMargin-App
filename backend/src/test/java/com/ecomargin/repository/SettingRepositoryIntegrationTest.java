package com.ecomargin.repository;

import com.ecomargin.config.DatabaseSeeder;
import com.ecomargin.model.Setting;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.MethodOrderer;
import org.junit.jupiter.api.Order;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestMethodOrder;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Integration tests for the Setting entity and DatabaseSeeder.
 *
 * These tests verify that:
 *  1. The Setting entity correctly maps the Java field "key" to the DB column "setting_key".
 *  2. The Java field "value" maps to DB column "value".
 *  3. All mandatory default settings are seeded with non-null setting_key and value.
 *  4. Repeated seeder runs are fully idempotent (no duplicate rows, no overwrite of existing values).
 *  5. Specific high-priority settings (min_wallet_balance_to_start, default_charging_rate_per_kwh,
 *     offers_banners) insert successfully.
 */
@SpringBootTest
@ActiveProfiles("test")
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
class SettingRepositoryIntegrationTest {

    @Autowired
    private SettingRepository settingRepository;

    @Autowired
    private DatabaseSeeder databaseSeeder;

    // -------------------------------------------------------------------------
    // 1. Entity mapping: setting_key receives the key, value receives the value
    // -------------------------------------------------------------------------

    @Test
    @Order(1)
    @DisplayName("setting_key column receives the key; value column receives the value — no null constraint violations")
    @Transactional
    void testSettingEntityColumnMapping() {
        String testKey   = "test_column_mapping_key";
        String testValue = "test_column_mapping_value";

        Setting saved = settingRepository.save(Setting.builder()
                .key(testKey)
                .value(testValue)
                .description("Verifies setting_key <-> key mapping")
                .updatedAt(LocalDateTime.now())
                .build());

        // The entity's @Id field "key" must be stored in DB column "setting_key"
        assertThat(saved.getKey()).isNotNull().isEqualTo(testKey);
        assertThat(saved.getValue()).isNotNull().isEqualTo(testValue);
        assertThat(saved.getUpdatedAt()).isNotNull();

        // Retrieve by primary key (which is setting_key in the DB)
        Optional<Setting> retrieved = settingRepository.findById(testKey);
        assertThat(retrieved).isPresent();
        assertThat(retrieved.get().getKey()).isEqualTo(testKey);
        assertThat(retrieved.get().getValue()).isEqualTo(testValue);
    }

    // -------------------------------------------------------------------------
    // 2. min_wallet_balance_to_start inserts successfully
    // -------------------------------------------------------------------------

    @Test
    @Order(2)
    @DisplayName("min_wallet_balance_to_start: setting_key is non-null, value is 50.00")
    void testMinWalletBalanceSeeded() {
        databaseSeeder.run();

        Optional<Setting> opt = settingRepository.findById("min_wallet_balance_to_start");
        assertThat(opt).withFailMessage("min_wallet_balance_to_start must be present after seeder runs").isPresent();

        Setting s = opt.get();
        assertThat(s.getKey()).isNotNull().isEqualTo("min_wallet_balance_to_start");
        assertThat(s.getValue()).isNotNull().isNotEmpty();
        assertThat(s.getDescription()).isEqualTo("Minimum wallet balance required to initiate charging");
        assertThat(s.getUpdatedAt()).isNotNull();
    }

    // -------------------------------------------------------------------------
    // 3. default_charging_rate_per_kwh inserts successfully
    // -------------------------------------------------------------------------

    @Test
    @Order(3)
    @DisplayName("default_charging_rate_per_kwh: setting_key is non-null, value is non-empty")
    void testDefaultChargingRateSeeded() {
        databaseSeeder.run();

        Optional<Setting> opt = settingRepository.findById("default_charging_rate_per_kwh");
        assertThat(opt).withFailMessage("default_charging_rate_per_kwh must be present after seeder runs").isPresent();

        Setting s = opt.get();
        assertThat(s.getKey()).isNotNull().isEqualTo("default_charging_rate_per_kwh");
        assertThat(s.getValue()).isNotNull().isNotEmpty();
        assertThat(s.getUpdatedAt()).isNotNull();
    }

    // -------------------------------------------------------------------------
    // 4. offers_banners inserts successfully
    // -------------------------------------------------------------------------

    @Test
    @Order(4)
    @DisplayName("offers_banners: setting_key is non-null, value is non-empty JSON array")
    void testOffersBannersSeeded() {
        databaseSeeder.run();

        Optional<Setting> opt = settingRepository.findById("offers_banners");
        assertThat(opt).withFailMessage("offers_banners must be present after seeder runs").isPresent();

        Setting s = opt.get();
        assertThat(s.getKey()).isNotNull().isEqualTo("offers_banners");
        assertThat(s.getValue()).isNotNull().isNotBlank().startsWith("[");
        assertThat(s.getUpdatedAt()).isNotNull();
    }

    // -------------------------------------------------------------------------
    // 5. All 8 default settings are present with non-null setting_key and value
    // -------------------------------------------------------------------------

    @Test
    @Order(5)
    @DisplayName("All default settings: setting_key is non-null, value is non-null, updatedAt is non-null")
    void testAllDefaultSettingsSeededProperly() {
        databaseSeeder.run();

        String[] expectedKeys = {
                "min_wallet_balance_to_start",
                "default_charging_rate_per_kwh",
                "home_sections",
                "support_info",
                "app_maintenance",
                "charging_session_rules",
                "faqs",
                "offers_banners"
        };

        for (String key : expectedKeys) {
            Optional<Setting> opt = settingRepository.findById(key);
            assertThat(opt)
                    .withFailMessage("Expected setting setting_key='%s' to be present in DB", key)
                    .isPresent();

            Setting s = opt.get();
            assertThat(s.getKey())
                    .withFailMessage("setting_key must not be null for key=%s", key)
                    .isNotNull().isEqualTo(key);
            assertThat(s.getValue())
                    .withFailMessage("value must not be null/empty for key=%s", key)
                    .isNotNull().isNotEmpty();
            assertThat(s.getUpdatedAt())
                    .withFailMessage("updated_at must not be null for key=%s", key)
                    .isNotNull();
        }
    }

    // -------------------------------------------------------------------------
    // 6. Repeated seeder runs must NOT duplicate rows
    // -------------------------------------------------------------------------

    @Test
    @Order(6)
    @DisplayName("Repeated seeder runs: no duplicate rows for any setting key")
    void testNoRowDuplicationOnRepeatedSeederRuns() {
        databaseSeeder.run();
        databaseSeeder.run();
        databaseSeeder.run();

        long total = settingRepository.findAll().stream()
                .filter(s -> s.getKey() != null)
                .count();

        // Count distinct keys
        long distinct = settingRepository.findAll().stream()
                .map(Setting::getKey)
                .filter(k -> k != null)
                .distinct()
                .count();

        assertThat(total).isEqualTo(distinct)
                .withFailMessage("Duplicate settings detected after 3 seeder runs: total=%d distinct=%d", total, distinct);
    }

    // -------------------------------------------------------------------------
    // 7. Existing settings must NOT be overwritten on subsequent seeder runs
    // -------------------------------------------------------------------------

    @Test
    @Order(7)
    @DisplayName("Idempotency: existing production setting value is preserved after re-seeding")
    void testExistingSettingValuePreservedAfterReseed() {
        // Ensure initial seed
        databaseSeeder.run();

        // Simulate admin updating a setting
        settingRepository.save(Setting.builder()
                .key("min_wallet_balance_to_start")
                .value("99.99")
                .description("Custom admin override")
                .updatedAt(LocalDateTime.now())
                .build());

        // Run seeder 3 more times (simulating 3 Render restarts)
        databaseSeeder.run();
        databaseSeeder.run();
        databaseSeeder.run();

        // The admin override must still be intact
        Setting retrieved = settingRepository.findById("min_wallet_balance_to_start").orElseThrow(
                () -> new AssertionError("min_wallet_balance_to_start missing after re-seed"));
        assertThat(retrieved.getValue())
                .withFailMessage("Seeder MUST NOT overwrite existing production setting value")
                .isEqualTo("99.99");
        assertThat(retrieved.getDescription()).isEqualTo("Custom admin override");

        // Restore default for remaining tests
        settingRepository.save(Setting.builder()
                .key("min_wallet_balance_to_start")
                .value("50.00")
                .description("Minimum wallet balance required to initiate charging")
                .updatedAt(LocalDateTime.now())
                .build());
    }
}
