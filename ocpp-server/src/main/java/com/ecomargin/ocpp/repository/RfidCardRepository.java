package com.ecomargin.ocpp.repository;

import com.ecomargin.ocpp.model.RfidCard;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;

@Repository
public interface RfidCardRepository extends JpaRepository<RfidCard, Long> {
    Optional<RfidCard> findByCardUid(String cardUid);
    Optional<RfidCard> findByCardNumber(String cardNumber);
}
