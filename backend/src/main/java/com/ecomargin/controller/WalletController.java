package com.ecomargin.controller;

import com.ecomargin.model.Transaction;
import com.ecomargin.model.User;
import com.ecomargin.model.Wallet;
import com.ecomargin.repository.UserRepository;
import com.ecomargin.repository.WalletRepository;
import com.ecomargin.repository.TransactionRepository;
import com.ecomargin.service.NotificationService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.math.BigDecimal;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import java.util.stream.Collectors;

@Slf4j
@RestController
@RequestMapping("/api/v1/wallet")
@RequiredArgsConstructor
@org.springframework.transaction.annotation.Transactional
public class WalletController {

    private final WalletRepository walletRepository;
    private final UserRepository userRepository;
    private final TransactionRepository transactionRepository;
    private final NotificationService notificationService;

    private User getAuthenticatedUser() {
        if (SecurityContextHolder.getContext().getAuthentication() == null) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "User not authenticated");
        }
        Object principal = SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        if (principal instanceof User) {
            return (User) principal;
        }
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        if (email == null || "anonymousUser".equalsIgnoreCase(email)) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "User not authenticated");
        }
        return userRepository.findByEmailIgnoreCase(email)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "User not authenticated"));
    }

    private Wallet getOrCreateWallet(User user) {
        return walletRepository.findByUserId(user.getId())
                .orElseGet(() -> {
                    Wallet wallet = Wallet.builder()
                            .user(user)
                            .balance(BigDecimal.ZERO)
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
    public ResponseEntity<?> topup(@RequestBody(required = false) Map<String, Object> payload) {
        User user = getAuthenticatedUser();

        // 1. Amount Validation
        Object amountObj = payload != null ? payload.get("amount") : null;
        BigDecimal amount = BigDecimal.ZERO;
        try {
            if (amountObj instanceof Number) {
                amount = BigDecimal.valueOf(((Number) amountObj).doubleValue());
            } else if (amountObj instanceof String) {
                amount = new BigDecimal((String) amountObj);
            }
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("message", "Invalid top-up amount format"));
        }

        if (amount.compareTo(BigDecimal.ZERO) <= 0) {
            return ResponseEntity.badRequest().body(Map.of("message", "Top-up amount must be strictly positive"));
        }

        if (amount.compareTo(new BigDecimal("100000.00")) > 0) {
            return ResponseEntity.badRequest().body(Map.of("message", "Top-up amount exceeds maximum allowed limit of ₹100,000"));
        }

        // 2. Idempotency Check via Reference/Payment ID if provided
        String referenceId = null;
        if (payload != null) {
            if (payload.containsKey("referenceId") && payload.get("referenceId") != null) {
                referenceId = payload.get("referenceId").toString().trim();
            } else if (payload.containsKey("paymentId") && payload.get("paymentId") != null) {
                referenceId = payload.get("paymentId").toString().trim();
            } else if (payload.containsKey("idempotencyKey") && payload.get("idempotencyKey") != null) {
                referenceId = payload.get("idempotencyKey").toString().trim();
            }
        }

        if (referenceId != null && !referenceId.isEmpty()) {
            Optional<Transaction> existingTx = transactionRepository.findByReferenceId(referenceId);
            if (existingTx.isPresent()) {
                log.info("Idempotent Top-Up Request: Reference ID {} already processed.", referenceId);
                Wallet existingWallet = existingTx.get().getWallet();
                return ResponseEntity.ok(Map.of(
                        "balance", existingWallet.getBalance(),
                        "currency", "INR",
                        "referenceId", referenceId,
                        "message", "Wallet top-up already processed (idempotent response)"
                ));
            }
        } else {
            referenceId = "TOPUP-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();
        }

        // 3. Concurrency Protection & Atomic Credit Execution
        synchronized (("WALLET_TOPUP_" + user.getId()).intern()) {
            if (!referenceId.startsWith("TOPUP-")) {
                Optional<Transaction> existingTx = transactionRepository.findByReferenceId(referenceId);
                if (existingTx.isPresent()) {
                    Wallet existingWallet = existingTx.get().getWallet();
                    return ResponseEntity.ok(Map.of(
                            "balance", existingWallet.getBalance(),
                            "currency", "INR",
                            "referenceId", referenceId,
                            "message", "Wallet top-up already processed (idempotent response)"
                    ));
                }
            }

            // Lock & load user wallet
            Wallet wallet = walletRepository.findByUserIdForUpdate(user.getId())
                    .orElseGet(() -> {
                        Wallet w = Wallet.builder()
                                .user(user)
                                .balance(BigDecimal.ZERO)
                                .currency("INR")
                                .build();
                        return walletRepository.save(w);
                    });

            BigDecimal balanceBefore = wallet.getBalance();
            BigDecimal balanceAfter = balanceBefore.add(amount);
            wallet.setBalance(balanceAfter);
            walletRepository.save(wallet);

            Transaction transaction = Transaction.builder()
                    .wallet(wallet)
                    .amount(amount)
                    .type("CREDIT")
                    .status("SUCCESS")
                    .referenceId(referenceId)
                    .referenceType("TOPUP")
                    .balanceBefore(balanceBefore)
                    .balanceAfter(balanceAfter)
                    .build();
            transactionRepository.save(transaction);

            String formattedAmt;
            if (amount.stripTrailingZeros().scale() <= 0) {
                formattedAmt = String.format("%,d", amount.longValue());
            } else {
                formattedAmt = String.format("%,.2f", amount.doubleValue());
            }

            notificationService.createNotification(
                    user,
                    "Wallet Money Added",
                    "₹" + formattedAmt + " has been added to your EcoMargin wallet.",
                    "WALLET_CREDIT"
            );

            log.info("Wallet Security Audit: User {} topped up ₹{} successfully. Ref: {}", user.getEmail(), amount, referenceId);

            return ResponseEntity.ok(Map.of(
                    "balance", wallet.getBalance(),
                    "currency", "INR",
                    "referenceId", referenceId,
                    "message", "Wallet topped up successfully"
            ));
        }
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
            map.put("status", tx.getStatus() != null ? tx.getStatus() : "SUCCESS");
            map.put("referenceId", tx.getReferenceId() != null ? tx.getReferenceId() : "TXN-" + tx.getId());
            map.put("referenceType", tx.getReferenceType() != null ? tx.getReferenceType() : tx.getType());
            map.put("balanceBefore", tx.getBalanceBefore());
            map.put("balanceAfter", tx.getBalanceAfter());
            map.put("createdAt", tx.getCreatedAt());
            map.put("paymentMethod", "CREDIT".equalsIgnoreCase(tx.getType()) ? "UPI / Card / NetBanking" : "EcoMargin Wallet");

            String desc = "Wallet Transaction";
            if ("CREDIT".equalsIgnoreCase(tx.getType())) {
                desc = "Wallet Top-up";
            } else if ("DEBIT".equalsIgnoreCase(tx.getType())) {
                desc = "EV Charging Session";
            } else if ("REFUND".equalsIgnoreCase(tx.getType())) {
                desc = "Session Refund";
            }
            map.put("description", desc);

            if (tx.getSession() != null) {
                String stName = "EcoMargin Charging Hub";
                if (tx.getSession().getConnector() != null && tx.getSession().getConnector().getCharger() != null && tx.getSession().getConnector().getCharger().getStation() != null) {
                    stName = tx.getSession().getConnector().getCharger().getStation().getName();
                }
                map.put("stationName", stName);
                map.put("sessionId", tx.getSession().getId());
                map.put("ocppTransactionId", tx.getSession().getOcppTransactionId());
            }
            return map;
        }).collect(Collectors.toList());

        return ResponseEntity.ok(list);
    }
}
