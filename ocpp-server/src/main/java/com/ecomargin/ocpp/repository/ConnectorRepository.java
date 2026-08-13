package com.ecomargin.ocpp.repository;

import com.ecomargin.ocpp.model.Charger;
import com.ecomargin.ocpp.model.Connector;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;

@Repository
public interface ConnectorRepository extends JpaRepository<Connector, Long> {
    Optional<Connector> findByChargerAndConnectorIndex(Charger charger, Integer connectorIndex);
}
