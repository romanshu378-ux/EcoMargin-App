package com.ecomargin.repository;

import com.ecomargin.model.Charger;
import com.ecomargin.model.Connector;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface ConnectorRepository extends JpaRepository<Connector, Long> {
    Optional<Connector> findByChargerAndConnectorIndex(Charger charger, Integer connectorIndex);
    java.util.List<Connector> findByCharger(Charger charger);
}

