package com.ecomargin.config;

import com.ecomargin.model.Role;
import com.ecomargin.model.User;
import com.ecomargin.model.Wallet;
import com.ecomargin.model.Transaction;
import com.ecomargin.model.Station;
import com.ecomargin.model.Charger;
import com.ecomargin.model.Connector;
import com.ecomargin.model.Vendor;
import com.ecomargin.model.enums.RoleType;
import com.ecomargin.repository.UserRepository;
import com.ecomargin.repository.WalletRepository;
import com.ecomargin.repository.RoleRepository;
import com.ecomargin.repository.TransactionRepository;
import com.ecomargin.repository.StationRepository;
import com.ecomargin.repository.ChargerRepository;
import com.ecomargin.repository.ConnectorRepository;
import com.ecomargin.repository.VendorRepository;
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

    @Override
    public void run(String... args) throws Exception {
        log.info("=== RUNNING APPLICATION STARTUP DATABASE SEEDER ===");
        
        // 1. Seed Customer Role
        Role customerRole = roleRepository.findByName(RoleType.ROLE_CUSTOMER)
                .orElseGet(() -> roleRepository.save(
                        Role.builder().name(RoleType.ROLE_CUSTOMER).permissions(Collections.emptySet()).build()
                ));

        // Seed Vendor Role
        Role vendorRole = roleRepository.findByName(RoleType.ROLE_VENDOR)
                .orElseGet(() -> roleRepository.save(
                        Role.builder().name(RoleType.ROLE_VENDOR).permissions(Collections.emptySet()).build()
                ));

        // 2. Seed User romanshu@gmail.com
        String email = "romanshu@gmail.com";
        User user = userRepository.findByEmailIgnoreCase(email)
                .orElseGet(() -> userRepository.save(
                        User.builder()
                                .email(email)
                                .password(passwordEncoder.encode("password123"))
                                .firstName("Romanshu")
                                .lastName("Sharma")
                                .phoneNumber("+919876543210")
                                .isVerified(true)
                                .isAccountNonLocked(true)
                                .roles(Collections.singleton(customerRole))
                                .build()
                ));

        // Seed default Vendor user and Vendor profile
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
        } else {
            log.info("Startup Seeder: romanshu@gmail.com wallet balance already has ₹100.00 top-up.");
        }

        // 4. Seed Stations
        log.info("Seeding/updating default charging stations, chargers, and connectors...");

        // Station 1: Alwar Charging Hub
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

        // Station 2: Jaipur Fast Charger
        Station jaipurStation = seedStation(
                "Jaipur EV Charging Hub",
                new BigDecimal("26.915000"),
                new BigDecimal("75.792000"),
                "Tonk Road, Sector 62, Jaipur, Rajasthan 302018",
                defaultVendor
        );
        Charger jaipurCharger = seedCharger(jaipurStation, "IN_JAI_01", "ABB Terra 184", "ABB");
        seedConnector(jaipurCharger, 1, "CCS2", BigDecimal.valueOf(180.00));

        // Station 3: Austin Downtown Hub
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

        log.info("Successfully completed station seeding.");
    }

    private Station seedStation(String name, BigDecimal lat, BigDecimal lng, String address, Vendor vendor) {
        if (vendor == null) {
            throw new IllegalStateException("Validation Error: Cannot create station '" + name + "' without a valid Vendor!");
        }
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
