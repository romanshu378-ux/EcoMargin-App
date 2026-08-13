package com.ecomargin.repository;

import com.ecomargin.model.RfidCard;
import com.ecomargin.model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;

@Repository
public interface RfidCardRepository extends JpaRepository<RfidCard, Long> {
    Optional<RfidCard> findByUser(User user);
    Optional<RfidCard> findByCardNumber(String cardNumber);
    Optional<RfidCard> findByCardUid(String cardUid);
}
