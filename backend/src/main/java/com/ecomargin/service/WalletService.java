package com.ecomargin.service;

import com.ecomargin.model.ChargingSession;
import com.ecomargin.model.Transaction;
import com.ecomargin.model.Wallet;
import com.ecomargin.repository.ChargingSessionRepository;
import com.ecomargin.repository.TransactionRepository;
import com.ecomargin.repository.WalletRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.Optional;

@Slf4j
@Service
@RequiredArgsConstructor
public class WalletService {

    private final WalletRepository walletRepository;
    private final TransactionRepository transactionRepository;
    private final ChargingSessionRepository chargingSessionRepository;

    @Transactional
    public Transaction processChargingDebit(Long sessionId, String transactionId, BigDecimal amount) {
        log.info("Processing charging debit for sessionId: {}, transactionId: {}, amount: {}", sessionId, transactionId, amount);

        // 1. Check existing charging debit using sessionId + transactionId as referenceId
        String referenceId = sessionId + "_" + transactionId;
        Optional<Transaction> existingTx = transactionRepository.findByReferenceId(referenceId);
        if (existingTx.isPresent()) {
            log.info("Transaction with referenceId {} already processed. Returning existing transaction.", referenceId);
            return existingTx.get();
        }

        // 2. Fetch the session
        ChargingSession session = chargingSessionRepository.findById(sessionId)
                .orElseThrow(() -> new RuntimeException("Charging session not found: " + sessionId));

        // 3. Lock the user's wallet row using pessimistic write lock
        Long userId = session.getUser().getId();
        Wallet wallet = walletRepository.findByUserIdForUpdate(userId)
                .orElseThrow(() -> new RuntimeException("Wallet not found for userId: " + userId));

        // 4. Validate sufficient wallet balance (optional check: if balance is too low, we still deduct the final bill but log it)
        BigDecimal balanceBefore = wallet.getBalance();
        BigDecimal balanceAfter = balanceBefore.subtract(amount);

        wallet.setBalance(balanceAfter);
        walletRepository.save(wallet);

        // 5. Create a DEBIT ledger entry
        Transaction transaction = Transaction.builder()
                .wallet(wallet)
                .session(session)
                .amount(amount.negate())
                .type("DEBIT")
                .status("SUCCESS")
                .referenceId(referenceId)
                .referenceType("CHARGING")
                .balanceBefore(balanceBefore)
                .balanceAfter(balanceAfter)
                .build();

        Transaction savedTx = transactionRepository.save(transaction);

        // 6. Update charging_session.total_cost
        session.setTotalCost(amount);
        chargingSessionRepository.save(session);

        return savedTx;
    }
}
