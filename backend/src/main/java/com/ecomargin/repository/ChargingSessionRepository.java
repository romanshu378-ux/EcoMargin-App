package com.ecomargin.repository;

import com.ecomargin.model.ChargingSession;
import com.ecomargin.model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ChargingSessionRepository extends JpaRepository<ChargingSession, Long> {
    List<ChargingSession> findByUserOrderByCreatedAtDesc(User user);
    Optional<ChargingSession> findFirstByUserAndStatusInOrderByCreatedAtDesc(User user, List<String> statuses);
    List<ChargingSession> findByStatus(String status);
}
