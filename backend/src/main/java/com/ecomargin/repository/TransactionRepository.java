package com.ecomargin.repository;

import com.ecomargin.model.Transaction;
import com.ecomargin.model.Wallet;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface TransactionRepository extends JpaRepository<Transaction, Long> {
    List<Transaction> findByWalletOrderByCreatedAtDesc(Wallet wallet);
    java.util.Optional<Transaction> findByReferenceId(String referenceId);
}
