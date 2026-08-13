package com.ecomargin.ocpp.repository;

import com.ecomargin.ocpp.model.MeterValue;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface MeterValueRepository extends JpaRepository<MeterValue, Long> {
}
