package com.ecomargin.repository;

import com.ecomargin.config.DatabaseSeeder;
import com.ecomargin.model.Setting;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest
@ActiveProfiles("test")
class SettingRepositoryIntegrationTest {

    @Autowired
    private SettingRepository settingRepository;

    @Autowired
    private DatabaseSeeder databaseSeeder;

    @Test
    @DisplayName("Verify Setting entity mapping with key, value, description and timestamps")
    @Transactional
    void testSettingEntityPersistence() {
        String testKey = "custom_test_key";
        String testValue = "99.99";
        String testDesc = "Test description for setting";

        Setting setting = Setting.builder()
                .key(testKey)
                .value(testValue)
                .description(testDesc)
                .updatedAt(LocalDateTime.now())
                .build();

        Setting saved = settingRepository.save(setting);
        assertThat(saved.getKey()).isEqualTo(testKey);
        assertThat(saved.getValue()).isEqualTo(testValue);
        assertThat(saved.getDescription()).isEqualTo(testDesc);
        assertThat(saved.getUpdatedAt()).isNotNull();

        Optional<Setting> retrieved = settingRepository.findById(testKey);
        assertThat(retrieved).isPresent();
        assertThat(retrieved.get().getKey()).isEqualTo(testKey);
        assertThat(retrieved.get().getValue()).isEqualTo(testValue);
    }

    @Test
    @DisplayName("Verify all default settings exist and have non-null keys, values, and valid timestamps")
    void testDefaultSettingsSeededProperly() {
        // Run seeder to ensure defaults are populated
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
            Optional<Setting> settingOpt = settingRepository.findById(key);
            assertThat(settingOpt)
                    .withFailMessage("Expected setting key '%s' to be present", key)
                    .isPresent();

            Setting setting = settingOpt.get();
            assertThat(setting.getKey()).isNotNull().isEqualTo(key);
            assertThat(setting.getValue()).isNotNull().isNotEmpty();
            assertThat(setting.getDescription()).isNotNull();
            assertThat(setting.getUpdatedAt()).isNotNull();
        }

        // Specific assertion for min_wallet_balance_to_start
        Setting minBal = settingRepository.findById("min_wallet_balance_to_start").orElseThrow();
        assertThat(minBal.getValue()).isEqualTo("50.00");
        assertThat(minBal.getDescription()).isEqualTo("Minimum wallet balance required to initiate charging");
    }

    @Test
    @DisplayName("Verify DatabaseSeeder is fully idempotent and does NOT overwrite existing custom values on restart")
    void testDatabaseSeederIdempotency() {
        // Ensure initial seed
        databaseSeeder.run();

        // Admin updates a setting
        Setting customMinBalance = Setting.builder()
                .key("min_wallet_balance_to_start")
                .value("75.00")
                .description("Custom min balance updated by admin")
                .updatedAt(LocalDateTime.now())
                .build();
        settingRepository.save(customMinBalance);

        // Run seeder multiple times consecutively to simulate multiple backend restarts
        databaseSeeder.run();
        databaseSeeder.run();
        databaseSeeder.run();

        // Verify existing value was preserved and not overwritten
        Setting retrieved = settingRepository.findById("min_wallet_balance_to_start").orElseThrow();
        assertThat(retrieved.getValue()).isEqualTo("75.00");
        assertThat(retrieved.getDescription()).isEqualTo("Custom min balance updated by admin");

        // Restore default for other tests
        settingRepository.save(Setting.builder()
                .key("min_wallet_balance_to_start")
                .value("50.00")
                .description("Minimum wallet balance required to initiate charging")
                .updatedAt(LocalDateTime.now())
                .build());
    }
}
