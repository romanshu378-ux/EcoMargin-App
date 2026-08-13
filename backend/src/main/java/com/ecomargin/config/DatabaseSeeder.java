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

import java.math.BigDecimal;
import java.util.Collections;
import java.util.Optional;
import java.util.Set;

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

    @Override
    public void run(String... args) {
        log.info("=== DATABASE CONNECTED ===");
        log.info("=== RUNNING APPLICATION STARTUP DATABASE SEEDER ===");
        
        try {
            // 1. Seed Roles (Idempotent: checks existing, creates missing, never deletes or drops)
            seedRoles();
        } catch (Exception e) {
            log.error("Error during roles seeding: {}", e.getMessage(), e);
        }

        try {
            // 2. Seed Users conditionally using double-lookup (email & phone_number)
            if (seedDemoUser) {
                seedDemoUsers();
            } else {
                log.info("Demo user seeding is DISABLED (app.seed.demo-user=false). Preserving existing database users.");
            }
        } catch (Exception e) {
            log.error("Error during users seeding: {}", e.getMessage(), e);
        }

        try {
            // 3. Seed Default Settings (Idempotent: checks key, never overwrites or deletes existing settings)
            seedDefaultSettings();
        } catch (Exception e) {
            log.error("Error during settings seeding: {}", e.getMessage(), e);
        }

        try {
            // 4. Seed Stations
            seedDefaultStations();
        } catch (Exception e) {
            log.error("Error during stations seeding: {}", e.getMessage(), e);
        }

        log.info("=== SEEDER COMPLETED ===");
        log.info("=== SERVER STARTED ===");
    }

    private void seedRoles() {
        seedRole(RoleType.ROLE_CUSTOMER);
        seedRole(RoleType.ROLE_VENDOR);
        seedRole(RoleType.ROLE_ADMIN);
        seedRole(RoleType.ROLE_SUPER_ADMIN);
    }

    private void seedDemoUsers() {
        log.info("Demo user seeding is ENABLED (app.seed.demo-user=true)");
        Role customerRole = roleRepository.findByName(RoleType.ROLE_CUSTOMER).orElse(null);
        Role vendorRole = roleRepository.findByName(RoleType.ROLE_VENDOR).orElse(null);
        Role adminRole = roleRepository.findByName(RoleType.ROLE_ADMIN).orElse(null);
        Role superAdminRole = roleRepository.findByName(RoleType.ROLE_SUPER_ADMIN).orElse(null);

        User customerUser = seedUser("romanshu@gmail.com", "password123", "Romanshu", "Sharma", "+919876543210", 
                customerRole != null ? Collections.singleton(customerRole) : Collections.emptySet());
        User vendorUser = seedUser("vendor@ecomargin.com", "vendor123", "Eco", "Vendor", "+918888888888", 
                vendorRole != null ? Collections.singleton(vendorRole) : Collections.emptySet());
        User adminUser = seedUser("operator@ecomargin.com", "admin123", "System", "Admin", "+919999999991", 
                adminRole != null ? Collections.singleton(adminRole) : Collections.emptySet());
        User superAdminUser = seedUser("admin@ecomargin.com", "admin123", "Super", "Admin", "+919999999999", 
                superAdminRole != null ? Collections.singleton(superAdminRole) : Collections.emptySet());

        if (customerUser != null) {
            Wallet wallet = walletRepository.findByUserId(customerUser.getId())
                    .orElseGet(() -> walletRepository.save(
                            Wallet.builder().user(customerUser).balance(BigDecimal.ZERO).currency("INR").build()
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

    private void seedDefaultSettings() {
        seedSetting("min_wallet_balance_to_start", "50.00", "Minimum wallet balance required to initiate charging");
        seedSetting("default_charging_rate_per_kwh", "15.00", "Default per kWh charging price in INR");
        seedSetting("home_sections", "{\"hero_slider\": true, \"quick_actions\": true, \"wallet_card\": true, \"nearby_stations\": true, \"promo_banner\": true, \"search_section\": true}", "Home screen section visibility configuration");
        seedSetting("support_info", "{\"phone\": \"1800-123-4567\", \"email\": \"support@ecomargin.com\", \"hours\": \"24/7 Helpline\"}", "Support helpline contact information");
        seedSetting("app_maintenance", "{\"enabled\": false, \"message\": \"EcoMargin is currently undergoing scheduled maintenance. Please check back shortly.\"}", "Global app maintenance flag");
        seedSetting("charging_session_rules", "{\"max_duration_hours\": 12, \"idle_fee_per_min\": 2.0, \"auto_stop_target_pct\": 100}", "Charging session operational parameters");
        seedSetting("faqs", "[{\"q\": \"How do I start an EV charging session?\", \"a\": \"Simply find a nearby charger on the map, select the connector details, set your target battery limit, and tap Start Charging.\"}, {\"q\": \"How does EcoMargin Wallet billing work?\", \"a\": \"Your wallet balance is automatically debited based on the exact kWh energy consumed at the end of every charging session.\"}, {\"q\": \"What connector types are supported?\", \"a\": \"EcoMargin supports DC Fast Chargers (CCS2, GB/T, CHAdeMO) and AC Chargers (Type 2).\"}]", "Customer FAQs list");
        seedSetting("offers_banners", "[{\"code\": \"ECOGREEN20\", \"title\": \"20% Cashback on First Charging Session\", \"desc\": \"Get up to ₹100 cashback credited into your EcoMargin Wallet.\", \"expiry\": \"Valid till 31 Aug 2026\"}, {\"code\": \"FASTCHARGE50\", \"title\": \"Flat ₹50 OFF on DC Fast Chargers\", \"desc\": \"Applicable on session power > 50 kW.\", \"expiry\": \"Valid till 15 Aug 2026\"}]", "Active promotional offers & coupons");
    }

    private void seedDefaultStations() {
        Vendor defaultVendor = vendorRepository.findAll().stream().findFirst().orElse(null);
        if (defaultVendor != null) {
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
        }
    }

    private User seedUser(String email, String rawPassword, String firstName, String lastName, String phoneNumber, Set<Role> roles) {
        String cleanEmail = email.trim().toLowerCase();
        String cleanPhone = (phoneNumber != null && !phoneNumber.isBlank()) ? phoneNumber.trim() : null;

        // 1. Check by email
        Optional<User> byEmail = userRepository.findByEmailIgnoreCase(cleanEmail);
        if (byEmail.isPresent()) {
            return byEmail.get();
        }

        // 2. Check by phone number
        if (cleanPhone != null) {
            Optional<User> byPhone = userRepository.findByPhoneNumber(cleanPhone);
            if (byPhone.isPresent()) {
                return byPhone.get();
            }
        }

        // 3. Create missing seed user
        try {
            User newUser = User.builder()
                    .email(cleanEmail)
                    .password(passwordEncoder.encode(rawPassword))
                    .firstName(firstName)
                    .lastName(lastName)
                    .phoneNumber(cleanPhone)
                    .isVerified(true)
                    .isAccountNonLocked(true)
                    .roles(roles)
                    .jwtVersion(0)
                    .build();
            return userRepository.save(newUser);
        } catch (Exception e) {
            log.warn("Seed user creation skipped for email {} / phone {}: {}", cleanEmail, cleanPhone, e.getMessage());
            return userRepository.findByEmailIgnoreCase(cleanEmail)
                    .or(() -> cleanPhone != null ? userRepository.findByPhoneNumber(cleanPhone) : Optional.empty())
                    .orElse(null);
        }
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
        if (key == null || key.isBlank()) {
            log.warn("Skipping seedSetting with null or blank key");
            return;
        }
        try {
            Optional<Setting> existing = settingRepository.findById(key);
            if (existing.isEmpty()) {
                Setting setting = Setting.builder()
                        .key(key)
                        .value(val)
                        .description(desc)
                        .updatedAt(java.time.LocalDateTime.now())
                        .build();
                settingRepository.save(setting);
                log.info("Seeded default setting: key='{}'", key);
            } else {
                log.debug("Setting key='{}' already exists. Preserving existing value.", key);
            }
        } catch (Exception e) {
            log.error("Failed to seed setting key='{}': {}", key, e.getMessage(), e);
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
