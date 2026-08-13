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
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.util.Collections;

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
    private final org.springframework.jdbc.core.JdbcTemplate jdbcTemplate;

    @Override
    public void run(String... args) throws Exception {
        log.info("=== RUNNING APPLICATION STARTUP DATABASE SEEDER ===");
        
        // 0. Ensure safe schema migration for roles_name_check constraint & jwt_version
        try {
            java.util.List<String> constraints = jdbcTemplate.queryForList(
                "SELECT constraint_name FROM information_schema.constraint_column_usage WHERE LOWER(table_name) = 'roles' AND LOWER(column_name) = 'name'",
                String.class
            );
            for (String constraint : constraints) {
                if (constraint != null && constraint.toLowerCase().contains("check")) {
                    log.info("Dropping check constraint on roles.name: {}", constraint);
                    jdbcTemplate.execute("ALTER TABLE roles DROP CONSTRAINT IF EXISTS " + constraint + ";");
                }
            }
            jdbcTemplate.execute("ALTER TABLE roles DROP CONSTRAINT IF EXISTS roles_name_check;");
        } catch (Exception e) {
            log.warn("Schema migration check for roles constraints drop: {}", e.getMessage());
        }

        try {
            jdbcTemplate.execute("ALTER TABLE roles ADD CONSTRAINT roles_name_check CHECK (name IN ('ROLE_CUSTOMER', 'ROLE_VENDOR', 'ROLE_ADMIN', 'ROLE_SUPER_ADMIN'));");
        } catch (Exception e) {
            log.warn("Schema migration check for roles_name_check add: {}", e.getMessage());
        }

        try {
            jdbcTemplate.execute("ALTER TABLE users ADD COLUMN IF NOT EXISTS jwt_version INT NOT NULL DEFAULT 0;");
        } catch (Exception e) {
            log.warn("Schema migration check for jwt_version: {}", e.getMessage());
        }
        
        // 1. Seed Roles
        Role customerRole = seedRole(RoleType.ROLE_CUSTOMER);
        Role vendorRole = seedRole(RoleType.ROLE_VENDOR);
        Role adminRole = seedRole(RoleType.ROLE_ADMIN);
        Role superAdminRole = seedRole(RoleType.ROLE_SUPER_ADMIN);

        // 2. Seed Users
        // Customer User
        String customerEmail = "romanshu@gmail.com";
        User user = userRepository.findByEmailIgnoreCase(customerEmail)
                .orElseGet(() -> userRepository.save(
                        User.builder()
                                .email(customerEmail)
                                .password(passwordEncoder.encode("password123"))
                                .firstName("Romanshu")
                                .lastName("Sharma")
                                .phoneNumber("+919876543210")
                                .isVerified(true)
                                .isAccountNonLocked(true)
                                .roles(Collections.singleton(customerRole))
                                .build()
                ));

        // Vendor User
        String vendorEmail = "vendor@ecomargin.com";
        User vendorUser = userRepository.findByEmailIgnoreCase(vendorEmail)
                .orElseGet(() -> userRepository.save(
                        User.builder()
                                .email(vendorEmail)
                                .password(passwordEncoder.encode("vendor123"))
                                .firstName("Eco")
                                .lastName("Vendor")
                                .phoneNumber("+918888888888")
                                .isVerified(true)
                                .isAccountNonLocked(true)
                                .roles(Collections.singleton(vendorRole))
                                .build()
                ));

        Vendor defaultVendor = vendorRepository.findByUser(vendorUser)
                .orElseGet(() -> vendorRepository.save(
                        Vendor.builder()
                                .user(vendorUser)
                                .businessName("EcoMargin Default Vendor")
                                .status("ACTIVE")
                                .build()
                ));

        // Admin User
        String adminEmail = "operator@ecomargin.com";
        userRepository.findByEmailIgnoreCase(adminEmail)
                .orElseGet(() -> userRepository.save(
                        User.builder()
                                .email(adminEmail)
                                .password(passwordEncoder.encode("admin123"))
                                .firstName("System")
                                .lastName("Admin")
                                .phoneNumber("+919999999991")
                                .isVerified(true)
                                .isAccountNonLocked(true)
                                .roles(Collections.singleton(adminRole))
                                .build()
                ));

        // Super Admin User
        String superAdminEmail = "admin@ecomargin.com";
        userRepository.findByEmailIgnoreCase(superAdminEmail)
                .orElseGet(() -> userRepository.save(
                        User.builder()
                                .email(superAdminEmail)
                                .password(passwordEncoder.encode("admin123"))
                                .firstName("Super")
                                .lastName("Admin")
                                .phoneNumber("+919999999999")
                                .isVerified(true)
                                .isAccountNonLocked(true)
                                .roles(Collections.singleton(superAdminRole))
                                .build()
                ));

        // 3. Seed Wallet & top up ₹100.00
        Wallet wallet = walletRepository.findByUserId(user.getId())
                .orElseGet(() -> walletRepository.save(
                        Wallet.builder().user(user).balance(BigDecimal.ZERO).currency("INR").build()
                ));

        String referenceId = "TXN-ROMANSHU-TOPUP-100";
        if (transactionRepository.findByReferenceId(referenceId).isEmpty()) {
            BigDecimal amount = new BigDecimal("100.00");
            BigDecimal prevBalance = wallet.getBalance();
            BigDecimal newBalance = prevBalance.add(amount);
            
            wallet.setBalance(newBalance);
            walletRepository.save(wallet);

            Transaction transaction = Transaction.builder()
                    .wallet(wallet)
                    .amount(amount)
                    .type("CREDIT")
                    .status("SUCCESS")
                    .referenceId(referenceId)
                    .referenceType("TOPUP")
                    .balanceBefore(prevBalance)
                    .balanceAfter(newBalance)
                    .build();
            transactionRepository.save(transaction);
            log.info("Startup Seeder: Successfully topped up romanshu@gmail.com with ₹100.00");
        }

        // 4. Seed Default Settings
        seedSetting("min_wallet_balance_to_start", "50.00", "Minimum wallet balance required to initiate charging");
        seedSetting("default_charging_rate_per_kwh", "15.00", "Default per kWh charging price in INR");
        seedSetting("home_sections", "{\"hero_slider\": true, \"quick_actions\": true, \"wallet_card\": true, \"nearby_stations\": true, \"promo_banner\": true, \"search_section\": true}", "Home screen section visibility configuration");
        seedSetting("support_info", "{\"phone\": \"1800-123-4567\", \"email\": \"support@ecomargin.com\", \"hours\": \"24/7 Helpline\"}", "Support helpline contact information");
        seedSetting("app_maintenance", "{\"enabled\": false, \"message\": \"EcoMargin is currently undergoing scheduled maintenance. Please check back shortly.\"}", "Global app maintenance flag");
        seedSetting("charging_session_rules", "{\"max_duration_hours\": 12, \"idle_fee_per_min\": 2.0, \"auto_stop_target_pct\": 100}", "Charging session operational parameters");
        seedSetting("faqs", "[{\"q\": \"How do I start an EV charging session?\", \"a\": \"Simply find a nearby charger on the map, select the connector details, set your target battery limit, and tap Start Charging.\"}, {\"q\": \"How does EcoMargin Wallet billing work?\", \"a\": \"Your wallet balance is automatically debited based on the exact kWh energy consumed at the end of every charging session.\"}, {\"q\": \"What connector types are supported?\", \"a\": \"EcoMargin supports DC Fast Chargers (CCS2, GB/T, CHAdeMO) and AC Chargers (Type 2).\"}]", "Customer FAQs list");
        seedSetting("offers_banners", "[{\"code\": \"ECOGREEN20\", \"title\": \"20% Cashback on First Charging Session\", \"desc\": \"Get up to ₹100 cashback credited into your EcoMargin Wallet.\", \"expiry\": \"Valid till 31 Aug 2026\"}, {\"code\": \"FASTCHARGE50\", \"title\": \"Flat ₹50 OFF on DC Fast Chargers\", \"desc\": \"Applicable on session power > 50 kW.\", \"expiry\": \"Valid till 15 Aug 2026\"}]", "Active promotional offers & coupons");

        // 5. Seed Stations
        log.info("Seeding default charging stations, chargers, and connectors...");

        Station alwarStation = seedStation(
                "Alwar Charging Hub",
                new BigDecimal("27.568400"),
                new BigDecimal("76.626400"),
                "Dholidub, Near Ram Mandir, Alwar, Rajasthan 301001",
                defaultVendor
        );
        Charger alwarCharger = seedCharger(alwarStation, "IN_ALW_01", "Tritium RT50", "Tritium");
        seedConnector(alwarCharger, 1, "CCS2", BigDecimal.valueOf(50.00));
        seedConnector(alwarCharger, 2, "CHADEMO", BigDecimal.valueOf(50.00));

        Station jaipurStation = seedStation(
                "Jaipur EV Charging Hub",
                new BigDecimal("26.915000"),
                new BigDecimal("75.792000"),
                "Tonk Road, Sector 62, Jaipur, Rajasthan 302018",
                defaultVendor
        );
        Charger jaipurCharger = seedCharger(jaipurStation, "IN_JAI_01", "ABB Terra 184", "ABB");
        seedConnector(jaipurCharger, 1, "CCS2", BigDecimal.valueOf(180.00));

        Station austinStation = seedStation(
                "Austin Downtown Hub",
                new BigDecimal("30.267153"),
                new BigDecimal("-97.743062"),
                "120 E 6th St, Austin, TX 78701",
                defaultVendor
        );
        Charger austinCharger = seedCharger(austinStation, "TX_AUS_DWTN_01", "ABB Terra 184", "ABB");
        seedConnector(austinCharger, 1, "CCS2", BigDecimal.valueOf(180.00));
        seedConnector(austinCharger, 2, "CCS2", BigDecimal.valueOf(180.00));

        log.info("Successfully completed database seeding.");
    }

    private Role seedRole(RoleType name) {
        return roleRepository.findByName(name)
                .orElseGet(() -> {
                    try {
                        return roleRepository.save(
                                Role.builder().name(name).permissions(Collections.emptySet()).build()
                        );
                    } catch (Exception e) {
                        log.warn("Role seeding fallback for {}: {}", name, e.getMessage());
                        return roleRepository.findByName(name).orElse(null);
                    }
                });
    }

    private void seedSetting(String key, String val, String desc) {
        if (settingRepository.findById(key).isEmpty()) {
            settingRepository.save(Setting.builder()
                    .key(key)
                    .value(val)
                    .description(desc)
                    .build());
        }
    }

    private Station seedStation(String name, BigDecimal lat, BigDecimal lng, String address, Vendor vendor) {
        return stationRepository.findByName(name)
                .orElseGet(() -> stationRepository.save(Station.builder()
                        .name(name)
                        .latitude(lat)
                        .longitude(lng)
                        .address(address)
                        .status("ACTIVE")
                        .vendor(vendor)
                        .build()));
    }

    private Charger seedCharger(Station station, String ocppId, String model, String brand) {
        return chargerRepository.findByOcppId(ocppId)
                .orElseGet(() -> chargerRepository.save(Charger.builder()
                        .station(station)
                        .ocppId(ocppId)
                        .model(model)
                        .brand(brand)
                        .status("AVAILABLE")
                        .build()));
    }

    private void seedConnector(Charger charger, int index, String type, BigDecimal maxPower) {
        connectorRepository.findByChargerAndConnectorIndex(charger, index)
                .orElseGet(() -> connectorRepository.save(Connector.builder()
                        .charger(charger)
                        .connectorIndex(index)
                        .type(type)
                        .status("AVAILABLE")
                        .maxPowerKw(maxPower)
                        .build()));
    }
}
