package com.ecomargin.repository;

import com.ecomargin.model.Vehicle;
import com.ecomargin.model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface VehicleRepository extends JpaRepository<Vehicle, Long> {
    List<Vehicle> findByUser(User user);
    Optional<Vehicle> findByIdAndUser(Long id, User user);
    List<Vehicle> findByUserAndIsDefaultTrue(User user);
}
