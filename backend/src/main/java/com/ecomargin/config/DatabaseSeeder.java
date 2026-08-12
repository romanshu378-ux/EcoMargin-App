package com.ecomargin.config;
 
import com.ecomargin.model.Role;
import com.ecomargin.model.User;
import com.ecomargin.model.Wallet;
import com.ecomargin.model.Transaction;
import com.ecomargin.model.Station;
import com.ecomargin.model.Charger;
import com.ecomargin.model.Connector;
import com.ecomargin.model.enums.RoleType;
import com.ecomargin.repository.UserRepository;
import com.ecomargin.repository.WalletRepository;
import com.ecomargin.repository.RoleRepository;
import com.ecomargin.repository.TransactionRepository;
import com.ecomargin.repository.StationRepository;
import com.ecomargin.repository.ChargerRepository;
import com.ecomargin.repository.ConnectorRepository;
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
 
    @Override
    public void run(String... args) throws Exception {
        log.info("=== RUNNING APPLICATION STARTUP DATABASE SEEDER ===");
        
        // 1. Seed Customer Role
        Role customerRole = roleRepository.findByName(RoleType.ROLE_CUSTOMER)
                .orElseGet(() -> roleRepository.save(
                        Role.builder().name(RoleType.ROLE_CUSTOMER).permissions(Collections.emptySet()).build()
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
 
        // 4. Seed Stations if none exist
        if (stationRepository.count() == 0) {
            log.info("Seeding default charging stations, chargers, and connectors...");
            
            // Station 1: Alwar Charging Hub
            Station alwarStation = stationRepository.save(Station.builder()
                    .name("Alwar Charging Hub")
                    .latitude(new BigDecimal("27.568400"))
                    .longitude(new BigDecimal("76.626400"))
                    .address("Dholidub, Near Ram Mandir, Alwar, Rajasthan 301001")
                    .status("ACTIVE")
                    .build());
                    
            Charger alwarCharger = chargerRepository.save(Charger.builder()
                    .station(alwarStation)
                    .ocppId("IN_ALW_01")
                    .model("Tritium RT50")
                    .brand("Tritium")
                    .status("AVAILABLE")
                    .build());
                    
            connectorRepository.save(Connector.builder()
                    .charger(alwarCharger)
                    .connectorIndex(1)
                    .type("CCS2")
                    .status("AVAILABLE")
                    .maxPowerKw(BigDecimal.valueOf(50.00))
                    .build());
            connectorRepository.save(Connector.builder()
                    .charger(alwarCharger)
                    .connectorIndex(2)
                    .type("CHADEMO")
                    .status("AVAILABLE")
                    .maxPowerKw(BigDecimal.valueOf(50.00))
                    .build());
 
            // Station 2: Jaipur Fast Charger
            Station jaipurStation = stationRepository.save(Station.builder()
                    .name("Jaipur EV Charging Hub")
                    .latitude(new BigDecimal("26.915000"))
                    .longitude(new BigDecimal("75.792000"))
                    .address("Tonk Road, Sector 62, Jaipur, Rajasthan 302018")
                    .status("ACTIVE")
                    .build());
                    
            Charger jaipurCharger = chargerRepository.save(Charger.builder()
                    .station(jaipurStation)
                    .ocppId("IN_JAI_01")
                    .model("ABB Terra 184")
                    .brand("ABB")
                    .status("AVAILABLE")
                    .build());
                    
            connectorRepository.save(Connector.builder()
                    .charger(jaipurCharger)
                    .connectorIndex(1)
                    .type("CCS2")
                    .status("AVAILABLE")
                    .maxPowerKw(BigDecimal.valueOf(180.00))
                    .build());
 
            // Station 3: Austin Downtown Hub
            Station austinStation = stationRepository.save(Station.builder()
                    .name("Austin Downtown Hub")
                    .latitude(new BigDecimal("30.267153"))
                    .longitude(new BigDecimal("-97.743062"))
                    .address("120 E 6th St, Austin, TX 78701")
                    .status("ACTIVE")
                    .build());
                    
            Charger austinCharger = chargerRepository.save(Charger.builder()
                    .station(austinStation)
                    .ocppId("TX_AUS_DWTN_01")
                    .model("ABB Terra 184")
                    .brand("ABB")
                    .status("AVAILABLE")
                    .build());
                    
            connectorRepository.save(Connector.builder()
                    .charger(austinCharger)
                    .connectorIndex(1)
                    .type("CCS2")
                    .status("AVAILABLE")
                    .maxPowerKw(BigDecimal.valueOf(180.00))
                    .build());
            connectorRepository.save(Connector.builder()
                    .charger(austinCharger)
                    .connectorIndex(2)
                    .type("CCS2")
                    .status("AVAILABLE")
                    .maxPowerKw(BigDecimal.valueOf(180.00))
                    .build());
            
            log.info("Successfully seeded default charging stations, chargers, and connectors.");
        }
    }
}
