package com.ecomargin.config;

import com.ecomargin.model.Role;
import com.ecomargin.model.User;
import com.ecomargin.model.Wallet;
import com.ecomargin.model.Transaction;
import com.ecomargin.model.enums.RoleType;
import com.ecomargin.repository.UserRepository;
import com.ecomargin.repository.WalletRepository;
import com.ecomargin.repository.RoleRepository;
import com.ecomargin.repository.TransactionRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Profile;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.util.Collections;

@Slf4j
@Component
@Profile({"dev", "test"})
@RequiredArgsConstructor
public class DatabaseSeeder implements CommandLineRunner {

    private final UserRepository userRepository;
    private final WalletRepository walletRepository;
    private final RoleRepository roleRepository;
    private final TransactionRepository transactionRepository;
    private final PasswordEncoder passwordEncoder;

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
    }
}
