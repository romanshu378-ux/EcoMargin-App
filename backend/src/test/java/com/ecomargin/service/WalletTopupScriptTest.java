package com.ecomargin.service;

import com.ecomargin.model.Role;
import com.ecomargin.model.Transaction;
import com.ecomargin.model.User;
import com.ecomargin.model.Wallet;
import com.ecomargin.model.enums.RoleType;
import com.ecomargin.repository.UserRepository;
import com.ecomargin.repository.WalletRepository;
import com.ecomargin.repository.TransactionRepository;
import com.ecomargin.repository.RoleRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import java.math.BigDecimal;
import java.util.Collections;
import java.util.Optional;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("dev")
public class WalletTopupScriptTest {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private WalletRepository walletRepository;

    @Autowired
    private TransactionRepository transactionRepository;

    @Autowired
    private RoleRepository roleRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private MockMvc mockMvc;

    @Test
    public void executeTopupAndVerify() throws Exception {
        System.out.println("=== STARTING WALLET TOP-UP SCRIPT ===");
        
        // 1. Ensure ROLE_CUSTOMER exists
        Role customerRole = roleRepository.findByName(RoleType.ROLE_CUSTOMER)
                .orElseGet(() -> {
                    Role r = Role.builder()
                            .name(RoleType.ROLE_CUSTOMER)
                            .permissions(Collections.emptySet())
                            .build();
                    return roleRepository.save(r);
                });

        // 2. Ensure User exists
        String email = "romanshu@gmail.com";
        Optional<User> userOpt = userRepository.findByEmailIgnoreCase(email);
        User user;
        if (userOpt.isEmpty()) {
            System.out.println("[INFO] Seeding user: " + email);
            User u = User.builder()
                    .email(email)
                    .password(passwordEncoder.encode("password123"))
                    .firstName("Romanshu")
                    .lastName("Sharma")
                    .phoneNumber("+919876543210")
                    .isVerified(true)
                    .isAccountNonLocked(true)
                    .roles(Collections.singleton(customerRole))
                    .build();
            user = userRepository.save(u);
        } else {
            user = userOpt.get();
            // Re-hash password to ensure it matches
            user.setPassword(passwordEncoder.encode("password123"));
            userRepository.save(user);
        }

        // 3. Ensure Wallet exists
        Wallet wallet = walletRepository.findByUserId(user.getId())
                .orElseGet(() -> {
                    Wallet w = Wallet.builder()
                            .user(user)
                            .balance(BigDecimal.ZERO)
                            .currency("INR")
                            .build();
                    return walletRepository.save(w);
                });

        BigDecimal prevBalance = wallet.getBalance();
        System.out.println("[INFO] Previous Wallet Balance: ₹" + prevBalance);

        // 4. Perform idempotent top-up
        String referenceId = "TXN-ROMANSHU-TOPUP-100";
        Optional<Transaction> existingTx = transactionRepository.findByReferenceId(referenceId);
        Transaction savedTx;
        
        if (existingTx.isPresent()) {
            savedTx = existingTx.get();
            System.out.println("[INFO] Top-up of ₹100.00 already processed! Idempotency guard triggered.");
        } else {
            BigDecimal amount = new BigDecimal("100.00");
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
            savedTx = transactionRepository.save(transaction);
            System.out.println("[INFO] Successfully added ₹100.00");
        }

        // Print database verification details
        System.out.println("\n=== DATABASE VERIFICATION ===");
        System.out.println("Customer Email: " + user.getEmail());
        System.out.println("Customer ID: " + user.getId());
        System.out.println("Previous Wallet Balance: ₹" + savedTx.getBalanceBefore());
        System.out.println("Amount Added: ₹" + savedTx.getAmount());
        System.out.println("New Wallet Balance: ₹" + wallet.getBalance());
        System.out.println("Transaction/Ledger ID: " + savedTx.getId());
        System.out.println("Reference ID: " + savedTx.getReferenceId());
        System.out.println("Type: " + savedTx.getType());
        System.out.println("Status: " + savedTx.getStatus());
        System.out.println("=============================\n");

        // 5. REST API LOGIN
        System.out.println("[INFO] Testing API Login...");
        String loginPayload = "{\"email\":\"" + email + "\",\"password\":\"password123\"}";
        MvcResult loginResult = mockMvc.perform(post("/api/v1/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content(loginPayload))
                .andExpect(status().isOk())
                .andReturn();
        
        String loginResponse = loginResult.getResponse().getContentAsString();
        System.out.println("[INFO] Login API Response: " + loginResponse);
        
        // Extract JWT access token
        String tokenKey = "\"accessToken\":\"";
        int startIdx = loginResponse.indexOf(tokenKey) + tokenKey.length();
        int endIdx = loginResponse.indexOf("\"", startIdx);
        String token = loginResponse.substring(startIdx, endIdx);
        
        // 6. REST API GET BALANCE
        System.out.println("[INFO] Testing GET Wallet Balance API...");
        MvcResult balanceResult = mockMvc.perform(get("/api/v1/wallet/balance")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andReturn();
        
        String balanceResponse = balanceResult.getResponse().getContentAsString();
        System.out.println("\n=== WALLET API VERIFICATION RESULT ===");
        System.out.println("GET /api/v1/wallet/balance Response: " + balanceResponse);

        // 7. REST API GET TRANSACTIONS
        System.out.println("[INFO] Testing GET Wallet Transactions API...");
        MvcResult txResult = mockMvc.perform(get("/api/v1/wallet/transactions")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andReturn();
        
        String txResponse = txResult.getResponse().getContentAsString();
        System.out.println("GET /api/v1/wallet/transactions Response: " + txResponse);
        System.out.println("=======================================\n");
    }
}
