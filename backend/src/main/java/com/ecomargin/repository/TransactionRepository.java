package com.ecomargin.repository;

import com.ecomargin.model.Transaction;
import com.ecomargin.model.Wallet;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface TransactionRepository extends JpaRepository<Transaction, Long> {
    List<Transaction> findByWalletOrderByCreatedAtDesc(Wallet wallet);
    Optional<Transaction> findByReferenceId(String referenceId);
    Optional<Transaction> findFirstBySessionId(Long sessionId);
}
