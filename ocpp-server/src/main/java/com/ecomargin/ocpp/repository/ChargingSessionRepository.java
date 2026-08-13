package com.ecomargin.ocpp.repository;

import com.ecomargin.ocpp.model.ChargingSession;
import com.ecomargin.ocpp.model.Connector;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ChargingSessionRepository extends JpaRepository<ChargingSession, Long> {
    Optional<ChargingSession> findByOcppTransactionId(String ocppTransactionId);
    
    Optional<ChargingSession> findFirstByConnectorAndStatusInOrderByCreatedAtDesc(Connector connector, List<String> statuses);

    List<ChargingSession> findByStatusIn(List<String> statuses);
}
