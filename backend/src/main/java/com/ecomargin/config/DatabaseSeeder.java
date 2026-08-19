package com.ecomargin.config;

import com.ecomargin.model.Role;
import com.ecomargin.model.User;
import com.ecomargin.model.Wallet;
import com.ecomargin.model.Transaction;
import com.ecomargin.model.Station;
import com.ecomargin.model.Charger;
import com.ecomargin.model.Connector;
import com.ecomargin.model.Vendor;
import com.ecomargin.model.Setting;
import com.ecomargin.model.enums.RoleType;
import com.ecomargin.repository.UserRepository;
import com.ecomargin.repository.WalletRepository;
import com.ecomargin.repository.RoleRepository;
import com.ecomargin.repository.TransactionRepository;
import com.ecomargin.repository.StationRepository;
import com.ecomargin.repository.ChargerRepository;
import com.ecomargin.repository.ConnectorRepository;
import com.ecomargin.repository.VendorRepository;
import com.ecomargin.repository.SettingRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.function.Function;
import java.util.stream.Collectors;

@Slf4j
@Component
@RequiredArgsConstructor
public class DatabaseSeeder implements CommandLineRunner {

    private final UserRepository userRepository;
    private final WalletRepository walletRepository;
    private final RoleRepository roleRepository;
    private final TransactionRepository transactionRepository;
    private final PasswordEncoder passwordEncoder;
    private final StationRepository stationRepository;
    private final ChargerRepository chargerRepository;
    private final ConnectorRepository connectorRepository;
    private final VendorRepository vendorRepository;
    private final SettingRepository settingRepository;

    @Value("${app.seed.demo-user:false}")
    private boolean seedDemoUser;

    public static final List<String> REQUIRED_SETTINGS = List.of(
            "min_wallet_balance_to_start",
            "default_charging_rate_per_kwh",
            "home_sections",
            "support_info",
            "app_maintenance",
            "charging_session_rules",
            "faqs",
            "offers_banners"
    );

    @Override
    @Transactional
    public void run(String... args) {
        log.info("=== DATABASE CONNECTED ===");
        log.info("=== RUNNING APPLICATION STARTUP DATABASE SEEDER ===");

        // 1. Seed Roles
        try {
            seedRoles();
        } catch (Exception e) {
            log.error("[SEEDER FATAL] Roles seeding failed: {}", e.getMessage(), e);
            throw new IllegalStateException("Application startup failed during role seeding: " + e.getMessage(), e);
        }

        // 2. Seed Demo Users (conditional)
        try {
            if (seedDemoUser) {
                seedDemoUsers();
            } else {
                log.info("[SEEDER] Demo user seeding is DISABLED (app.seed.demo-user=false). Preserving existing database users.");
            }
        } catch (Exception e) {
            log.error("[SEEDER] Non-fatal error during demo user seeding: {}", e.getMessage(), e);
        }

        // 3. Seed Default Settings (Idempotent — never overwrites existing production settings)
        Map<String, Setting> settingsMap;
        try {
            settingsMap = seedDefaultSettings();
        } catch (Exception e) {
            log.error("[SEEDER FATAL] Settings seeding failed: {}", e.getMessage(), e);
            throw new IllegalStateException("Application startup failed during settings seeding: " + e.getMessage(), e);
        }

        // 4. Seed Stations
        try {
            seedDefaultStations();
        } catch (Exception e) {
            log.error("[SEEDER] Non-fatal error during station seeding: {}", e.getMessage(), e);
        }

        // 5. Mandatory Startup Validation — Fail startup if any of the 8 required settings are missing
        validateRequiredSettings(settingsMap);

        log.info("=== SEEDER STATUS: SUCCESS ===");
        log.info("=== ALL 8 REQUIRED SETTINGS VERIFIED IN DATABASE ===");
        log.info("=== SERVER STARTED ===");
    }

    // -------------------------------------------------------------------------
    // Roles
    // -------------------------------------------------------------------------

    private void seedRoles() {
        seedRole(RoleType.ROLE_CUSTOMER);
        seedRole(RoleType.ROLE_VENDOR);
        seedRole(RoleType.ROLE_ADMIN);
        seedRole(RoleType.ROLE_SUPER_ADMIN);
    }

    private Role seedRole(RoleType name) {
        return roleRepository.findByName(name)
                .orElseGet(() -> roleRepository.save(
                        Role.builder().name(name).permissions(Collections.emptySet()).build()
                ));
    }

    // -------------------------------------------------------------------------
    // Demo Users
    // -------------------------------------------------------------------------

    private void seedDemoUsers() {
        log.info("[SEEDER] Demo user seeding is ENABLED (app.seed.demo-user=true)");
        Role customerRole   = roleRepository.findByName(RoleType.ROLE_CUSTOMER).orElse(null);
        Role vendorRole     = roleRepository.findByName(RoleType.ROLE_VENDOR).orElse(null);
        Role adminRole      = roleRepository.findByName(RoleType.ROLE_ADMIN).orElse(null);
        Role superAdminRole = roleRepository.findByName(RoleType.ROLE_SUPER_ADMIN).orElse(null);

        User customerUser = seedUser("romanshu@gmail.com", "password123", "Romanshu", "Sharma", "+919876543210",
                customerRole  != null ? Collections.singleton(customerRole)  : Collections.emptySet());
        User vendorUser   = seedUser("vendor@ecomargin.com", "vendor123", "Eco", "Vendor", "+918888888888",
                vendorRole    != null ? Collections.singleton(vendorRole)    : Collections.emptySet());
        seedUser("operator@ecomargin.com", "admin123", "System", "Admin", "+919999999991",
                adminRole     != null ? Collections.singleton(adminRole)     : Collections.emptySet());
        User adminUser = seedUser("admin@ecomargin.com", "admin123", "Super", "Admin", "+919999999999",
                superAdminRole != null ? Collections.singleton(superAdminRole) : Collections.emptySet());

        if (adminUser != null && !passwordEncoder.matches("admin123", adminUser.getPassword())) {
            log.info("[SEEDER] Syncing admin@ecomargin.com password hash to match admin123");
            adminUser.setPassword(passwordEncoder.encode("admin123"));
            userRepository.save(adminUser);
        }

        if (customerUser != null) {
            Wallet wallet = walletRepository.findByUserId(customerUser.getId())
                    .orElseGet(() -> walletRepository.save(
                            Wallet.builder().user(customerUser).balance(BigDecimal.ZERO).currency("INR").build()
                    ));

            String referenceId = "TXN-ROMANSHU-TOPUP-100";
            if (transactionRepository.findByReferenceId(referenceId).isEmpty()) {
                BigDecimal amount      = new BigDecimal("100.00");
                BigDecimal prevBalance = wallet.getBalance();
                BigDecimal newBalance  = prevBalance.add(amount);

                wallet.setBalance(newBalance);
                walletRepository.save(wallet);

                transactionRepository.save(Transaction.builder()
                        .wallet(wallet)
                        .amount(amount)
                        .type("CREDIT")
                        .status("SUCCESS")
                        .referenceId(referenceId)
                        .referenceType("TOPUP")
                        .balanceBefore(prevBalance)
                        .balanceAfter(newBalance)
                        .build());
            }
        }

        if (vendorUser != null) {
            vendorRepository.findByUser(vendorUser)
                    .orElseGet(() -> vendorRepository.save(
                            Vendor.builder()
                                    .user(vendorUser)
                                    .businessName("EcoMargin Default Vendor")
                                    .status("ACTIVE")
                                    .build()
                    ));
        }
    }

    private User seedUser(String email, String rawPassword, String firstName, String lastName,
                          String phoneNumber, Set<Role> roles) {
        String cleanEmail = email.trim().toLowerCase();
        String cleanPhone = (phoneNumber != null && !phoneNumber.isBlank()) ? phoneNumber.trim() : null;

        Optional<User> byEmail = userRepository.findByEmailIgnoreCase(cleanEmail);
        if (byEmail.isPresent()) return byEmail.get();

        if (cleanPhone != null) {
            Optional<User> byPhone = userRepository.findByPhoneNumber(cleanPhone);
            if (byPhone.isPresent()) return byPhone.get();
        }

        try {
            return userRepository.save(User.builder()
                    .email(cleanEmail)
                    .password(passwordEncoder.encode(rawPassword))
                    .firstName(firstName)
                    .lastName(lastName)
                    .phoneNumber(cleanPhone)
                    .isVerified(true)
                    .isAccountNonLocked(true)
                    .roles(roles)
                    .jwtVersion(0)
                    .build());
        } catch (Exception e) {
            log.warn("[SEEDER] Seed user creation skipped for email {} / phone {}: {}", cleanEmail, cleanPhone, e.getMessage());
            return userRepository.findByEmailIgnoreCase(cleanEmail)
                    .or(() -> cleanPhone != null ? userRepository.findByPhoneNumber(cleanPhone) : Optional.empty())
                    .orElse(null);
        }
    }

    // -------------------------------------------------------------------------
    // Settings — Idempotent, never overwrites existing production values
    // Throws exception if required settings cannot be created
    // -------------------------------------------------------------------------

    private Map<String, Setting> seedDefaultSettings() {
        Map<String, Setting> existingMap = settingRepository.findAllById(REQUIRED_SETTINGS)
                .stream()
                .filter(s -> s.getKey() != null)
                .collect(Collectors.toMap(Setting::getKey, Function.identity(), (s1, s2) -> s1));

        seedSettingIfMissing(existingMap, "min_wallet_balance_to_start", "50.00",
                "Minimum wallet balance required to initiate charging");
        seedSettingIfMissing(existingMap, "default_charging_rate_per_kwh", "15.00",
                "Default per kWh charging price in INR");
        seedSettingIfMissing(existingMap, "home_sections",
                "{\"hero_slider\": true, \"quick_actions\": true, \"wallet_card\": true, \"nearby_stations\": true, \"promo_banner\": true, \"search_section\": true}",
                "Home screen section visibility configuration");
        seedSettingIfMissing(existingMap, "support_info",
                "{\"phone\": \"1800-123-4567\", \"email\": \"support@ecomargin.com\", \"hours\": \"24/7 Helpline\"}",
                "Support helpline contact information");
        seedSettingIfMissing(existingMap, "app_maintenance",
                "{\"enabled\": false, \"message\": \"EcoMargin is currently undergoing scheduled maintenance. Please check back shortly.\"}",
                "Global app maintenance flag");
        seedSettingIfMissing(existingMap, "charging_session_rules",
                "{\"max_duration_hours\": 12, \"idle_fee_per_min\": 2.0, \"auto_stop_target_pct\": 100}",
                "Charging session operational parameters");
        seedSettingIfMissing(existingMap, "faqs",
                "[{\"q\": \"How do I start an EV charging session?\", \"a\": \"Simply find a nearby charger on the map, select the connector details, set your target battery limit, and tap Start Charging.\"}, {\"q\": \"How does EcoMargin Wallet billing work?\", \"a\": \"Your wallet balance is automatically debited based on the exact kWh energy consumed at the end of every charging session.\"}, {\"q\": \"What connector types are supported?\", \"a\": \"EcoMargin supports DC Fast Chargers (CCS2, GB/T, CHAdeMO) and AC Chargers (Type 2).\"}]",
                "Customer FAQs list");
        seedSettingIfMissing(existingMap, "offers_banners",
                "[{\"code\": \"ECOGREEN20\", \"title\": \"20% Cashback on First Charging Session\", \"desc\": \"Get up to ₹100 cashback credited into your EcoMargin Wallet.\", \"expiry\": \"Valid till 31 Aug 2026\"}, {\"code\": \"FASTCHARGE50\", \"title\": \"Flat ₹50 OFF on DC Fast Chargers\", \"desc\": \"Applicable on session power > 50 kW.\", \"expiry\": \"Valid till 15 Aug 2026\"}]",
                "Active promotional offers & coupons");

        return existingMap;
    }

    /**
     * Inserts a single default setting only if it does not already exist in the provided map.
     * Preserves existing production setting values. Never uses null setting_key.
     * Throws IllegalStateException if setting fails to insert.
     */
    private void seedSettingIfMissing(Map<String, Setting> settingsMap, String key, String val, String desc) {
        if (key == null || key.isBlank()) {
            throw new IllegalArgumentException("Cannot seed setting with null or blank setting_key");
        }
        if (val == null) {
            throw new IllegalArgumentException("Cannot seed setting key='" + key + "' with null value");
        }
        try {
            if (!settingsMap.containsKey(key)) {
                Setting setting = Setting.builder()
                        .key(key)            // written to column setting_key per entity mapping
                        .value(val)
                        .description(desc)
                        .updatedAt(LocalDateTime.now())
                        .build();
                Setting saved = settingRepository.save(setting);
                settingsMap.put(key, saved);
                log.info("[SEEDER] Inserted default setting: setting_key='{}'", key);
            } else {
                log.debug("[SEEDER] Setting setting_key='{}' already exists — preserving existing value.", key);
            }
        } catch (Exception e) {
            log.error("[SEEDER FATAL] Failed to seed setting_key='{}': {}", key, e.getMessage(), e);
            throw new IllegalStateException("Failed to seed required setting setting_key='" + key + "': " + e.getMessage(), e);
        }
    }

    /**
     * Validates that all 8 required settings exist in the in-memory map or database.
     * Throws IllegalStateException to halt application startup if any setting is missing.
     */
    public void validateRequiredSettings(Map<String, Setting> settingsMap) {
        List<String> missingKeys = new ArrayList<>();

        for (String reqKey : REQUIRED_SETTINGS) {
            Setting setting = (settingsMap != null) ? settingsMap.get(reqKey) : settingRepository.findById(reqKey).orElse(null);
            if (setting == null || setting.getKey() == null || setting.getValue() == null) {
                missingKeys.add(reqKey);
                log.error("[FATAL STARTUP ERROR] Required setting_key='{}' is missing or invalid in database!", reqKey);
            }
        }

        if (!missingKeys.isEmpty()) {
            String errorMsg = "Application startup failed! Required application settings are missing from database: " + missingKeys;
            log.error("[FATAL STARTUP ERROR] {}", errorMsg);
            throw new IllegalStateException(errorMsg);
        }
    }

    public void validateRequiredSettings() {
        Map<String, Setting> map = settingRepository.findAllById(REQUIRED_SETTINGS)
                .stream()
                .filter(s -> s.getKey() != null)
                .collect(Collectors.toMap(Setting::getKey, Function.identity(), (s1, s2) -> s1));
        validateRequiredSettings(map);
    }

    // -------------------------------------------------------------------------
    // Stations / Chargers / Connectors
    // -------------------------------------------------------------------------

    private void seedDefaultStations() {
        Vendor defaultVendor = vendorRepository.findAll().stream().findFirst().orElse(null);
        if (defaultVendor != null) {
            Station alwarStation = seedStation(
                    "Alwar Charging Hub",
                    new BigDecimal("27.568400"), new BigDecimal("76.626400"),
                    "Dholidub, Near Ram Mandir, Alwar, Rajasthan 301001",
                    "Alwar", "Rajasthan", "India", defaultVendor);
            Charger alwarCharger = seedCharger(alwarStation, "IN_ALW_01", "Tritium RT50", "Tritium");
            seedConnector(alwarCharger, 1, "CCS2",    BigDecimal.valueOf(50.00));
            seedConnector(alwarCharger, 2, "CHADEMO", BigDecimal.valueOf(50.00));

            Station jaipurStation = seedStation(
                    "Jaipur EV Charging Hub",
                    new BigDecimal("26.915000"), new BigDecimal("75.792000"),
                    "Tonk Road, Sector 62, Jaipur, Rajasthan 302018",
                    "Jaipur", "Rajasthan", "India", defaultVendor);
            Charger jaipurCharger = seedCharger(jaipurStation, "IN_JAI_01", "ABB Terra 184", "ABB");
            seedConnector(jaipurCharger, 1, "CCS2", BigDecimal.valueOf(180.00));

            Station austinStation = seedStation(
                    "Austin Downtown Hub",
                    new BigDecimal("30.267153"), new BigDecimal("-97.743062"),
                    "120 E 6th St, Austin, TX 78701",
                    "Austin", "Texas", "USA", defaultVendor);
            Charger austinCharger = seedCharger(austinStation, "TX_AUS_DWTN_01", "ABB Terra 184", "ABB");
            seedConnector(austinCharger, 1, "CCS2", BigDecimal.valueOf(180.00));
            seedConnector(austinCharger, 2, "CCS2", BigDecimal.valueOf(180.00));
        }
    }

    private Station seedStation(String name, BigDecimal lat, BigDecimal lng, String address, String city, String state, String country, Vendor vendor) {
        return stationRepository.findByName(name)
                .orElseGet(() -> stationRepository.save(Station.builder()
                        .name(name).latitude(lat).longitude(lng)
                        .address(address).city(city).state(state).country(country).status("ACTIVE").vendor(vendor)
                        .build()));
    }

    private Charger seedCharger(Station station, String ocppId, String model, String brand) {
        return chargerRepository.findByOcppId(ocppId)
                .orElseGet(() -> chargerRepository.save(Charger.builder()
                        .station(station).ocppId(ocppId).model(model)
                        .brand(brand).status("AVAILABLE")
                        .build()));
    }

    private void seedConnector(Charger charger, int index, String type, BigDecimal maxPower) {
        connectorRepository.findByChargerAndConnectorIndex(charger, index)
                .orElseGet(() -> connectorRepository.save(Connector.builder()
                        .charger(charger).connectorIndex(index).type(type)
                        .status("AVAILABLE").maxPowerKw(maxPower)
                        .build()));
    }
}
