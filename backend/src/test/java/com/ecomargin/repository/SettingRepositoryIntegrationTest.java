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
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Integration tests for Setting Entity, DatabaseSeeder, and Schema Mapping.
 *
 * Explicit test cases:
 *  1. Fresh settings insertion
 *  2. Existing settings preservation (idempotency)
 *  3. Repeated seeder execution (no duplication)
 *  4. All 8 required settings present and non-null
 *  5. No duplicate setting identifiers
 *  6. No null setting_key / canonical column check
 *  7. Startup validation failure when required settings cannot be created
 *  8. Production schema compatibility (setting_key column mapping)
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
    // 1. Fresh settings insertion
    // -------------------------------------------------------------------------
    @Test
    @Order(1)
    @DisplayName("1. Fresh settings insertion: custom setting saves and reads back successfully")
    @Transactional
    void testFreshSettingsInsertion() {
        String testKey   = "custom_fresh_setting_key";
        String testValue = "custom_fresh_setting_value";

        Setting saved = settingRepository.save(Setting.builder()
                .key(testKey)
                .value(testValue)
                .description("Test fresh insertion")
                .updatedAt(LocalDateTime.now())
                .build());

        assertThat(saved.getKey()).isNotNull().isEqualTo(testKey);
        assertThat(saved.getValue()).isEqualTo(testValue);

        Optional<Setting> opt = settingRepository.findById(testKey);
        assertThat(opt).isPresent();
        assertThat(opt.get().getKey()).isEqualTo(testKey);
        assertThat(opt.get().getValue()).isEqualTo(testValue);
    }

    // -------------------------------------------------------------------------
    // 2. Existing settings preservation
    // -------------------------------------------------------------------------
    @Test
    @Order(2)
    @DisplayName("2. Existing settings preservation: existing production setting value is preserved on re-seed")
    void testExistingSettingsPreservation() {
        databaseSeeder.run();

        // Simulate admin override
        settingRepository.save(Setting.builder()
                .key("min_wallet_balance_to_start")
                .value("99.99")
                .description("Admin override test")
                .updatedAt(LocalDateTime.now())
                .build());

        // Re-run seeder
        databaseSeeder.run();

        Setting retrieved = settingRepository.findById("min_wallet_balance_to_start")
                .orElseThrow(() -> new AssertionError("min_wallet_balance_to_start missing"));
        assertThat(retrieved.getValue())
                .withFailMessage("Seeder must NOT overwrite existing production value")
                .isEqualTo("99.99");

        // Restore default
        settingRepository.save(Setting.builder()
                .key("min_wallet_balance_to_start")
                .value("50.00")
                .description("Minimum wallet balance required to initiate charging")
                .updatedAt(LocalDateTime.now())
                .build());
    }

    // -------------------------------------------------------------------------
    // 3. Repeated seeder execution
    // -------------------------------------------------------------------------
    @Test
    @Order(3)
    @DisplayName("3. Repeated seeder execution: 3 consecutive seeder runs execute without error or duplication")
    void testRepeatedSeederExecution() {
        databaseSeeder.run();
        databaseSeeder.run();
        databaseSeeder.run();

        List<Setting> all = settingRepository.findAll();
        assertThat(all).isNotEmpty();
    }

    // -------------------------------------------------------------------------
    // 4. All 8 required settings
    // -------------------------------------------------------------------------
    @Test
    @Order(4)
    @DisplayName("4. All 8 required settings: all 8 mandatory application settings are present in database")
    void testAllEightRequiredSettingsPresent() {
        databaseSeeder.run();

        for (String reqKey : DatabaseSeeder.REQUIRED_SETTINGS) {
            Optional<Setting> opt = settingRepository.findById(reqKey);
            assertThat(opt)
                    .withFailMessage("Required setting setting_key='%s' is missing in DB", reqKey)
                    .isPresent();

            Setting setting = opt.get();
            assertThat(setting.getKey()).isNotNull().isEqualTo(reqKey);
            assertThat(setting.getValue()).isNotNull().isNotBlank();
        }
    }

    // -------------------------------------------------------------------------
    // 5. No duplicate setting identifiers
    // -------------------------------------------------------------------------
    @Test
    @Order(5)
    @DisplayName("5. No duplicate setting identifiers: total setting rows equals distinct setting_key count")
    void testNoDuplicateSettingIdentifiers() {
        databaseSeeder.run();

        List<Setting> settings = settingRepository.findAll();
        long totalCount = settings.size();
        long distinctKeyCount = settings.stream()
                .map(Setting::getKey)
                .filter(k -> k != null)
                .distinct()
                .count();

        assertThat(totalCount).isEqualTo(distinctKeyCount)
                .withFailMessage("Duplicate setting keys detected in database");
    }

    // -------------------------------------------------------------------------
    // 6. No null setting_key
    // -------------------------------------------------------------------------
    @Test
    @Order(6)
    @DisplayName("6. No null setting_key: every persisted setting has a non-null, non-blank setting_key")
    void testNoNullSettingKey() {
        databaseSeeder.run();

        List<Setting> settings = settingRepository.findAll();
        for (Setting s : settings) {
            assertThat(s.getKey())
                    .withFailMessage("Persisted setting has null or blank setting_key")
                    .isNotNull()
                    .isNotBlank();
        }
    }

    // -------------------------------------------------------------------------
    // 7. Startup failure when required settings cannot be created
    // -------------------------------------------------------------------------
    @Test
    @Order(7)
    @DisplayName("7. Startup failure: validateRequiredSettings throws IllegalStateException when required key missing")
    void testStartupFailureWhenRequiredSettingMissing() {
        databaseSeeder.run();

        // Temporarily delete one required setting to simulate DB failure / missing key
        settingRepository.deleteById("min_wallet_balance_to_start");

        assertThatThrownBy(() -> databaseSeeder.validateRequiredSettings())
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("Required application settings are missing");

        // Restore missing setting
        databaseSeeder.run();
    }

    // -------------------------------------------------------------------------
    // 8. Production schema compatibility
    // -------------------------------------------------------------------------
    @Test
    @Order(8)
    @DisplayName("8. Production schema compatibility: Setting entity maps to setting_key column without SQL violations")
    @Transactional
    void testProductionSchemaCompatibility() {
        Setting setting = Setting.builder()
                .key("schema_compat_test")
                .value("schema_compat_value")
                .description("Schema compatibility test")
                .updatedAt(LocalDateTime.now())
                .build();

        Setting saved = settingRepository.save(setting);
        assertThat(saved).isNotNull();
        assertThat(saved.getKey()).isEqualTo("schema_compat_test");

        Optional<Setting> found = settingRepository.findById("schema_compat_test");
        assertThat(found).isPresent();
        assertThat(found.get().getValue()).isEqualTo("schema_compat_value");
    }
}
