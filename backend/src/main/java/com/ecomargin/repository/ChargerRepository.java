package com.ecomargin.repository;

import com.ecomargin.model.Charger;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.ecomargin.model.Station;
import java.util.List;
import java.util.Optional;

@Repository
public interface ChargerRepository extends JpaRepository<Charger, Long> {
    Optional<Charger> findByOcppId(String ocppId);
    List<Charger> findByStation(Station station);
    List<Charger> findByStationId(Long stationId);
}
