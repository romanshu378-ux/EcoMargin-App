package com.ecomargin.controller;

import com.ecomargin.model.Transaction;
import com.ecomargin.model.User;
import com.ecomargin.model.Wallet;
import com.ecomargin.repository.UserRepository;
import com.ecomargin.repository.WalletRepository;
import com.ecomargin.repository.TransactionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/v1/wallet")
@RequiredArgsConstructor
@org.springframework.transaction.annotation.Transactional
public class WalletController {

    private final WalletRepository walletRepository;
    private final UserRepository userRepository;
    private final TransactionRepository transactionRepository;

    private User getAuthenticatedUser() {
        Object principal = SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        if (principal instanceof User) {
            return (User) principal;
        }
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        return userRepository.findByEmailIgnoreCase(email)
                .orElseThrow(() -> new RuntimeException("User not authenticated"));
    }

    private Wallet getOrCreateWallet(User user) {
        return walletRepository.findByUserId(user.getId())
                .orElseGet(() -> {
                    Wallet wallet = Wallet.builder()
                            .user(user)
                            .balance(new BigDecimal("256.50"))
                            .currency("INR")
                            .build();
                    return walletRepository.save(wallet);
                });
    }

    @GetMapping("/balance")
    public ResponseEntity<?> getBalance() {
        User user = getAuthenticatedUser();
        Wallet wallet = getOrCreateWallet(user);
        Map<String, Object> response = new HashMap<>();
        response.put("balance", wallet.getBalance());
        response.put("currency", "INR");
        return ResponseEntity.ok(response);
    }

    @PostMapping("/topup")
    public ResponseEntity<?> topup(@RequestBody Map<String, Object> payload) {
        Object amountObj = payload.get("amount");
        BigDecimal amount = BigDecimal.ZERO;
        if (amountObj instanceof Number) {
            amount = BigDecimal.valueOf(((Number) amountObj).doubleValue());
        } else if (amountObj instanceof String) {
            amount = new BigDecimal((String) amountObj);
        }

        if (amount.compareTo(BigDecimal.ZERO) <= 0) {
            return ResponseEntity.badRequest().body(Map.of("message", "Invalid top-up amount"));
        }

        User user = getAuthenticatedUser();
        Wallet wallet = getOrCreateWallet(user);
        BigDecimal balanceBefore = wallet.getBalance();
        BigDecimal balanceAfter = balanceBefore.add(amount);
        wallet.setBalance(balanceAfter);
        walletRepository.save(wallet);

        Transaction transaction = Transaction.builder()
                .wallet(wallet)
                .amount(amount)
                .type("CREDIT")
                .status("SUCCESS")
                .referenceId("TXN-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase())
                .referenceType("TOPUP")
                .balanceBefore(balanceBefore)
                .balanceAfter(balanceAfter)
                .build();
        transactionRepository.save(transaction);

        return ResponseEntity.ok(Map.of(
                "balance", wallet.getBalance(),
                "currency", "INR",
                "message", "Wallet topped up successfully"
        ));
    }

    @GetMapping("/transactions")
    public ResponseEntity<?> getTransactions() {
        User user = getAuthenticatedUser();
        Wallet wallet = getOrCreateWallet(user);
        List<Transaction> txs = transactionRepository.findByWalletOrderByCreatedAtDesc(wallet);

        List<Map<String, Object>> list = txs.stream().map(tx -> {
            Map<String, Object> map = new HashMap<>();
            map.put("id", tx.getId());
            map.put("amount", tx.getAmount());
            map.put("type", tx.getType());
            map.put("status", tx.getStatus());
            map.put("referenceId", tx.getReferenceId());
            map.put("createdAt", tx.getCreatedAt());
            if (tx.getSession() != null) {
                map.put("stationName", "EcoMargin Charging Hub");
                map.put("sessionId", tx.getSession().getId());
            }
            return map;
        }).collect(Collectors.toList());

        return ResponseEntity.ok(list);
    }
}
